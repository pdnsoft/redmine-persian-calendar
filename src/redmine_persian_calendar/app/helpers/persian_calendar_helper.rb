# frozen_string_literal: true

# Persian Calendar Helper for Redmine
# Provides helper methods for Persian calendar functionality
module PersianCalendarHelper
  # Generate Persian calendar datepicker for a form field
  # @param field_id [String] HTML field ID
  # @param options [Hash] Datepicker options
  # @return [String] HTML and JavaScript for Persian datepicker
  def persian_calendar_for(field_id, options = {})
    return unless Redmine::PersianCalendar.enabled?
    
    # Include Persian calendar assets
    include_persian_calendar_assets
    
    # Default options
    default_options = {
      format: 'YYYY/MM/DD',
      initial_value: false,
      alt_field: ".#{field_id}_gregorian",
      alt_format: 'gregorian',
      calendar_type: 'persian',
      locale: 'fa'
    }
    
    options = default_options.merge(options)
    
    # Generate JavaScript initialization
    javascript_tag do
      <<~JS
        document.addEventListener('DOMContentLoaded', function() {
          const element = document.getElementById('#{field_id}');
          if (element && window.persianDatepicker) {
            element.persianDatepicker = new window.persianDatepicker(element, #{options.to_json});
          }
        });
      JS
    end
  end
  
  # Generate Persian date field tag
  # @param name [String] Field name
  # @param value [String, Date, nil] Field value
  # @param options [Hash] HTML options
  # @return [String] HTML input field with Persian datepicker
  def persian_date_field_tag(name, value = nil, options = {})
    return date_field_tag(name, value, options) unless Redmine::PersianCalendar.enabled?
    
    # Convert value to Persian format if it's a Date
    persian_value = if value.is_a?(Date) || value.is_a?(Time)
                      persian_date = Redmine::PersianCalendar::PersianDate.from_gregorian(value)
                      persian_date.format('YYYY/MM/DD')
                    else
                      value
                    end
    
    # Generate field ID
    field_id = options[:id] || name.to_s.gsub(/[\[\]]/, '_').gsub(/__+/, '_').chomp('_')
    
    # HTML options
    html_options = options.merge(
      id: field_id,
      class: "#{options[:class]} persian-datepicker".strip,
      data: { 
        'persian-calendar': true,
        'alt-field': "##{field_id}_gregorian"
      }
    )
    
    # Generate Persian date input and hidden Gregorian input
    persian_input = text_field_tag(name, persian_value, html_options)
    gregorian_input = hidden_field_tag("#{name}_gregorian", value, id: "#{field_id}_gregorian")
    
    # Combine inputs with datepicker initialization
    content = persian_input + gregorian_input + persian_calendar_for(field_id)
    content.html_safe
  end
  
  # Generate Persian datetime field tag
  # @param name [String] Field name
  # @param value [String, DateTime, nil] Field value
  # @param options [Hash] HTML options
  # @return [String] HTML input field with Persian datetime picker
  def persian_datetime_field_tag(name, value = nil, options = {})
    return datetime_local_field_tag(name, value, options) unless Redmine::PersianCalendar.enabled?
    
    # Convert value to Persian format if it's a DateTime
    persian_value = if value.is_a?(DateTime) || value.is_a?(Time)
                      persian_date = Redmine::PersianCalendar::PersianDate.from_gregorian(value)
                      time_part = value.strftime('%H:%M')
                      "#{persian_date.format('YYYY/MM/DD')} #{time_part}"
                    else
                      value
                    end
    
    # Use Persian date field with time support
    persian_date_field_tag(name, persian_value, options.merge(data: { 'time-picker': true }))
  end
  
  # Format Persian date for display
  # @param date [Date, Time, String] Date to format
  # @param format [Symbol, String] Format pattern
  # @return [String] Formatted Persian date
  def format_persian_date(date, format = :default)
    return '' if date.nil?
    return date.to_s unless Redmine::PersianCalendar.enabled?
    
    begin
      persian_date = case date
                     when Redmine::PersianCalendar::PersianDate
                       date
                     else
                       Redmine::PersianCalendar::PersianDate.from_gregorian(date)
                     end
      
      format_pattern = case format
                       when :default
                         'YYYY/MM/DD'
                       when :short
                         'YY/M/D'
                       when :long
                         'dddd، D MMMM YYYY'
                       when :month_year
                         'MMMM YYYY'
                       else
                         format.to_s
                       end
      
      persian_date.format(format_pattern)
    rescue StandardError => e
      Rails.logger.warn "Persian date formatting error: #{e.message}"
      date.to_s
    end
  end
  
  # Format Persian time for display
  # @param time [Time, DateTime] Time to format
  # @param format [Symbol, String] Format pattern
  # @return [String] Formatted Persian time
  def format_persian_time(time, format = :default)
    return '' if time.nil?
    return format_time(time) unless Redmine::PersianCalendar.enabled?
    
    begin
      persian_date = Redmine::PersianCalendar::PersianDate.from_gregorian(time)
      time_part = time.strftime('%H:%M')
      
      case format
      when :default
        "#{persian_date.format('YYYY/MM/DD')} #{time_part}"
      when :short
        "#{persian_date.format('YY/M/D')} #{time_part}"
      when :long
        "#{persian_date.format('dddd، D MMMM YYYY')} ساعت #{time_part}"
      else
        "#{persian_date.format(format.to_s)} #{time_part}"
      end
    rescue StandardError => e
      Rails.logger.warn "Persian time formatting error: #{e.message}"
      format_time(time)
    end
  end
  
  # Generate Persian date tooltip
  # @param date [Date, Time] Date for tooltip
  # @return [String] Tooltip text with both Persian and Gregorian dates
  def persian_date_tooltip(date)
    return '' if date.nil?
    return date.to_s unless Redmine::PersianCalendar.enabled?
    
    begin
      persian_date = Redmine::PersianCalendar::PersianDate.from_gregorian(date)
      gregorian_formatted = date.strftime('%Y-%m-%d')
      persian_formatted = persian_date.format('YYYY/MM/DD')
      
      "#{persian_formatted} (#{gregorian_formatted})"
    rescue StandardError => e
      Rails.logger.warn "Persian date tooltip error: #{e.message}"
      date.to_s
    end
  end
  
  # Generate link to Persian month
  # @param date [Date, PersianDate] Date to link to
  # @param options [Hash] Link options
  # @return [String] HTML link to month view
  def link_to_persian_month(date, options = {})
    return link_to_month(date.month, date.year, date.month, options) unless Redmine::PersianCalendar.enabled?
    
    begin
      persian_date = date.is_a?(Redmine::PersianCalendar::PersianDate) ? date : Redmine::PersianCalendar::PersianDate.from_gregorian(date)
      
      # Default link text
      link_text = options.delete(:text) || persian_date.format('MMMM YYYY')
      
      # Generate link parameters
      link_params = {
        year: persian_date.year,
        month: persian_date.month,
        calendar_type: 'persian'
      }.merge(options.delete(:params) || {})
      
      # Merge with current request parameters
      final_params = request.query_parameters.merge(link_params)
      
      link_to(link_text, { params: final_params }, options)
    rescue StandardError => e
      Rails.logger.warn "Persian month link error: #{e.message}"
      link_to_month(date.month, date.year, date.month, options)
    end
  end
  
  # Generate Persian month navigation
  # @param current_date [Date, PersianDate] Current date
  # @return [String] HTML navigation with previous/next month links
  def persian_month_navigation(current_date)
    return '' unless Redmine::PersianCalendar.enabled?
    
    begin
      persian_date = current_date.is_a?(Redmine::PersianCalendar::PersianDate) ? current_date : Redmine::PersianCalendar::PersianDate.from_gregorian(current_date)
      
      # Previous month
      prev_month = persian_date.prev_month
      prev_link = link_to_persian_month(prev_month, text: "« #{prev_month.format('MMMM')}")
      
      # Next month  
      next_month = persian_date.next_month
      next_link = link_to_persian_month(next_month, text: "#{next_month.format('MMMM')} »")
      
      # Current month header
      current_header = persian_calendar_header(persian_date)
      
      content_tag(:div, class: 'persian-month-navigation') do
        content_tag(:div, prev_link, class: 'prev-month') +
        content_tag(:div, current_header, class: 'current-month') +
        content_tag(:div, next_link, class: 'next-month')
      end
    rescue StandardError => e
      Rails.logger.warn "Persian month navigation error: #{e.message}"
      ''
    end
  end
  
  # Generate Persian calendar header
  # @param date [Date, PersianDate] Date for header
  # @return [String] HTML calendar header with month and year
  def persian_calendar_header(date)
    return '' unless Redmine::PersianCalendar.enabled?
    
    begin
      persian_date = date.is_a?(Redmine::PersianCalendar::PersianDate) ? date : Redmine::PersianCalendar::PersianDate.from_gregorian(date)
      
      month_name = persian_date.format('MMMM')
      year = persian_date.format('YYYY')
      
      content_tag(:h2, class: 'persian-calendar-header') do
        content_tag(:span, month_name, class: 'month-name') + ' ' +
        content_tag(:span, year, class: 'year')
      end
    rescue StandardError => e
      Rails.logger.warn "Persian calendar header error: #{e.message}"
      content_tag(:h2, date.to_s)
    end
  end
  
  private
  
  # Include Persian calendar CSS and JavaScript assets
  def include_persian_calendar_assets
    return if @persian_calendar_assets_included
    
    content_for :header_tags do
      stylesheet_link_tag('persian_calendar', media: 'all') +
      javascript_include_tag('persian-date') +
      javascript_include_tag('persian-datepicker') +
      javascript_include_tag('persian_calendar_controller')
    end
    
    @persian_calendar_assets_included = true
  end
end