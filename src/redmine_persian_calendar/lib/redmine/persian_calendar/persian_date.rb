# frozen_string_literal: true

module Redmine
  module PersianCalendar
    # Persian date object with formatting and calculation methods
    # Provides a convenient interface for working with Persian dates
    class PersianDate
      attr_reader :year, :month, :day
      
      # Initialize Persian date
      # @param year [Integer] Persian year
      # @param month [Integer] Persian month (1-12)
      # @param day [Integer] Persian day
      def initialize(year, month, day)
        @year = year.to_i
        @month = month.to_i
        @day = day.to_i
        
        unless DateConverter.valid_persian_date?(@year, @month, @day)
          raise InvalidDateError, "Invalid Persian date: #{@year}/#{@month}/#{@day}"
        end
      end
      
      # Create PersianDate from Gregorian date
      # @param gregorian_date [Date, Time, String] Gregorian date
      # @return [PersianDate] Persian date object
      def self.from_gregorian(gregorian_date)
        persian_components = DateConverter.gregorian_to_jalali(gregorian_date)
        new(persian_components[:year], persian_components[:month], persian_components[:day])
      end
      
      # Create PersianDate from Persian date string
      # @param persian_date_string [String] Persian date in 'YYYY/MM/DD' format
      # @return [PersianDate] Persian date object
      def self.parse(persian_date_string)
        parts = persian_date_string.split(/[\/\-]/)
        raise InvalidDateError, "Invalid Persian date format" unless parts.length == 3
        
        new(parts[0].to_i, parts[1].to_i, parts[2].to_i)
      end
      
      # Get current Persian date
      # @return [PersianDate] Current Persian date
      def self.today
        from_gregorian(Date.current)
      end
      
      # Convert to Gregorian date
      # @return [Date] Gregorian date
      def to_gregorian
        DateConverter.jalali_to_gregorian(year: @year, month: @month, day: @day)
      end
      
      # Format Persian date according to pattern
      # @param pattern [String] Format pattern
      # @return [String] Formatted Persian date
      def format(pattern = 'YYYY/MM/DD')
        formatted = pattern.dup
        
        # Year formatting
        formatted.gsub!('YYYY', @year.to_s)
        formatted.gsub!('YY', (@year % 100).to_s.rjust(2, '0'))
        
        # Month formatting
        formatted.gsub!('MMMM', persian_month_name)
        formatted.gsub!('MMM', persian_month_name_short)
        formatted.gsub!('MM', @month.to_s.rjust(2, '0'))
        formatted.gsub!('M', @month.to_s)
        
        # Day formatting
        formatted.gsub!('DD', @day.to_s.rjust(2, '0'))
        formatted.gsub!('D', @day.to_s)
        
        # Day of week formatting
        formatted.gsub!('dddd', persian_day_name)
        formatted.gsub!('ddd', persian_day_name_short)
        
        # Convert to Persian numerals if enabled
        if Redmine::PersianCalendar.use_persian_numerals
          Redmine::PersianCalendar.to_persian_numerals(formatted)
        else
          formatted
        end
      end
      
      # Get Persian month name
      # @return [String] Persian month name
      def persian_month_name
        Redmine::PersianCalendar.persian_month_name(@month)
      end
      
      # Get short Persian month name (first 3 characters)
      # @return [String] Short Persian month name
      def persian_month_name_short
        persian_month_name&.slice(0, 3)
      end
      
      # Get Persian day name
      # @return [String] Persian day name
      def persian_day_name
        gregorian_date = to_gregorian
        day_of_week = gregorian_date.wday # 0=Sunday, 1=Monday, etc.
        Redmine::PersianCalendar.persian_day_name(day_of_week)
      end
      
      # Get short Persian day name (first 3 characters)
      # @return [String] Short Persian day name
      def persian_day_name_short
        persian_day_name&.slice(0, 3)
      end
      
      # Check if this is a leap year
      # @return [Boolean] true if leap year
      def leap_year?
        DateConverter.persian_leap_year?(@year)
      end
      
      # Get number of days in current month
      # @return [Integer] number of days
      def days_in_month
        DateConverter.days_in_persian_month(@year, @month)
      end
      
      # Add days to Persian date
      # @param days [Integer] number of days to add
      # @return [PersianDate] new Persian date
      def +(days)
        gregorian_date = to_gregorian + days
        self.class.from_gregorian(gregorian_date)
      end
      
      # Subtract days from Persian date
      # @param days [Integer] number of days to subtract
      # @return [PersianDate] new Persian date
      def -(days)
        gregorian_date = to_gregorian - days
        self.class.from_gregorian(gregorian_date)
      end
      
      # Compare Persian dates
      # @param other [PersianDate] other Persian date
      # @return [Integer] -1, 0, or 1
      def <=>(other)
        return nil unless other.is_a?(PersianDate)
        
        [@year, @month, @day] <=> [other.year, other.month, other.day]
      end
      
      # Check equality
      # @param other [PersianDate] other Persian date
      # @return [Boolean] true if equal
      def ==(other)
        return false unless other.is_a?(PersianDate)
        
        @year == other.year && @month == other.month && @day == other.day
      end
      
      # String representation
      # @return [String] Persian date string
      def to_s
        format('YYYY/MM/DD')
      end
      
      # Hash representation
      # @return [Hash] Persian date components
      def to_h
        { year: @year, month: @month, day: @day }
      end
      
      # JSON representation
      # @return [String] JSON string
      def to_json(*args)
        to_h.to_json(*args)
      end
      
      # Beginning of month
      # @return [PersianDate] first day of month
      def beginning_of_month
        self.class.new(@year, @month, 1)
      end
      
      # End of month
      # @return [PersianDate] last day of month
      def end_of_month
        self.class.new(@year, @month, days_in_month)
      end
      
      # Beginning of year
      # @return [PersianDate] first day of year
      def beginning_of_year
        self.class.new(@year, 1, 1)
      end
      
      # End of year
      # @return [PersianDate] last day of year
      def end_of_year
        last_month_days = leap_year? ? 30 : 29
        self.class.new(@year, 12, last_month_days)
      end
      
      # Next month
      # @return [PersianDate] same day in next month
      def next_month
        if @month == 12
          next_year = @year + 1
          next_month_num = 1
        else
          next_year = @year
          next_month_num = @month + 1
        end
        
        # Handle day overflow (e.g., 31st of month with only 30 days)
        max_days = DateConverter.days_in_persian_month(next_year, next_month_num)
        next_day = [@day, max_days].min
        
        self.class.new(next_year, next_month_num, next_day)
      end
      
      # Previous month
      # @return [PersianDate] same day in previous month
      def prev_month
        if @month == 1
          prev_year = @year - 1
          prev_month_num = 12
        else
          prev_year = @year
          prev_month_num = @month - 1
        end
        
        # Handle day overflow
        max_days = DateConverter.days_in_persian_month(prev_year, prev_month_num)
        prev_day = [@day, max_days].min
        
        self.class.new(prev_year, prev_month_num, prev_day)
      end
      
      # Include Comparable module for comparison operators
      include Comparable
    end
  end
end