/**
 * Copy to clipboard functionality for code blocks
 */
(function() {
  'use strict';

  function addCopyButtons() {
    const codeBlocks = document.querySelectorAll('pre');

    codeBlocks.forEach(function(pre) {
      // Skip if already has a copy button
      if (pre.parentElement.classList.contains('code-wrapper')) return;

      // Wrap pre in a container for positioning
      const wrapper = document.createElement('div');
      wrapper.className = 'code-wrapper';
      pre.parentNode.insertBefore(wrapper, pre);
      wrapper.appendChild(pre);

      // Create copy button
      const button = document.createElement('button');
      button.className = 'copy-btn';
      button.setAttribute('aria-label', 'Copy code');
      button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';

      button.addEventListener('click', function() {
        const code = pre.querySelector('code') || pre;
        const text = code.textContent;

        navigator.clipboard.writeText(text).then(function() {
          button.classList.add('copied');
          button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>';

          setTimeout(function() {
            button.classList.remove('copied');
            button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';
          }, 2000);
        });
      });

      wrapper.appendChild(button);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addCopyButtons);
  } else {
    addCopyButtons();
  }
})();
