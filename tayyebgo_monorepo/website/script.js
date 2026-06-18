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
window.addEventListener('load', () => {
  const loadingScreen = document.getElementById('loadingScreen');
  if (loadingScreen) {
    setTimeout(() => loadingScreen.classList.add('hidden'), 300);
    setTimeout(() => loadingScreen.remove(), 700);
  }
});

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
