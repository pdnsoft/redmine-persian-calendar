# frozen_string_literal: true

# Persian Calendar module for Redmine
# Provides Persian/Jalali calendar functionality

module Redmine
  module PersianCalendar
    # Persian calendar error classes
    class Error < StandardError; end
    class InvalidDateError < Error; end
    class ConversionError < Error; end
    class CacheError < Error; end
    
    # Load Persian calendar components
    require_relative "persian_calendar/date_converter"
    require_relative "persian_calendar/persian_date"
    require_relative "persian_calendar/cache"
    require_relative "persian_calendar/validator"
    
    # Persian calendar configuration
    mattr_accessor :enabled, default: true
    mattr_accessor :cache_enabled, default: true
    mattr_accessor :use_persian_numerals, default: true
    mattr_accessor :leap_year_mode, default: 'algorithmic'
    
    # Persian month names
    PERSIAN_MONTH_NAMES = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
    ].freeze
    
    # Persian day names
    PERSIAN_DAY_NAMES = [
      'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه'
    ].freeze
    
    # Persian numerals mapping
    PERSIAN_NUMERALS = {
      '0' => '۰', '1' => '۱', '2' => '۲', '3' => '۳', '4' => '۴',
      '5' => '۵', '6' => '۶', '7' => '۷', '8' => '۸', '9' => '۹'
    }.freeze
    
    class << self
      # Check if Persian calendar is enabled
      def enabled?
        enabled && Setting.plugin_redmine_persian_calendar["enabled"] == "1"
      end
      
      # Convert Western numerals to Persian numerals
      def to_persian_numerals(text)
        return text unless use_persian_numerals
        
        text.to_s.gsub(/[0-9]/) { |digit| PERSIAN_NUMERALS[digit] }
      end
      
      # Convert Persian numerals to Western numerals
      def to_western_numerals(text)
        text.to_s.gsub(/[۰-۹]/) { |digit| PERSIAN_NUMERALS.key(digit) }
      end
      
      # Get Persian month name by index (1-12)
      def persian_month_name(month_index)
        PERSIAN_MONTH_NAMES[month_index - 1] if month_index.between?(1, 12)
      end
      
      # Get Persian day name by index (0-6, Sunday=0)
      def persian_day_name(day_index)
        PERSIAN_DAY_NAMES[day_index] if day_index.between?(0, 6)
      end
    end
  end
end