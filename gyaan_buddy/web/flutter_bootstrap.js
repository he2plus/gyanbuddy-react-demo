{{flutter_js}}
{{flutter_build_config}}

const loadingElement = document.getElementById('app-loading');
let loadingHidden = false;

function hideLoadingElement() {
  if (loadingHidden || !loadingElement) return;
  loadingHidden = true;
  loadingElement.classList.add('is-hidden');
  window.setTimeout(() => loadingElement.remove(), 220);
}

window.addEventListener('gyanbuddy-app-ready', hideLoadingElement, {
  once: true,
});

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    window.setTimeout(hideLoadingElement, 10000);
  },
});
