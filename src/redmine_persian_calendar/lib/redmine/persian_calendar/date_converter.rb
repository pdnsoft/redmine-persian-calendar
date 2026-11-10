# frozen_string_literal: true

module Redmine
  module PersianCalendar
    # Persian calendar date conversion algorithms
    # Uses JDF.SCR.IR proven algorithm - most accurate Persian calendar converter
    class DateConverter
      class << self
        # Convert Gregorian date to Persian/Jalali date
        def gregorian_to_jalali(date)
          return nil if date.nil?
          
          # Convert input to Date object
          gregorian_date = case date
                          when Date
                            date
                          when Time, DateTime
                            date.to_date
                          when String
                            Date.parse(date)
                          else
                            raise InvalidDateError, "Invalid date format: #{date}"
                          end
          
          # Use cached result if available
          cache_key = "g2j_#{gregorian_date.strftime('%Y%m%d')}"
          if Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
            cached_result = Rails.cache.read(cache_key)
            return cached_result if cached_result
          end
          
          # Perform conversion using JDF algorithm
          gy = gregorian_date.year
          gm = gregorian_date.month
          gd = gregorian_date.day
          
          jy, jm, jd = gregorian_to_jalali_jdf(gy, gm, gd)
          result = { year: jy, month: jm, day: jd }
          
          # Cache the result
          if Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
            Rails.cache.write(cache_key, result, expires_in: 1.hour)
          end
          
          result
        rescue StandardError => e
          raise ConversionError, "Failed to convert Gregorian to Jalali: #{e.message}"
        end
        
        # Convert Persian/Jalali date to Gregorian date
        def jalali_to_gregorian(persian_date)
          return nil if persian_date.nil?
          
          # Parse Persian date components
          year, month, day = parse_persian_date(persian_date)
          
          # Validate Persian date
          raise InvalidDateError, "Invalid Persian date" unless valid_persian_date?(year, month, day)
          
          # Use cached result if available
          cache_key = "j2g_#{year}#{month.to_s.rjust(2, '0')}#{day.to_s.rjust(2, '0')}"
          if Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
            cached_result = Rails.cache.read(cache_key)
            return cached_result if cached_result
          end
          
          # Perform conversion using JDF algorithm
          gy, gm, gd = jalali_to_gregorian_jdf(year, month, day)
          result = Date.new(gy, gm, gd)
          
          # Cache the result
          if Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
            Rails.cache.write(cache_key, result, expires_in: 1.hour)
          end
          
          result
        rescue StandardError => e
          raise ConversionError, "Failed to convert Jalali to Gregorian: #{e.message}"
        end
        
        # Validate Persian date components
        def valid_persian_date?(year, month, day)
          return false unless year.is_a?(Integer) && month.is_a?(Integer) && day.is_a?(Integer)
          return false unless year.between?(1300, 1500) # Reasonable range
          return false unless month.between?(1, 12)
          return false unless day.between?(1, days_in_persian_month(year, month))
          
          true
        end
        
        # Get number of days in Persian month
        def days_in_persian_month(year, month)
          return 0 unless month.between?(1, 12)
          
          if month <= 6
            31
          elsif month <= 11
            30
          else
            persian_leap_year?(year) ? 30 : 29
          end
        end
        
        # Check if Persian year is leap year
        def persian_leap_year?(year)
          # 33-year cycle algorithm
          cycle = year % 33
          [1, 5, 9, 13, 17, 22, 26, 30].include?(cycle)
        end
        
        private
        
        # Parse Persian date from various formats
        def parse_persian_date(persian_date)
          case persian_date
          when Hash
            [persian_date[:year], persian_date[:month], persian_date[:day]]
          when String
            parts = persian_date.split(/[\/\-]/)
            raise InvalidDateError, "Invalid Persian date format" unless parts.length == 3
            parts.map(&:to_i)
          else
            raise InvalidDateError, "Invalid Persian date format"
          end
        end
        
        # JDF.SCR.IR Gregorian to Jalali conversion algorithm
        # Author: JDF.SCR.IR - Most accurate Persian calendar converter
        # @param [Integer] gy Gregorian year
        # @param [Integer] gm Gregorian month
        # @param [Integer] gd Gregorian day
        # @return [Array Integer] [jy,jm,jd]
        def gregorian_to_jalali_jdf(gy, gm, gd)
          g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
          
          if gm > 2
            gy2 = gy + 1
          else
            gy2 = gy
          end
          
          days = 355666 + (365 * gy) + ((gy2 + 3) / 4).to_i - ((gy2 + 99) / 100).to_i + ((gy2 + 399) / 400).to_i + gd + g_d_m[gm - 1]
          
          jy = -1595 + (33 * (days / 12053).to_i)
          days %= 12053
          
          jy += 4 * (days / 1461).to_i
          days %= 1461
          
          if days > 365
            jy += ((days - 1) / 365).to_i
            days = (days - 1) % 365
          end
          
          if days < 186
            jm = 1 + (days / 31).to_i
            jd = 1 + (days % 31)
          else
            jm = 7 + ((days - 186) / 30).to_i
            jd = 1 + ((days - 186) % 30)
          end
          
          [jy, jm, jd]
        end
        
        # JDF.SCR.IR Jalali to Gregorian conversion algorithm
        # @param [Integer] jy Jalali year
        # @param [Integer] jm Jalali month
        # @param [Integer] jd Jalali day
        # @return [Array Integer] [gy,gm,gd]
        def jalali_to_gregorian_jdf(jy, jm, jd)
          jy += 1595
          days = -355668 + (365 * jy) + ((jy / 33).to_i * 8) + (((jy % 33) + 3) / 4).to_i + jd
          
          if jm < 7
            days += (jm - 1) * 31
          else
            days += ((jm - 7) * 30) + 186
          end
          
          gy = 400 * (days / 146097).to_i
          days %= 146097
          
          if days > 36524
            days -= 1
            gy += 100 * (days / 36524).to_i
            days %= 36524
            days += 1 if days >= 365
          end
          
          gy += 4 * (days / 1461).to_i
          days %= 1461
          
          if days > 365
            gy += ((days - 1) / 365).to_i
            days = (days - 1) % 365
          end
          
          gd = days + 1
          
          # Check for leap year
          is_leap = (gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0)
          sal_a = [0, 31, (is_leap ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
          
          gm = 0
          while gm < 13 && gd > sal_a[gm]
            gd -= sal_a[gm]
            gm += 1
          end
          
          [gy, gm, gd]
        end
      end
    end
  end
end