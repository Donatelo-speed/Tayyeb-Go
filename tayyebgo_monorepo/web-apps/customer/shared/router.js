// SPA Router for TayyebGo Customer Web App
class Router {
  constructor() {
    this.routes = {};
    this.currentRoute = null;
    this.beforeEach = null;
    this.params = {};

    // Listen for back/forward buttons
    window.addEventListener('popstate', () => this.navigate(window.location.pathname));

    // Intercept link clicks
    document.addEventListener('click', (e) => {
      const link = e.target.closest('a[href]');
      if (link && link.href.startsWith(window.location.origin)) {
        e.preventDefault();
        this.navigate(link.getAttribute('href'));
      }
    });
  }

  // Register a route
  route(path, handler, options = {}) {
    this.routes[path] = { handler, ...options };
    return this;
  }

  // Set guard function
  guard(fn) {
    this.beforeEach = fn;
    return this;
  }

  // Navigate to a path
  async navigate(path, replace = false) {
    // Parse route and params
    const { routePath, params } = this.parseRoute(path);
    this.params = params;

    // Find matching route
    const route = this.routes[routePath] || this.routes['*'];

    // Run guard
    if (this.beforeEach) {
      const allowed = await this.beforeEach(routePath, this.currentRoute);
      if (!allowed) return;
    }

    // Update URL
    if (replace) {
      window.history.replaceState({}, '', path);
    } else {
      window.history.pushState({}, '', path);
    }

    this.currentRoute = routePath;

    // Execute route handler
    if (route && route.handler) {
      await route.handler(params);
    }
  }

  // Parse route with params (e.g., /restaurant/:id)
  parseRoute(path) {
    const pathParts = path.split('/').filter(Boolean);

    for (const routePath of Object.keys(this.routes)) {
      const routeParts = routePath.split('/').filter(Boolean);

      if (routeParts.length !== pathParts.length) continue;

      const params = {};
      let match = true;

      for (let i = 0; i < routeParts.length; i++) {
        if (routeParts[i].startsWith(':')) {
          params[routeParts[i].slice(1)] = pathParts[i];
        } else if (routeParts[i] !== pathParts[i]) {
          match = false;
          break;
        }
      }

      if (match) return { routePath, params };
    }

    return { routePath: path, params: {} };
  }

  // Get current params
  getParams() {
    return this.params;
  }

  // Initialize with current path
  init() {
    this.navigate(window.location.pathname, true);
  }
}

export const router = new Router();
export default router;
