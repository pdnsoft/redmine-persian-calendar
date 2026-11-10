/*
 * RTL row menus: Redmine positions #context-menu from the mouse and lets RTL
 * submenus open leftward, so menus opened from the row "…" button push
 * submenus off the left edge. Keep the menu at the click point, shift it only
 * when needed, and make submenus open to the right (reverse-x) where there is
 * room. Redmine re-places the menu when the AJAX menu arrives, so keep
 * re-applying for a short window.
 */
(function () {
  function centerHours() {
    document.querySelectorAll("table.time-entries td.hours, table#time-report td.hours").forEach(function (cell) {
      cell.style.setProperty("text-align", "center", "important");
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", centerHours);
  } else {
    centerHours();
  }
  document.addEventListener("ajax:complete", centerHours);

  if (document.documentElement.dir !== "rtl") return;

  var pointerX = null;

  function remember(event) {
    var point = event.touches && event.touches[0] ? event.touches[0] : event;
    if (typeof point.pageX === "number") pointerX = point.pageX;
  }

  function place() {
    var menu = document.getElementById("context-menu");
    if (!menu || !menu.children.length || pointerX === null) return;

    // jQuery .show() clears the inline display, so test layout instead.
    var width = menu.offsetWidth;
    if (!width) return;

    var margin = 4;
    var submenuRoom = 180;
    var scrollX = window.pageXOffset;
    var viewport = document.documentElement.clientWidth + scrollX;
    var left = Math.min(pointerX, viewport - width - margin);
    left = Math.max(left, margin + scrollX);

    // reverse-x makes RTL submenus open to the right (see context_menu.css)
    var flip = left + width + submenuRoom <= viewport - margin;
    if (!flip && left - submenuRoom < margin + scrollX) {
      // No room on either side: keep the menu on screen, submenu opens left.
      left = Math.min(left, viewport - width - margin);
    }

    if (menu.classList.contains("reverse-x") !== flip) {
      menu.classList.toggle("reverse-x", flip);
    }
    if (menu.style.right !== "auto") menu.style.right = "auto";
    if (parseFloat(menu.style.left) !== left) menu.style.left = left + "px";
  }

  function poll() {
    var frames = 0;
    (function tick() {
      place();
      if (++frames < 240) requestAnimationFrame(tick);
    })();
  }

  document.addEventListener("contextmenu", function (event) {
    remember(event);
    poll();
  }, true);

  document.addEventListener("click", function (event) {
    var target = event.target;
    if (!target || !target.closest || !target.closest(".js-contextmenu")) return;
    remember(event);
    poll();
  }, true);

  // Redmine may re-apply its own classes when the AJAX menu arrives or a
  // submenu is hovered; keep the placement consistent.
  document.addEventListener("mouseover", function (event) {
    var target = event.target;
    if (target && target.closest && target.closest("#context-menu")) place();
  }, true);
})();
