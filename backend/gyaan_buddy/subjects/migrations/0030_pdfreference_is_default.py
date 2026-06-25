from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('subjects', '0029_assessmentsession_pdfreference_questionmodification'),
    ]

    operations = [
        migrations.AddField(
            model_name='pdfreference',
            name='is_default',
            field=models.BooleanField(default=False, help_text='Default PDF for this chapter — cannot be deleted.'),
        ),
    ]
