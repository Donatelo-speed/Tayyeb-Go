// ========================================
// TayyebGo Premium Interactions v2.0
// ========================================

// --- Mobile Menu ---
function toggleMobileMenu() {
  const menu = document.getElementById('mobileMenu');
  const btn = document.querySelector('.mobile-menu-btn');
  menu.classList.toggle('open');
  btn.classList.toggle('open');
  btn.setAttribute('aria-expanded', menu.classList.contains('open'));
}

document.querySelectorAll('.mobile-menu a').forEach(link => {
  link.addEventListener('click', () => {
    document.getElementById('mobileMenu').classList.remove('open');
    document.querySelector('.mobile-menu-btn').classList.remove('open');
  });
});

// --- Theme Toggle ---
const themeToggle = document.getElementById('themeToggle');
const html = document.documentElement;

const savedTheme = localStorage.getItem('tayyebgo-theme');
if (savedTheme) {
  html.setAttribute('data-theme', savedTheme);
} else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
  html.setAttribute('data-theme', 'dark');
}

themeToggle.addEventListener('click', () => {
  const current = html.getAttribute('data-theme');
  const next = current === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('tayyebgo-theme', next);
});

// --- Navbar Scroll ---
const navbar = document.getElementById('navbar');
let lastScroll = 0;

window.addEventListener('scroll', () => {
  const scrollY = window.scrollY;
  if (scrollY > 50) {
    navbar.classList.add('scrolled');
  } else {
    navbar.classList.remove('scrolled');
  }
  lastScroll = scrollY;
});

// --- Smooth Scroll ---
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function(e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      const offset = 80;
      const top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  });
});

// --- Ripple Effect ---
document.querySelectorAll('.ripple').forEach(btn => {
  btn.addEventListener('click', function(e) {
    const rect = this.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    this.style.setProperty('--ripple-x', x + 'px');
    this.style.setProperty('--ripple-y', y + 'px');
    this.classList.remove('rippling');
    void this.offsetWidth;
    this.classList.add('rippling');
    setTimeout(() => this.classList.remove('rippling'), 600);
  });
});

// Fix ripple positioning
const rippleStyle = document.createElement('style');
rippleStyle.textContent = `.ripple::after { left: var(--ripple-x, 50%); top: var(--ripple-y, 50%); }`;
document.head.appendChild(rippleStyle);

// --- Scroll Reveal ---
const revealElements = document.querySelectorAll(
  '.section-header, .step-card, .split-content, .split-visual, ' +
  '.testimonial-card, .pricing-card, .faq-item, .blog-card, ' +
  '.partner-logo-item, .career-perk, .career-dept-card, ' +
  '.download-content, .download-phone, .contact-form, .info-card, ' +
  '.app-screen-wrapper, .feature-card, .trust-item'
);

revealElements.forEach(el => el.classList.add('reveal'));

const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
    }
  });
}, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

revealElements.forEach(el => revealObserver.observe(el));

// --- App Showcase Screen Switching ---
const appWrappers = document.querySelectorAll('.app-screen-wrapper');
const appDots = document.querySelectorAll('.app-dot');
let activeScreen = 1;
let appInterval;

function switchScreen(num) {
  activeScreen = num;
  appWrappers.forEach(w => {
    w.classList.toggle('active', w.dataset.screen == num);
  });
  appDots.forEach(d => {
    d.classList.toggle('active', d.dataset.screen == num);
  });
}

function startAppInterval() {
  appInterval = setInterval(() => {
    activeScreen = activeScreen >= 3 ? 1 : activeScreen + 1;
    switchScreen(activeScreen);
  }, 4000);
}

appDots.forEach(dot => {
  dot.addEventListener('click', () => {
    clearInterval(appInterval);
    switchScreen(parseInt(dot.dataset.screen));
    startAppInterval();
  });
});

appWrappers.forEach(wrapper => {
  wrapper.addEventListener('click', () => {
    clearInterval(appInterval);
    switchScreen(parseInt(wrapper.dataset.screen));
    startAppInterval();
  });
});

startAppInterval();

// Pause on hover
const showcase = document.querySelector('.app-showcase');
if (showcase) {
  showcase.addEventListener('mouseenter', () => clearInterval(appInterval));
  showcase.addEventListener('mouseleave', startAppInterval);
}

