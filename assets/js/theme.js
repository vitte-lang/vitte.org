// Theme management: dark/light/auto
(function() {
  const THEME_KEY = 'vitte-theme';
  const THEME_AUTO = 'auto';
  const THEME_DARK = 'dark';
  const THEME_LIGHT = 'light';

  function getPreferredTheme() {
    const stored = localStorage.getItem(THEME_KEY);
    if (stored) return stored;
    return THEME_AUTO;
  }

  function getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? THEME_DARK : THEME_LIGHT;
  }

  function applyTheme(theme) {
    if (theme === THEME_AUTO) {
      document.documentElement.removeAttribute('data-theme');
    } else {
      document.documentElement.setAttribute('data-theme', theme);
    }
  }

  function setTheme(theme) {
    localStorage.setItem(THEME_KEY, theme);
    applyTheme(theme);
    updateThemeToggle();
  }

  function toggleTheme() {
    const current = getPreferredTheme();
    const themes = [THEME_AUTO, THEME_DARK, THEME_LIGHT];
    const nextIndex = (themes.indexOf(current) + 1) % themes.length;
    setTheme(themes[nextIndex]);
  }

  function updateThemeToggle() {
    const toggle = document.getElementById('theme-toggle');
    if (!toggle) return;
    
    const theme = getPreferredTheme();
    const icons = {
      auto: '🎨',
      dark: '🌙',
      light: '☀️'
    };
    
    const labels = {
      auto: 'Auto',
      dark: 'Dark',
      light: 'Light'
    };
    
    toggle.textContent = icons[theme];
    toggle.title = `Switch theme (Current: ${labels[theme]})`;
  }

  // Listen for system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (getPreferredTheme() === THEME_AUTO) {
      applyTheme(THEME_AUTO);
    }
  });

  // Initialize
  document.addEventListener('DOMContentLoaded', function() {
    const theme = getPreferredTheme();
    applyTheme(theme);
    updateThemeToggle();

    const toggle = document.getElementById('theme-toggle');
    if (toggle) {
      toggle.addEventListener('click', toggleTheme);
    }
  });

  // Expose toggle function for HTML
  window.toggleTheme = toggleTheme;
})();
