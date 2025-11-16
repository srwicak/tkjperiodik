document.addEventListener('turbo:load', function() {
  // Handle Turbo reload with Safari compatibility
  // Wrap sessionStorage in try-catch for Safari Private Browsing
  if (window.location.pathname === "/") {
    try {
      if (!sessionStorage.getItem('dashboard_reload')) {
        sessionStorage.setItem('dashboard_reload', 'true');
        Turbo.visit(window.location.href, { action: "replace" });
      } else {
        sessionStorage.removeItem('dashboard_reload');
        // Show flash notices if available
        const flashNotice = sessionStorage.getItem('flash_notice');
        if (flashNotice) {
          const flashElement = document.createElement('div');
          flashElement.className = 'flash-notice';
          flashElement.innerText = flashNotice;
          document.body.insertBefore(flashElement, document.body.firstChild);
          sessionStorage.removeItem('flash_notice');
        }
      }
    } catch (e) {
      // Safari Private Browsing blocks sessionStorage, continue without it
      console.warn('SessionStorage not available:', e);
    }
  }

  // Initialize dashboard elements
  initDashboard();
});

document.addEventListener('turbo:before-visit', function(event) {
  try {
    const flashNoticeElement = document.querySelector('.flash-notice');
    if (flashNoticeElement) {
      sessionStorage.setItem('flash_notice', flashNoticeElement.innerText);
    }
  } catch (e) {
    // Safari Private Browsing blocks sessionStorage, continue without it
    console.warn('SessionStorage not available:', e);
  }
});

function initDashboard() {
  const sidebarToggle = document.querySelector('.sidebar-toggle');
  const sidebarOverlay = document.querySelector('.sidebar-overlay');
  const sidebarMenu = document.querySelector('.sidebar-menu');
  const main = document.querySelector('.main');

  if (sidebarToggle) {
    sidebarToggle.addEventListener('click', function(e) {
      e.preventDefault();
      main.classList.toggle('active');
      sidebarOverlay.classList.toggle('hidden');
      sidebarMenu.classList.toggle('md:-translate-x-full');
      sidebarMenu.classList.toggle('-translate-x-full');
      sidebarMenu.classList.toggle('md:translate-x-0');
    });
  }

  if (sidebarOverlay) {
    sidebarOverlay.addEventListener('click', function(e) {
      e.preventDefault();
      main.classList.remove('active');
      sidebarOverlay.classList.toggle('hidden');
      sidebarMenu.classList.toggle('-translate-x-full');
    });
  }

  document.querySelectorAll('.sidebar-dropdown-toggle').forEach(function (item) {
    item.addEventListener('click', function (e) {
      e.preventDefault()
      // Safari-compatible closest() with fallback
      let parent = item.closest ? item.closest('.group') : findAncestor(item, 'group');
      if (parent && parent.classList.contains('selected')) {
        parent.classList.remove('selected')
      } else if (parent) {
        document.querySelectorAll('.sidebar-dropdown-toggle').forEach(function (i) {
          let p = i.closest ? i.closest('.group') : findAncestor(i, 'group');
          if (p) p.classList.remove('selected')
        })
        parent.classList.add('selected')
      }
    })
  })

  // Helper function for older browsers
  function findAncestor(el, cls) {
    while ((el = el.parentElement) && !el.classList.contains(cls));
    return el;
  }

  // fullscreen with Safari compatibility
  const fullscreenButton = document.getElementById('fullscreen-button');

  if (fullscreenButton) {
    fullscreenButton.addEventListener('click', toggleFullscreen);
  }

  function toggleFullscreen() {
    // Safari uses webkitFullscreenElement
    const isFullscreen = document.fullscreenElement || document.webkitFullscreenElement;
    
    if (isFullscreen) {
      // Exit fullscreen with Safari compatibility
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
      }
    } else {
      // Enter fullscreen with Safari compatibility
      const elem = document.documentElement;
      if (elem.requestFullscreen) {
        elem.requestFullscreen();
      } else if (elem.webkitRequestFullscreen) {
        elem.webkitRequestFullscreen();
      }
    }
  }
}