// --- Hero Particles ---
function createParticles() {
  const container = document.getElementById('heroParticles');
  if (!container) return;
  for (let i = 0; i < 30; i++) {
    const particle = document.createElement('div');
    particle.className = 'hero-particle';
    particle.style.left = Math.random() * 100 + '%';
    particle.style.top = Math.random() * 100 + '%';
    particle.style.animationDelay = Math.random() * 3 + 's';
    particle.style.animationDuration = (2 + Math.random() * 3) + 's';
    const size = 2 + Math.random() * 3;
    particle.style.width = size + 'px';
    particle.style.height = size + 'px';
    container.appendChild(particle);
  }
}
createParticles();

// --- Counter Animation ---
function animateCounters() {
  document.querySelectorAll('[data-count]').forEach(el => {
    if (el.dataset.animated) return;
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !el.dataset.animated) {
          el.dataset.animated = 'true';
          const target = parseInt(el.dataset.count);
          const suffix = el.querySelector('.stat-number').textContent.replace(/[0-9]/g, '');
          const duration = 2000;
          const start = performance.now();

          function update(now) {
            const elapsed = now - start;
            const progress = Math.min(elapsed / duration, 1);
            const eased = 1 - Math.pow(1 - progress, 3);
            const current = Math.floor(eased * target);
            if (target >= 1000) {
              el.querySelector('.stat-number').textContent = (current / 1000).toFixed(current >= target ? 0 : 1) + 'K+';
            } else {
              el.querySelector('.stat-number').textContent = current + suffix;
            }
            if (progress < 1) requestAnimationFrame(update);
            else el.querySelector('.stat-number').textContent = el.querySelector('.stat-number').textContent;
          }
          requestAnimationFrame(update);
        }
      });
    }, { threshold: 0.5 });
    observer.observe(el);
  });
}
animateCounters();

// --- Parallax on Hero ---
window.addEventListener('scroll', () => {
  const scrollY = window.scrollY;
  const heroVisual = document.querySelector('.hero-visual');
  if (heroVisual && scrollY < window.innerHeight) {
    heroVisual.style.transform = `translateY(${scrollY * 0.08}px)`;
  }
});

// --- FAQ Accordion ---
document.querySelectorAll('.faq-trigger').forEach(trigger => {
  trigger.addEventListener('click', () => {
    const item = trigger.closest('.faq-item');
    const isOpen = item.classList.contains('open');

    // Close all other items
    document.querySelectorAll('.faq-item.open').forEach(openItem => {
      if (openItem !== item) {
        openItem.classList.remove('open');
        openItem.querySelector('.faq-trigger').setAttribute('aria-expanded', 'false');
      }
    });

    item.classList.toggle('open');
    trigger.setAttribute('aria-expanded', !isOpen);
  });
});

// --- Contact Form ---
const contactForm = document.getElementById('contactForm');
if (contactForm) {
  contactForm.addEventListener('submit', (e) => {
    e.preventDefault();

    // Basic validation
    const name = contactForm.querySelector('#name');
    const email = contactForm.querySelector('#email');
    const subject = contactForm.querySelector('#subject');
    const message = contactForm.querySelector('#message');

    let valid = true;
    [name, email, subject, message].forEach(field => {
      if (!field.value.trim()) {
        field.style.borderColor = '#EF4444';
        valid = false;
      } else {
        field.style.borderColor = '';
      }
    });

    if (email.value && !email.value.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
      email.style.borderColor = '#EF4444';
      valid = false;
    }

    if (!valid) return;

    const btn = contactForm.querySelector('button[type="submit"]');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<span>Sent! We\'ll get back to you soon.</span>';
    btn.style.background = 'var(--success)';
    btn.disabled = true;
    setTimeout(() => {
      btn.innerHTML = originalText;
      btn.style.background = '';
      btn.disabled = false;
      contactForm.reset();
    }, 3000);
  });
}

// --- Performance: Lazy load images ---
if ('IntersectionObserver' in window) {
  const imgObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target;
        if (img.dataset.src) {
          img.src = img.dataset.src;
          img.removeAttribute('data-src');
        }
        imgObserver.unobserve(img);
      }
    });
  }, { rootMargin: '100px' });

  document.querySelectorAll('img[data-src]').forEach(img => imgObserver.observe(img));
}

