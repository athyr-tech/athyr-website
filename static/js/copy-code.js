/**
 * Copy to clipboard functionality for code blocks (GitHub style)
 */
(function() {
  'use strict';

  var copyIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';
  var checkIcon = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>';

  function addCopyButtons() {
    var codeBlocks = document.querySelectorAll('pre');

    codeBlocks.forEach(function(pre) {
      if (pre.parentElement.classList.contains('code-block-wrapper')) return;
      if (pre.parentElement.classList.contains('code-block')) return;
      if (pre.classList.contains('hero-terminal-body')) return;

      // Get language from code element class (e.g., "language-go")
      var code = pre.querySelector('code');
      var lang = '';
      if (code && code.className) {
        var match = code.className.match(/language-(\w+)/);
        if (match) lang = match[1];
      }

      // Create wrapper
      var wrapper = document.createElement('div');
      wrapper.className = 'code-block-wrapper';
      pre.parentNode.insertBefore(wrapper, pre);

      // Create header
      var header = document.createElement('div');
      header.className = 'code-block-header';

      // Language label
      var langSpan = document.createElement('span');
      langSpan.className = 'code-block-lang';
      langSpan.textContent = lang || 'code';
      header.appendChild(langSpan);

      // Copy button
      var button = document.createElement('button');
      button.className = 'code-block-copy';
      button.setAttribute('aria-label', 'Copy code');
      button.innerHTML = copyIcon + '<span>Copy</span>';

      button.addEventListener('click', function() {
        var text = (code || pre).textContent;

        navigator.clipboard.writeText(text).then(function() {
          button.classList.add('copied');
          button.innerHTML = checkIcon + '<span>Copied!</span>';

          setTimeout(function() {
            button.classList.remove('copied');
            button.innerHTML = copyIcon + '<span>Copy</span>';
          }, 2000);
        });
      });

      header.appendChild(button);
      wrapper.appendChild(header);
      wrapper.appendChild(pre);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addCopyButtons);
  } else {
    addCopyButtons();
  }
})();
