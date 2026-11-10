# frozen_string_literal: true

# Persian Calendar Configuration for Redmine
# This initializer sets up Persian/Jalali calendar support

Rails.application.configure do
  # Persian calendar configuration
  config.persian_calendar = ActiveSupport::OrderedOptions.new
  
  # Enable Persian calendar support (can be disabled for rollback)
  config.persian_calendar.enabled = true
  
  # Default calendar type for new users
  config.persian_calendar.default_calendar_type = 'persian'
  
  # Cache configuration for date conversions
  config.persian_calendar.cache_enabled = true
  config.persian_calendar.cache_expires_in = 1.hour
  
  # Supported date range (Persian years)
  config.persian_calendar.min_year = 1300  # ~1921 CE
  config.persian_calendar.max_year = 1500  # ~2121 CE
  
  # Persian numeral display
  config.persian_calendar.use_persian_numerals = true
  
  # Leap year calculation mode
  config.persian_calendar.leap_year_mode = 'algorithmic'  # or 'astronomical'
end

# Load Persian calendar components after Rails initialization
Rails.application.config.after_initialize do
  # Require Persian calendar components
  require_dependency 'redmine/persian_calendar'
end