// Rails BDD Generator - UX Enhancement JavaScript
// Theme: Literary

document.addEventListener('DOMContentLoaded', function() {

  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // Add animation classes to elements as they come into view
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('fade-in');
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  document.querySelectorAll('.card, .feature-card, tr').forEach(el => {
    observer.observe(el);
  });

  // Form validation feedback
  const forms = document.querySelectorAll('form');
  forms.forEach(form => {
    form.addEventListener('submit', function(e) {
      const requiredFields = form.querySelectorAll('[required]');
      let isValid = true;

      requiredFields.forEach(field => {
        if (!field.value.trim()) {
          field.classList.add('is-invalid');
          isValid = false;
        } else {
          field.classList.remove('is-invalid');
        }
      });

      if (!isValid) {
        e.preventDefault();
        // Show error message
        const alert = document.createElement('div');
        alert.className = 'alert alert-danger';
        alert.textContent = 'Please fill in all required fields.';
        form.insertBefore(alert, form.firstChild);

        setTimeout(() => alert.remove(), 5000);
      }
    });
  });

  // Auto-dismiss alerts
  document.querySelectorAll('.alert').forEach(alert => {
    setTimeout(() => {
      alert.style.transition = 'opacity 0.5s';
      alert.style.opacity = '0';
      setTimeout(() => alert.remove(), 500);
    }, 5000);
  });

  // Table row actions
  document.querySelectorAll('table tbody tr').forEach(row => {
    row.style.cursor = 'pointer';
    row.addEventListener('click', function(e) {
      if (!e.target.matches('a, button')) {
        const showLink = row.querySelector('a[href*="show"], a[href*="edit"]');
        if (showLink) {
          window.location = showLink.href;
        }
      }
    });
  });

  // Search form enhancements
  const searchInputs = document.querySelectorAll('.search-form input');
  searchInputs.forEach(input => {
    input.addEventListener('input', function() {
      if (this.value.length > 0) {
        this.classList.add('has-value');
      } else {
        this.classList.remove('has-value');
      }
    });
  });

  // Confirm dialogs
  document.querySelectorAll('[data-confirm]').forEach(element => {
    element.addEventListener('click', function(e) {
      if (!confirm(this.dataset.confirm)) {
        e.preventDefault();
      }
    });
  });

  // Mobile menu toggle (if needed)
  const menuToggle = document.querySelector('.menu-toggle');
  if (menuToggle) {
    menuToggle.addEventListener('click', function() {
      document.querySelector('.navbar-nav').classList.toggle('show');
    });
  }

  // Loading states for forms
  document.querySelectorAll('form').forEach(form => {
    form.addEventListener('submit', function() {
      const submitBtn = form.querySelector('[type="submit"]');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="spinner"></span> Processing...';
      }
    });
  });

  // Theme-specific enhancements
  // Add reading progress indicator
const article = document.querySelector('article');
if (article) {
  const progressBar = document.createElement('div');
  progressBar.className = 'reading-progress';
  progressBar.style.cssText = 'position: fixed; top: 0; left: 0; width: 0; height: 3px; background: var(--primary); z-index: 9999;';
  document.body.appendChild(progressBar);

  window.addEventListener('scroll', () => {
    const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
    const scrollPosition = window.pageYOffset;
    const progress = (scrollPosition / scrollHeight) * 100;
    progressBar.style.width = progress + '%';
  });
}

});

// Helper functions
function formatCurrency(amount) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(amount);
}

function formatDate(dateString) {
  const options = { year: 'numeric', month: 'long', day: 'numeric' };
  return new Date(dateString).toLocaleDateString(undefined, options);
}

// Debounce function for search
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}
