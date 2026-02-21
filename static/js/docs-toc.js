/**
 * Docs TOC scroll-spy
 * Highlights the current section in the Table of Contents as the user scrolls.
 */
(function () {
  const toc = document.querySelector('.docs-toc');
  if (!toc) return;

  const links = toc.querySelectorAll('nav a');
  if (!links.length) return;

  // Build a map of anchor href -> heading element
  // Use getElementById instead of querySelector because Hugo generates
  // IDs like "1-start-athyr" which aren't valid CSS selectors.
  const headings = [];
  links.forEach(function (link) {
    const href = link.getAttribute('href');
    if (!href || !href.startsWith('#')) return;
    const target = document.getElementById(href.slice(1));
    if (target) headings.push({ el: target, link: link });
  });

  if (!headings.length) return;

  var active = null;

  function update() {
    // Find the heading closest to the top of the viewport
    var current = null;
    var offset = 120; // offset for sticky nav

    for (var i = 0; i < headings.length; i++) {
      if (headings[i].el.getBoundingClientRect().top <= offset) {
        current = headings[i];
      }
    }

    // If no heading has scrolled past the offset, highlight the first one
    if (!current) {
      current = headings[0];
    }

    if (current === active) return;

    if (active) active.link.classList.remove('active');
    if (current) current.link.classList.add('active');
    active = current;
  }

  // Throttle scroll events
  var ticking = false;
  window.addEventListener('scroll', function () {
    if (!ticking) {
      requestAnimationFrame(function () {
        update();
        ticking = false;
      });
      ticking = true;
    }
  });

  // Initial highlight
  update();
})();
