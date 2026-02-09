// Language/i18n management
(function() {
  const LANG_KEY = 'vitte-lang';
  
  // Traductions
  const translations = {
    fr: {
      'nav.book': 'Livre',
      'nav.cli': 'CLI',
      'nav.stdlib': 'Stdlib',
      'nav.grammar': 'Grammaire',
      'nav.errors': 'Erreurs',
      'theme.auto': 'Auto',
      'theme.dark': 'Sombre',
      'theme.light': 'Clair',
      'search.placeholder': 'Chercher…',
      'version.label': 'Version',
      'common.home': 'Accueil',
      'common.about': 'À propos',
      'common.lang': 'Langue',
    },
    en: {
      'nav.book': 'Book',
      'nav.cli': 'CLI',
      'nav.stdlib': 'Stdlib',
      'nav.grammar': 'Grammar',
      'nav.errors': 'Errors',
      'theme.auto': 'Auto',
      'theme.dark': 'Dark',
      'theme.light': 'Light',
      'search.placeholder': 'Search…',
      'version.label': 'Version',
      'common.home': 'Home',
      'common.about': 'About',
      'common.lang': 'Language',
    },
    es: {
      'nav.book': 'Libro',
      'nav.cli': 'CLI',
      'nav.stdlib': 'Stdlib',
      'nav.grammar': 'Gramática',
      'nav.errors': 'Errores',
      'theme.auto': 'Auto',
      'theme.dark': 'Oscuro',
      'theme.light': 'Claro',
      'search.placeholder': 'Buscar…',
      'version.label': 'Versión',
      'common.home': 'Inicio',
      'common.about': 'Acerca de',
      'common.lang': 'Idioma',
    },
    pt: {
      'nav.book': 'Livro',
      'nav.cli': 'CLI',
      'nav.stdlib': 'Stdlib',
      'nav.grammar': 'Gramática',
      'nav.errors': 'Erros',
      'theme.auto': 'Auto',
      'theme.dark': 'Escuro',
      'theme.light': 'Claro',
      'search.placeholder': 'Pesquisar…',
      'version.label': 'Versão',
      'common.home': 'Início',
      'common.about': 'Sobre',
      'common.lang': 'Idioma',
    },
    it: {
      'nav.book': 'Libro',
      'nav.cli': 'CLI',
      'nav.stdlib': 'Stdlib',
      'nav.grammar': 'Grammatica',
      'nav.errors': 'Errori',
      'theme.auto': 'Auto',
      'theme.dark': 'Scuro',
      'theme.light': 'Chiaro',
      'search.placeholder': 'Cerca…',
      'version.label': 'Versione',
      'common.home': 'Home',
      'common.about': 'Chi siamo',
      'common.lang': 'Lingua',
    },
  };

  const languages = {
    fr: { name: 'Français', flag: '🇫🇷' },
    en: { name: 'English', flag: '🇬🇧' },
    es: { name: 'Español', flag: '🇪🇸' },
    pt: { name: 'Português', flag: '🇵🇹' },
    it: { name: 'Italiano', flag: '🇮🇹' },
  };

  function getPreferredLanguage() {
    const stored = localStorage.getItem(LANG_KEY);
    if (stored && translations[stored]) return stored;
    
    // Déterminer la langue du navigateur
    const browserLang = (navigator.language || navigator.userLanguage).substring(0, 2);
    if (translations[browserLang]) return browserLang;
    
    return 'en'; // Par défaut
  }

  function t(key, currentLang) {
    const lang = currentLang || getPreferredLanguage();
    return translations[lang]?.[key] || key;
  }

  function setLanguage(lang) {
    if (!translations[lang]) return;
    localStorage.setItem(LANG_KEY, lang);
    updatePageLanguage(lang);
    updateLanguageUI(lang);
  }

  function updatePageLanguage(lang) {
    // Mettre à jour les éléments avec data-i18n
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      el.textContent = t(key, lang);
    });

    // Mettre à jour les attributs
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      const key = el.getAttribute('data-i18n-placeholder');
      el.placeholder = t(key, lang);
    });

    // Mettre à jour la langue du document
    document.documentElement.lang = lang;
  }

  function updateLanguageUI(lang) {
    const selector = document.getElementById('language-selector');
    if (selector) {
      selector.value = lang;
    }

    const toggle = document.getElementById('language-toggle');
    if (toggle) {
      const langInfo = languages[lang];
      toggle.textContent = langInfo.flag;
      toggle.title = `Language: ${langInfo.name}`;
    }
  }

  function initializeLanguageSelector() {
    const selector = document.getElementById('language-selector');
    if (!selector) return;

    Object.keys(languages).forEach(lang => {
      const option = document.createElement('option');
      option.value = lang;
      option.textContent = `${languages[lang].flag} ${languages[lang].name}`;
      selector.appendChild(option);
    });

    const currentLang = getPreferredLanguage();
    selector.value = currentLang;
    selector.addEventListener('change', (e) => setLanguage(e.target.value));
  }

  // Initialize on DOM ready
  document.addEventListener('DOMContentLoaded', function() {
    const currentLang = getPreferredLanguage();
    updatePageLanguage(currentLang);
    initializeLanguageSelector();
    updateLanguageUI(currentLang);
  });

  // Expose functions
  window.vitteI18n = {
    t,
    setLanguage,
    getPreferredLanguage,
  };
})();
