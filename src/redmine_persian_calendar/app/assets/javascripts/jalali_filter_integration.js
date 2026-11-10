// Jalali Filter Integration — Minimal reliable approach
// Does NOT add Jalali UI to filter inputs — just lets native datepicker work
// format_date override handles Jalali display elsewhere

(function() {
  // Only run if JalaliDatePicker is loaded
  function waitForJalali(cb) {
    if (typeof JalaliDatePicker !== 'undefined') return cb();
    var check = setInterval(function() {
      if (typeof JalaliDatePicker !== 'undefined') {
        clearInterval(check);
        cb();
      }
    }, 100);
    setTimeout(function() { clearInterval(check); }, 10000);
  }

  waitForJalali(function() {
    // Initialize Jalali ONLY on form date inputs (start_date, due_date, spent_on)
    // NOT on filter value inputs — those use native datepicker
    function initFormPickers() {
      if (typeof JalaliDatePicker === 'undefined') return;

      // Only form inputs — NOT filter values_* inputs
      var selectors = [
        '#issue_start_date',
        '#issue_due_date',
        '#time_entry_spent_on',
        '#version_effective_date'
      ];

      var selector = selectors.join(', ');

      $(selector).not('.jalali-initialized').each(function() {
        var input = this;
        var $input = $(input);

        // Skip if already has Jalali
        if (input.getAttribute('data-jalali-picker') === 'true') return;
        if ($input.next('.jalali-date-picker-container').length > 0) return;

        try {
          new JalaliDatePicker(input, {
            onDateSelect: function(dateData) {
              $input.trigger('change').trigger('input');
            }
          }).initializeFromInput();

          $input.addClass('jalali-initialized');
        } catch (e) {}
      });
    }

    // Run on page load and after AJAX
    initFormPickers();
    if (typeof jQuery !== 'undefined') {
      jQuery(document).on('ajax:complete', function() {
        setTimeout(initFormPickers, 300);
      });
    }

    // Also run periodically for dynamic forms
    setInterval(initFormPickers, 1000);
  });
})();
