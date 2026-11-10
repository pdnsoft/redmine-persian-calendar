# Force Persian Calendar Activation - Must load LAST
Rails.application.config.after_initialize do
  begin
    # Force load Persian calendar
    require 'redmine/persian_calendar'
    
    # Force enable configuration
    Rails.application.config.persian_calendar ||= ActiveSupport::OrderedOptions.new
    Rails.application.config.persian_calendar.enabled = true
    Rails.application.config.persian_calendar.default_calendar_type = 'persian'
    Rails.application.config.persian_calendar.cache_enabled = true
    Rails.application.config.persian_calendar.cache_expires_in = 1.hour
    Rails.application.config.persian_calendar.use_persian_numerals = true
    
    # Force include helpers in ActionView
    if defined?(PersianCalendarHelper)
      ActionView::Base.send :include, PersianCalendarHelper
    end
    
    # Force include Persian date support in models
    if defined?(PersianDateSupport)
      [Issue, TimeEntry, Version, News, Document].each do |model|
        unless model.included_modules.include?(PersianDateSupport)
          model.send :include, PersianDateSupport
        end
      end
    end
    
    # Override date display methods globally
    Date.class_eval do
      alias_method :original_to_s, :to_s
      
      def to_s(format = :default)
        if Rails.application.config.persian_calendar&.enabled && format == :default
          persian = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(self)
          "#{persian[:year]}/#{persian[:month].to_s.rjust(2, '0')}/#{persian[:day].to_s.rjust(2, '0')}"
        else
          original_to_s(format)
        end
      end
    end
  rescue => error
    Rails.logger.error("[PersianCalendar] Activation failed: #{error.message}")
  end
end
