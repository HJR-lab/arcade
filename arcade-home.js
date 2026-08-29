/*
 * Rivers Arcade — shared "back to the arcade" button.
 *
 * Drop this into any game page:
 *   <script src="../../arcade-home.js"></script>
 *
 * The link target is derived from this script's own src, so the button works
 * from any folder depth without hardcoding a path.
 *
 * Optional attributes on the <script> tag:
 *   data-corner="top-left|top-right|bottom-left|bottom-right"  (default top-left)
 *   data-label="ARCADE"        text shown on the button
 *   data-hide-on-touch="true"  hide it on touch devices, where games often
 *                              put on-screen controls in the corners
 *
 * The button lives in a shadow root so game stylesheets can't restyle it and
 * its own styles can't leak into the game.
 */
(function () {
  'use strict';

  var script = document.currentScript;
  if (!script) return;

  var corner = (script.dataset.corner || 'top-left').toLowerCase();
  var label = script.dataset.label || 'ARCADE';
  var hideOnTouch = script.dataset.hideOnTouch === 'true';
  var homeHref = new URL('index.html', script.src).href;

  function build() {
    if (hideOnTouch && window.matchMedia && window.matchMedia('(pointer: coarse)').matches) return;
    if (document.getElementById('arcade-home-button')) return;

    var host = document.createElement('div');
    host.id = 'arcade-home-button';
    var root = host.attachShadow({ mode: 'open' });

    var top = corner.indexOf('top') === 0;
    var left = corner.indexOf('left') !== -1;
    var vertical = top
      ? 'top: calc(env(safe-area-inset-top, 0px) + 10px);'
      : 'bottom: calc(env(safe-area-inset-bottom, 0px) + 10px);';
    var horizontal = left
      ? 'left: calc(env(safe-area-inset-left, 0px) + 10px);'
      : 'right: calc(env(safe-area-inset-right, 0px) + 10px);';

    root.innerHTML =
      '<style>' +
      ':host { position: fixed; ' + vertical + horizontal +
      ' z-index: 2147483000; -webkit-tap-highlight-color: transparent; }' +
      'a {' +
      '  display: inline-flex; align-items: center; gap: 7px;' +
      '  font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;' +
      '  font-size: 11px; font-weight: 700; letter-spacing: 0.12em;' +
      '  text-decoration: none; white-space: nowrap;' +
      '  color: #00ffff; background: rgba(13, 2, 33, 0.72);' +
      '  border: 1px solid rgba(0, 255, 255, 0.55); border-radius: 999px;' +
      '  padding: 7px 13px; cursor: pointer;' +
      '  backdrop-filter: blur(6px); -webkit-backdrop-filter: blur(6px);' +
      '  box-shadow: 0 0 10px rgba(0, 255, 255, 0.22);' +
      '  text-shadow: 0 0 6px rgba(0, 255, 255, 0.5);' +
      '  transition: color 0.15s, border-color 0.15s, box-shadow 0.15s, background 0.15s;' +
      '  opacity: 0.82;' +
      '}' +
      'a:hover, a:focus-visible {' +
      '  opacity: 1; color: #ff6ec7; border-color: rgba(255, 110, 199, 0.8);' +
      '  background: rgba(13, 2, 33, 0.9);' +
      '  box-shadow: 0 0 14px rgba(255, 110, 199, 0.45);' +
      '}' +
      'a:active { transform: translateY(1px); }' +
      '.icon { font-size: 13px; line-height: 1; }' +
      '@media (max-width: 480px) { a { font-size: 10px; padding: 6px 10px; } }' +
      '@media (prefers-reduced-motion: reduce) { a { transition: none; } }' +
      '</style>' +
      '<a part="button" href="' + homeHref + '" title="Back to Rivers Arcade">' +
      '<span class="icon" aria-hidden="true">&#9664;</span><span></span></a>';

    var link = root.querySelector('a');
    link.lastElementChild.textContent = label;

    // Games often listen for clicks/keys on the document (jump, shoot, ...).
    // Keep our own events from reaching them.
    ['click', 'pointerdown', 'mousedown', 'touchstart', 'keydown'].forEach(function (type) {
      link.addEventListener(type, function (e) { e.stopPropagation(); });
    });

    document.body.appendChild(host);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', build);
  } else {
    build();
  }
})();
