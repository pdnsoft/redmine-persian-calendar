# frozen_string_literal: true

module Redmine
  module PersianCalendar
    # Validation utilities for Persian calendar
    class Validator
      class << self
        # Validate Persian date string format
        def valid_date_format?(date_string)
          return false if date_string.blank?
          
          # Check for basic format: YYYY/MM/DD or YYYY-MM-DD
          return false unless date_string.match?(/^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}$/)
          
          parts = date_string.split(/[\/\-]/)
          return false unless parts.length == 3
          
          year, month, day = parts.map(&:to_i)
          DateConverter.valid_persian_date?(year, month, day)
        end
        
        # Validate Persian date range
        def valid_date_range?(start_date, end_date)
          return false unless valid_date_format?(start_date) && valid_date_format?(end_date)
          
          start_persian = PersianDate.parse(start_date)
          end_persian = PersianDate.parse(end_date)
          
          start_persian <= end_persian
        rescue StandardError
          false
        end
        
        # Validate Persian year
        def valid_year?(year)
          year.to_i.between?(1300, 1500)
        end
        
        # Validate Persian month
        def valid_month?(month)
          month.to_i.between?(1, 12)
        end
        
        # Validate Persian day for given year and month
        def valid_day?(year, month, day)
          return false unless valid_year?(year) && valid_month?(month)
          
          max_days = DateConverter.days_in_persian_month(year.to_i, month.to_i)
          day.to_i.between?(1, max_days)
        end
        
        # Sanitize Persian date input
        def sanitize_date_input(input)
          return nil if input.blank?
          
          # Convert Persian numerals to Western numerals
          sanitized = Redmine::PersianCalendar.to_western_numerals(input.to_s)
          
          # Remove extra whitespace
          sanitized.strip
        end
      end
    end
  end
end