// --- Accessibility: Keyboard navigation for FAQ ---
document.querySelectorAll('.faq-trigger').forEach(trigger => {
  trigger.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      trigger.click();
    }
  });
});

// --- Reduce motion preference ---
if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
  document.documentElement.style.setProperty('--transition-fast', '0s');
  document.documentElement.style.setProperty('--transition-base', '0s');
  document.documentElement.style.setProperty('--transition-smooth', '0s');
  document.documentElement.style.setProperty('--transition-spring', '0s');
}

// --- Arabic Language Toggle ---
const translations = {
  // Navigation
  'nav_how': { en: 'How It Works', ar: 'كيف يعمل' },
  'nav_features': { en: 'Features', ar: 'المميزات' },
  'nav_customers': { en: 'Customers', ar: 'العملاء' },
  'nav_drivers': { en: 'Drivers', ar: 'السائقون' },
  'nav_partners': { en: 'Partners', ar: 'الشركاء' },
  'nav_pricing': { en: 'Pricing', ar: 'الأسعار' },
  'nav_signin': { en: 'Sign In', ar: 'تسجيل الدخول' },
  'nav_getstarted': { en: 'Get Started', ar: 'ابدأ الآن' },
  // Hero
  'hero_badge': { en: 'Live in Damascus & beyond', ar: 'متاح في دمشق وما حولها' },
  'hero_title1': { en: 'Everything', ar: 'كل شيء' },
  'hero_title2': { en: 'Delivered.', ar: 'توصيل.' },
  'hero_subtitle': { en: 'Food, groceries, pharmacy, and anything you need — delivered to your door in minutes. One app for your entire city.', ar: 'طعام، بقالة، صيدلية، وأي شيء تحتاجه — يوصّل لبابك في دقائق. تطبيق واحد لمدينتك كلها.' },
  'hero_ordernow': { en: 'Order Now', ar: 'اطلب الآن' },
  'hero_partner': { en: 'Partner With Us', ar: 'كن شريكاً' },
  'stat_orders': { en: 'Orders Delivered', ar: 'طلب تم توصيله' },
  'stat_stores': { en: 'Partner Stores', ar: 'متجر شريك' },
  'stat_drivers': { en: 'Active Drivers', ar: 'سائق نشط' },
  // Trust
  'trust_payments': { en: 'Secure Payments', ar: 'مدفوعات آمنة' },
  'trust_fast': { en: 'Fast Delivery', ar: 'توصيل سريع' },
  'trust_support': { en: '24/7 Support', ar: 'دعم على مدار الساعة' },
  'trust_rating': { en: 'Top Rated', ar: 'الأعلى تقييماً' },
  // How It Works
  'how_tag': { en: 'How It Works', ar: 'كيف يعمل' },
  'how_title': { en: 'Order in 3 simple steps', ar: 'اطلب في 3 خطوات بسيطة' },
  'how_subtitle': { en: 'From your phone to your door in minutes.', ar: 'من هاتفك إلى بابك في دقائق.' },
  'step1_title': { en: 'Browse & Choose', ar: 'تصفح واختر' },
  'step1_desc': { en: 'Explore restaurants, stores, and services near you. Find exactly what you want.', ar: 'استكشف المطاعم والمتاجر والخدمات القريبة منك. اعثر على ما تريد بالضبط.' },
  'step2_title': { en: 'Place Your Order', ar: 'أدخل طلبك' },
  'step2_desc': { en: 'Checkout with cash, Sham Cash, or card. Schedule for later or order now.', ar: 'ادفع نقداً، شام كاش، أو بطاقة. جدول للوقت اللاحق أو اطلب الآن.' },
  'step3_title': { en: 'Track & Receive', ar: 'تتبع واستلم' },
  'step3_desc': { en: 'Watch your driver in real-time. Get notified at every step. Enjoy your order.', ar: 'تابع سائقك في الوقت الحقيقي. احصل على إشعار في كل خطوة. استمتع بطلبك.' },
  // Features
  'features_tag': { en: 'Why TayyebGo', ar: 'لماذا TayyebGo' },
  'features_title': { en: 'Built for your city', ar: 'مصمم لمدينتك' },
  'features_subtitle': { en: 'Everything you need in one app, designed for the Middle East.', ar: 'كل ما تحتاجه في تطبيق واحد، مصمم للشرق الأوسط.' },
  'feat1_title': { en: 'Lightning Fast', ar: 'سريع كالبرق' },
  'feat1_desc': { en: 'Average delivery in 20 minutes. Real-time tracking from restaurant to your door.', ar: 'متوسط التوصيل 20 دقيقة. تتبع مباشر من المطعم إلى بابك.' },
  'feat2_title': { en: 'Anything Delivery', ar: 'توصيل أي شيء' },
  'feat2_desc': { en: "Don't just order food. Request anything — medicine, documents, gifts. We buy it for you.", ar: 'لا تطلب فقط الطعام. اطلب أي شيء — أدوية، مستندات، هدايا. نشتريه لك.' },
  'feat3_title': { en: 'Multiple Payments', ar: 'دفع متعدد' },
  'feat3_desc': { en: 'Cash, Sham Cash, or card. Pay however works for you. Secure and encrypted.', ar: 'نقداً، شام كاش، أو بطاقة. ادفع بالطريقة المناسبة لك. آمن ومشفر.' },
  'feat4_title': { en: 'Loyalty Rewards', ar: 'مكافآت الولاء' },
  'feat4_desc': { en: 'Earn points on every order. Redeem for discounts, free delivery, and exclusive deals.', ar: 'اكسب نقاطاً في كل طلب. استبدلها بخصومات وتوصيل مجاني وعروض حصرية.' },
  'feat5_title': { en: 'Safe & Secure', ar: 'آمن ومحمي' },
  'feat5_desc': { en: 'Encrypted payments, verified drivers, and SOS safety features for peace of mind.', ar: 'مدفوعات مشفرة، سائقون موثوقون، وميزات أمان طوارئ لراحة بالك.' },
  'feat6_title': { en: 'Top Rated', ar: 'الأعلى تقييماً' },
  'feat6_desc': { en: '4.9 average rating. Loved by customers, drivers, and partners across Syria.', ar: 'متوسط تقييم 4.9. محبوب من العملاء والسائقين والشركاء في سوريا.' },
  // Sections
  'customers_tag': { en: 'For Customers', ar: 'للعملاء' },
  'customers_title': { en: 'Your city, your way.', ar: 'مدينتك، بطريقتك.' },
  'customers_desc': { en: 'Order from your favorite restaurants or ask us to pick up anything — medicine, documents, gifts. TayyebGo delivers it all.', ar: 'اطلب من مطاعمك المفضلة أو اطلب منا توصيل أي شيء — أدوية، مستندات، هدايا. TayyebGo يوصّل كل شيء.' },
  'drivers_tag': { en: 'For Drivers', ar: 'للسائقين' },
  'drivers_title': { en: 'Earn on your schedule.', ar: 'أربحك بجدولك.' },
  'drivers_desc': { en: 'Drive when you want, earn what you need. Join hundreds of drivers already earning with TayyebGo.', ar: 'قُد متى تشاء، اكسب ما تحتاجه. انضم لمئات السائقين الذين يكسبون مع TayyebGo.' },
  'partners_tag': { en: 'For Partners', ar: 'للشركاء' },
  'partners_title': { en: 'Grow your business.', ar: 'نمِّ عملك.' },
  'partners_desc': { en: 'Reach thousands of customers. Manage orders, menu, and analytics — all in one place.', ar: 'الآلاف من العملاء في متناول يدك. أدر الطلبات والقائمة والتحليلات — كلها في مكان واحد.' },
  // Pricing
  'pricing_tag': { en: 'Pricing', ar: 'الأسعار' },
  'pricing_title': { en: 'Simple, transparent pricing', ar: 'أسعار بسيطة وشفافة' },
  'pricing_subtitle': { en: 'No hidden fees. You only pay for what you use.', ar: 'بدون رسوم خفية. تدفع فقط لما تستخدمه.' },
  'price_customer': { en: 'Customer', ar: 'عميل' },
  'price_free': { en: 'Free', ar: 'مجاني' },
  'price_touse': { en: 'To download & use', ar: 'للتحميل والاستخدام' },
  'price_subscription': { en: 'Subscription', ar: 'اشتراك' },
  'price_partner': { en: 'Partner', ar: 'شريك' },
  'price_commission': { en: 'Commission per order', ar: 'عمولة لكل طلب' },
  'btn_getstarted': { en: 'Get Started', ar: 'ابدأ الآن' },
  'btn_subscribenow': { en: 'Subscribe Now', ar: 'اشترك الآن' },
  'btn_joinpartner': { en: 'Join as Partner', ar: 'انضم كشريك' },
  // CTA
  'cta_title': { en: 'Ready to get started?', ar: 'مستعد للبدء؟' },
  'cta_desc': { en: 'Join thousands of people already using TayyebGo.', ar: 'انضم لآلاف الأشخاص الذين يستخدمون TayyebGo.' },
  'cta_create': { en: 'Create Account', ar: 'إنشاء حساب' },
  // Footer
  'footer_product': { en: 'Product', ar: 'المنتج' },
  'footer_company': { en: 'Company', ar: 'الشركة' },
  'footer_support': { en: 'Support', ar: 'الدعم' },
  'footer_about': { en: 'About Us', ar: 'من نحن' },
  'footer_careers': { en: 'Careers', ar: 'الوظائف' },
  'footer_blog': { en: 'Blog', ar: 'المدونة' },
  'footer_help': { en: 'Help Center', ar: 'مركز المساعدة' },
  'footer_safety': { en: 'Safety', ar: 'الأمان' },
  'footer_terms': { en: 'Terms of Service', ar: 'شروط الخدمة' },
  'footer_privacy': { en: 'Privacy Policy', ar: 'سياسة الخصوصية' },
  'footer_download': { en: 'Download', ar: 'التحميل' },
  'footer_refer': { en: 'Refer & Earn', ar: 'أصدِف واكسب' },
  'footer_homs': { en: 'Homs', ar: 'حمص' },
};

