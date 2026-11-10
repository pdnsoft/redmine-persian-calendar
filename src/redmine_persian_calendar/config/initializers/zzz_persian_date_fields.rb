# Persian Date Fields Integration with Jalali Date Picker
# This initializer overrides Redmine's date field helpers to add Persian calendar support

Rails.application.config.after_initialize do
  # Override ApplicationHelper to add Persian date functionality
  ApplicationHelper.class_eval do
    
    # Override calendar_for to DISABLE original datepicker (let our universal system handle it)
    def calendar_for_with_persian(field_id)
      include_calendar_headers_tags
      
      # Just disable the original datepicker - our universal system will handle initialization
      javascript_tag(<<~JS)
        $(function() { 
          var field = $('##{field_id}');
          
          // Remove the original datepicker functionality
          field.removeClass('date');
          
          // Remove the calendar button if it exists
          field.next('img').remove();
          
        });
      JS
    end
    
    alias_method :calendar_for_without_persian, :calendar_for
    alias_method :calendar_for, :calendar_for_with_persian
    
    # Override include_calendar_headers_tags to include Jalali Date Picker
    def include_calendar_headers_tags_with_persian
      unless @calendar_headers_tags_included
        tags = ''.html_safe
        @calendar_headers_tags_included = true
        content_for :header_tags do
          start_of_week = Setting.start_of_week
          start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
          start_of_week = start_of_week.to_i % 7
          
          # Original datepicker options (kept for compatibility)
          tags <<
            javascript_tag(
              "var datepickerOptions={dateFormat: 'yy-mm-dd', firstDay: #{start_of_week}, " \
                "showOn: 'button', buttonImageOnly: true, buttonImage: '" +
              asset_path('calendar.png') +
                "', showButtonPanel: true, showWeek: true, showOtherMonths: true, " \
                "selectOtherMonths: true, changeMonth: true, changeYear: true, " \
                "beforeShow: beforeShowDatePicker};"
            )
          
          # Include Jalali Date Picker JavaScript and CSS
          tags << javascript_include_tag('jalali_date_picker')
          tags << stylesheet_link_tag('jalali_date_picker')
          
          # CSS to immediately hide native datepicker elements for filter fields
          tags << content_tag(:style, <<~CSS)
            /* Immediately hide native datepicker elements for filter fields */
            input[id*="values_"][type="date"]:not(.jalali-initialized),
            input[name*="values_"][type="date"]:not(.jalali-initialized) {
              opacity: 0 !important;
              pointer-events: none !important;
              position: absolute !important;
              left: -9999px !important;
            }
            
            /* Hide calendar buttons for filter fields */
            input[id*="values_"] + img[src*="calendar"],
            input[name*="values_"] + img[src*="calendar"] {
              display: none !important;
            }
            
            /* Ensure Jalali picker containers are visible */
            .jalali-date-picker-container {
              opacity: 1 !important;
              pointer-events: auto !important;
              position: relative !important;
              left: auto !important;
            }
          CSS
          
          # Universal Jalali Date Picker initialization (SINGLE SYSTEM)
          tags << javascript_tag(<<~JS)
            $(document).ready(function() {
              // Global tracker to prevent duplicate initialization
              window.jalaliPickerInstances = window.jalaliPickerInstances || new Set();
              
              // Initialize Jalali Date Picker for all date input fields
              function initializeAllJalaliPickers() {
                if (typeof JalaliDatePicker === 'undefined') {
                  return;
                }
                
                // Find ONLY specific date input fields (more selective)
                var dateInputs = $('input[type="date"]')
                  .filter('[id*="date"], [name*="date"], [id*="spent_on"], [name*="spent_on"], [id*="effective_date"], [name*="effective_date"], [id*="values_"], [name*="values_"], .jalali-date-target')
                  .not('[readonly]')
                  .not('[disabled]')
                  .not('[id*="confidential"]')  // Exclude confidential checkbox area
                  .not('[name*="confidential"]')
                  .not('.jalali-initialized');  // Skip already initialized
                
                dateInputs.each(function() {
                  var input = this;
                  var $input = $(input);
                  var fieldId = input.id || input.name || 'field_' + Math.random().toString(36).substr(2, 9);
                  
                  // Additional validation - only initialize for actual date fields
                  if (!fieldId.match(/(date|spent_on|effective_date|values_.*_(1|2)$)/i)) {
                    return;
                  }
                  
                  // Skip if already initialized (using unique field identifier)
                  if (window.jalaliPickerInstances.has(fieldId)) {
                    return;
                  }
                  
                  // CRITICAL: Skip if already has jalali container (double-check)
                  if ($input.next('.jalali-date-picker-container').length > 0) {
                    window.jalaliPickerInstances.add(fieldId);
                    return;
                  }
                  
                  // ROBUST DUPLICATION PREVENTION
                  // Remove any existing native datepicker elements that might interfere
                  $input.siblings('img[src*="calendar"]').remove(); // Remove calendar button
                  $input.removeClass('hasDatepicker'); // Remove jQuery datepicker class
                  if ($input.data('datepicker')) {
                    try {
                      $input.datepicker('destroy');
                    } catch(e) {
                      // Ignore errors during cleanup
                    }
                  }
                  
                  // Mark as initialized BEFORE creating picker
                  window.jalaliPickerInstances.add(fieldId);
                  $input.addClass('jalali-initialized');
                  
                  try {
                    // Initialize Jalali Date Picker
                    var picker = new JalaliDatePicker(input, {
                      onDateSelect: function(dateData) {
                        
                        // Trigger change event for any listeners
                        $input.trigger('change');
                      }
                    });
                    
                    // Initialize from existing value if present
                    picker.initializeFromInput();
                    
                  } catch (error) {
                    // Remove from tracker if failed
                    window.jalaliPickerInstances.delete(fieldId);
                  }
                });
              }
              
              // Initialize on page load
              setTimeout(initializeAllJalaliPickers, 100);
              
              // AGGRESSIVE INTERCEPTION: Monitor DOM mutations for filter date inputs
              if (typeof MutationObserver !== 'undefined') {
                var filterObserver = new MutationObserver(function(mutations) {
                  var shouldInit = false;
                  mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList') {
                      mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) { // Element node
                          // Check if it's a date input or contains date inputs
                          var isDateInput = node.tagName === 'INPUT' && node.type === 'date' && 
                                          (node.id.includes('values_') || node.name.includes('values_'));
                          var hasDateInputs = $(node).find('input[type="date"][id*="values_"], input[type="date"][name*="values_"]').length > 0;
                          
                          if (isDateInput || hasDateInputs) {
                            shouldInit = true;
                          }
                        }
                      });
                    }
                  });
                  
                  if (shouldInit) {
                    // Very quick initialization for new filter fields
                    setTimeout(initializeAllJalaliPickers, 10);
                  }
                });
                
                // Observe the filters table and entire document for changes
                filterObserver.observe(document.body, {
                  childList: true,
                  subtree: true
                });
              }
              
              // Re-initialize when new content is loaded (for AJAX updates)
              var initTimeout;
              $(document).on('DOMNodeInserted', function(e) {
                // Debounce to avoid excessive calls
                clearTimeout(initTimeout);
                initTimeout = setTimeout(function() {
                  initializeAllJalaliPickers();
                }, 200);
              });
              
              // Also initialize on common Redmine AJAX events
              $(document).on('ajax:complete', function() {
                setTimeout(initializeAllJalaliPickers, 300);
              });
              
              // Initialize on form updates (for filters, etc.)
              $(document).on('change', 'select[name*="filter"], select[id*="filter"]', function() {
                setTimeout(initializeAllJalaliPickers, 400);
              });
              
              // SPECIFIC HANDLING FOR FILTER DATE FIELDS
              // Monitor when filters are added/changed (for time entries and other queries)
              $(document).on('change', '#add_filter_select', function() {
                // When a new filter is added, wait for it to be built then initialize
                setTimeout(function() {
                  initializeAllJalaliPickers();
                }, 500);
              });
              
              // Monitor operator changes that might show/hide date fields
              $(document).on('change', 'select[id^="operators_"]', function() {
                setTimeout(function() {
                  initializeAllJalaliPickers();
                }, 300);
              });
              
              // Monitor when filter checkboxes are toggled
              $(document).on('change', 'input[name="f[]"]', function() {
                var filterName = $(this).val();
                
                // If it's a date-related filter, handle it specially
                if (filterName && filterName.match(/(date|spent_on|effective_date)/i)) {
                  if ($(this).is(':checked')) {
                    // Filter enabled - initialize Jalali pickers
                    setTimeout(function() {
                      initializeAllJalaliPickers();
                    }, 100);
                  } else {
                    // Filter disabled - clean up any orphaned pickers
                    setTimeout(function() {
                      cleanupOrphanedPickers(filterName);
                    }, 50);
                  }
                } else {
                  // For other filters, still check for new date fields
                  setTimeout(function() {
                    initializeAllJalaliPickers();
                  }, 200);
                }
              });
              
              // Cleanup function for orphaned pickers
              function cleanupOrphanedPickers(filterName) {
                var fieldId = filterName.replace('.', '_');
                
                // Remove from tracker
                window.jalaliPickerInstances.delete('values_' + fieldId + '_1');
                window.jalaliPickerInstances.delete('values_' + fieldId + '_2');
                
                // Clean up any orphaned containers
                $('.jalali-date-picker-container').each(function() {
                  var $container = $(this);
                  var $hiddenInput = $container.prev('input[type="date"]');
                  
                  // If the hidden input doesn't exist or is not visible in DOM, remove container
                  if ($hiddenInput.length === 0 || !$hiddenInput.closest('#filters-table').length) {
                    $container.remove();
                  }
                });
              }
            });
          JS
          
          jquery_locale = l('jquery.locale', :default => current_language.to_s)
          unless jquery_locale == 'en'
            tags << javascript_include_tag("i18n/datepicker-#{jquery_locale}.js")
          end
          tags
        end
      end
    end
    
    alias_method :include_calendar_headers_tags_without_persian, :include_calendar_headers_tags
    alias_method :include_calendar_headers_tags, :include_calendar_headers_tags_with_persian
  end
end
