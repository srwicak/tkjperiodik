document.addEventListener('turbo:load', function() {
  // Handle Turbo reload
  if (window.location.pathname === "/") { // Ganti "/" dengan path dashboard Anda jika berbeda
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
  }

  // Initialize dashboard elements
  initDashboard();
});

document.addEventListener('turbo:before-visit', function(event) {
  const flashNoticeElement = document.querySelector('.flash-notice');
  if (flashNoticeElement) {
    sessionStorage.setItem('flash_notice', flashNoticeElement.innerText);
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
      const parent = item.closest('.group')
      if (parent.classList.contains('selected')) {
        parent.classList.remove('selected')
      } else {
        document.querySelectorAll('.sidebar-dropdown-toggle').forEach(function (i) {
          i.closest('.group').classList.remove('selected')
        })
        parent.classList.add('selected')
      }
    })
  })

  // fullscreen
  const fullscreenButton = document.getElementById('fullscreen-button');

  if (fullscreenButton) {
    fullscreenButton.addEventListener('click', toggleFullscreen);
  }

  function toggleFullscreen() {
    if (document.fullscreenElement) {
      // If already in fullscreen, exit fullscreen
      document.exitFullscreen();
    } else {
      // If not in fullscreen, request fullscreen
      document.documentElement.requestFullscreen();
    }
  }
}