let currentLang = localStorage.getItem('tayyebgo-lang') || 'en';

function toggleLanguage() {
  currentLang = currentLang === 'en' ? 'ar' : 'en';
  localStorage.setItem('tayyebgo-lang', currentLang);
  applyLanguage();
}

function applyLanguage() {
  document.documentElement.setAttribute('lang', currentLang);
  document.documentElement.setAttribute('dir', currentLang === 'ar' ? 'rtl' : 'ltr');
  const langText = document.getElementById('langText');
  if (langText) langText.textContent = currentLang === 'en' ? 'AR' : 'EN';
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (translations[key] && translations[key][currentLang]) {
      el.textContent = translations[key][currentLang];
    }
  });
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
    const key = el.getAttribute('data-i18n-placeholder');
    if (translations[key] && translations[key][currentLang]) {
      el.placeholder = translations[key][currentLang];
    }
  });
}

// Apply language on load
applyLanguage();

// --- Console branding ---
console.log(
  '%c TayyebGo %c Everything Delivered ',
  'background: linear-gradient(135deg, #FF5A2C, #8B5CF6); color: white; padding: 8px 12px; border-radius: 6px 0 0 6px; font-weight: bold;',
  'background: #0A0F0D; color: #8A9A92; padding: 8px 12px; border-radius: 0 6px 6px 0;'
);

// --- Back to Top Button ---
const backToTop = document.getElementById('backToTop');
if (backToTop) {
  window.addEventListener('scroll', () => {
    if (window.scrollY > 300) {
      backToTop.classList.add('visible');
    } else {
      backToTop.classList.remove('visible');
    }
  });
  backToTop.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
}

// --- Loading Screen ---
function hideLoadingScreen() {
  const loadingScreen = document.getElementById('loadingScreen');
  if (loadingScreen) {
    loadingScreen.classList.add('hidden');
    setTimeout(() => loadingScreen.remove(), 500);
  }
}
window.addEventListener('load', () => setTimeout(hideLoadingScreen, 300));
setTimeout(hideLoadingScreen, 3000);

// --- Cookie Consent ---
function acceptCookies() {
  localStorage.setItem('tayyebgo-cookies', 'accepted');
  document.getElementById('cookieConsent').style.display = 'none';
}
function declineCookies() {
  localStorage.setItem('tayyebgo-cookies', 'declined');
  document.getElementById('cookieConsent').style.display = 'none';
}
if (!localStorage.getItem('tayyebgo-cookies')) {
  const cookieEl = document.getElementById('cookieConsent');
  if (cookieEl) cookieEl.style.display = 'flex';
}
