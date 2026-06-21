// Theme System for TayyebGo Customer Web App
class ThemeManager {
  constructor() {
    this.currentTheme = localStorage.getItem('tayyebgo-theme') || 'light';
    this.currentLang = localStorage.getItem('tayyebgo-lang') || 'en';
    this.init();
  }

  init() {
    document.documentElement.setAttribute('data-theme', this.currentTheme);
    document.documentElement.setAttribute('lang', this.currentLang);
    document.documentElement.setAttribute('dir', this.currentLang === 'ar' ? 'rtl' : 'ltr');
  }

  // Toggle theme
  toggleTheme() {
    this.currentTheme = this.currentTheme === 'light' ? 'dark' : 'light';
    localStorage.setItem('tayyebgo-theme', this.currentTheme);
    document.documentElement.setAttribute('data-theme', this.currentTheme);
    return this.currentTheme;
  }

  // Set theme
  setTheme(theme) {
    this.currentTheme = theme;
    localStorage.setItem('tayyebgo-theme', theme);
    document.documentElement.setAttribute('data-theme', theme);
  }

  // Toggle language
  toggleLanguage() {
    this.currentLang = this.currentLang === 'en' ? 'ar' : 'en';
    localStorage.setItem('tayyebgo-lang', this.currentLang);
    document.documentElement.setAttribute('lang', this.currentLang);
    document.documentElement.setAttribute('dir', this.currentLang === 'ar' ? 'rtl' : 'ltr');
    return this.currentLang;
  }

  // Set language
  setLanguage(lang) {
    this.currentLang = lang;
    localStorage.setItem('tayyebgo-lang', lang);
    document.documentElement.setAttribute('lang', lang);
    document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  }

  // Get theme
  getTheme() {
    return this.currentTheme;
  }

  // Get language
  getLanguage() {
    return this.currentLang;
  }

  // Check if dark mode
  isDark() {
    return this.currentTheme === 'dark';
  }

  // Check if Arabic
  isArabic() {
    return this.currentLang === 'ar';
  }
}

export const themeManager = new ThemeManager();
export default themeManager;
