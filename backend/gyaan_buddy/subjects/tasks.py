import logging
from celery import shared_task

logger = logging.getLogger('gyaan_buddy.subjects')


# ── PDF Processing ─────────────────────────────────────────────────────────────

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def process_pdf(self, pdf_reference_id: str):
    """
    Pipeline: POST gcs_path to ai-service → ai-service downloads, extracts, chunks, embeds.
    Updates PdfReference.embedding_status and total_pages.
    """
    from .models import PdfReference

    try:
        pdf_ref = PdfReference.objects.get(pk=pdf_reference_id)
    except PdfReference.DoesNotExist:
        logger.error(f"process_pdf: PdfReference {pdf_reference_id} not found")
        return

    pdf_ref.embedding_status = 'PROCESSING'
    pdf_ref.save(update_fields=['embedding_status'])

    try:
        total_pages = _run_pdf_pipeline(pdf_ref)
        pdf_ref.embedding_status = 'COMPLETED'
        pdf_ref.total_pages = total_pages
        pdf_ref.save(update_fields=['embedding_status', 'total_pages'])
        logger.info(f"process_pdf: completed for {pdf_reference_id} ({total_pages} pages)")
    except Exception as exc:
        logger.error(f"process_pdf: failed for {pdf_reference_id}: {exc}", exc_info=True)
        pdf_ref.embedding_status = 'FAILED'
        pdf_ref.save(update_fields=['embedding_status'])
        raise self.retry(exc=exc)


def _run_pdf_pipeline(pdf_ref) -> int:
    """
    POST the GCS path to ai-service /ai/embed.
    ai-service owns the full pipeline: GCS download → text extraction → chunk + embed + store.
    Returns total page count reported by ai-service.
    """
    import httpx
    from django.conf import settings as django_settings

    ai_service_url = getattr(django_settings, 'AI_SERVICE_URL', 'http://localhost:8001')
    payload = {
        "pdf_id": str(pdf_ref.id),
        "chapter_id": str(pdf_ref.chapter_id),
        "gcs_path": pdf_ref.gcs_path,
    }

    resp = httpx.post(
        f"{ai_service_url}/ai/embed",
        json=payload,
        timeout=300.0,  # large PDFs can take time to process
    )
    resp.raise_for_status()
    result = resp.json()
    logger.info(
        f"ai-service processed pdf {pdf_ref.id}: "
        f"{result.get('total_pages', 0)} pages, {result.get('chunks_stored', 0)} chunks"
    )
    return result.get('total_pages', 0)


# ── Qdrant Cleanup ─────────────────────────────────────────────────────────────

@shared_task(bind=True, max_retries=3, default_retry_delay=30)
def delete_pdf_embeddings(self, pdf_reference_id: str):
    """
    Soft-delete Qdrant vectors for this pdf_reference_id.
    Sets is_active=False so vectors are excluded from retrieval but not removed.
    """
    import httpx
    from django.conf import settings as django_settings

    try:
        ai_service_url = getattr(django_settings, 'AI_SERVICE_URL', 'http://localhost:8001')
        resp = httpx.delete(
            f"{ai_service_url}/ai/embed/{pdf_reference_id}",
            timeout=30.0,
        )
        resp.raise_for_status()
        logger.info(f"delete_pdf_embeddings: deactivated vectors for {pdf_reference_id}")
    except Exception as exc:
        logger.error(f"delete_pdf_embeddings: failed for {pdf_reference_id}: {exc}")
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30)
def reactivate_pdf_embeddings(self, pdf_reference_id: str):
    """
    Restore Qdrant vectors for this pdf_reference_id.
    Sets is_active=True so vectors are included in retrieval again.
    """
    import httpx
    from django.conf import settings as django_settings

    try:
        ai_service_url = getattr(django_settings, 'AI_SERVICE_URL', 'http://localhost:8001')
        resp = httpx.patch(
            f"{ai_service_url}/ai/embed/{pdf_reference_id}/reactivate",
            timeout=30.0,
        )
        resp.raise_for_status()
        logger.info(f"reactivate_pdf_embeddings: reactivated vectors for {pdf_reference_id}")
    except Exception as exc:
        logger.error(f"reactivate_pdf_embeddings: failed for {pdf_reference_id}: {exc}")
        raise self.retry(exc=exc)
