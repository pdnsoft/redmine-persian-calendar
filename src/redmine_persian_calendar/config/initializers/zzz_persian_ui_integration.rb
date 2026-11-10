# Persian Calendar UI Integration - Override Redmine's date display
Rails.application.config.after_initialize do
  begin
    # Override ApplicationHelper date methods
    ApplicationHelper.module_eval do
      alias_method :original_format_date, :format_date
      alias_method :original_format_time, :format_time
      
      def format_date(date)
        return original_format_date(date) unless date && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          original_format_date(date)
        end
      end
      
      def format_time(time, include_date = true)
        return original_format_time(time, include_date) unless time && Redmine::PersianCalendar.enabled?
        
        begin
          if include_date
            # Convert to user's local timezone first
            local_time = User.current.convert_time_to_user_timezone(time)
            persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(local_time.to_date)
            persian_date = "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
            time_part = local_time.strftime('%H:%M')
            "#{persian_date} #{time_part}"
          else
            local_time = User.current.convert_time_to_user_timezone(time)
            local_time.strftime('%H:%M')
          end
        rescue
          original_format_time(time, include_date)
        end
      end
    end
    
    # Override I18n module for global date formatting
    Redmine::I18n.module_eval do
      alias_method :original_format_date, :format_date
      alias_method :original_format_time, :format_time
      
      def format_date(date)
        return original_format_date(date) unless date && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          original_format_date(date)
        end
      end
      
      def format_time(time, include_date = true, user = nil)
        return original_format_time(time, include_date, user) unless time && Redmine::PersianCalendar.enabled?
        
        begin
          if include_date
            persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(time.to_date)
            persian_date = "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
            
            # Handle user timezone conversion
            local_time = user ? user.convert_time_to_user_timezone(time) : time
            time_part = local_time.strftime('%H:%M')
            "#{persian_date} #{time_part}"
          else
            local_time = user ? user.convert_time_to_user_timezone(time) : time
            local_time.strftime('%H:%M')
          end
        rescue
          original_format_time(time, include_date, user)
        end
      end
    end
    
    # Override Issue model date display
    Issue.class_eval do
      def created_on_persian
        return created_on unless Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(created_on.to_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          created_on.strftime('%Y/%m/%d')
        end
      end
      
      def updated_on_persian
        return updated_on unless Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(updated_on.to_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          updated_on.strftime('%Y/%m/%d')
        end
      end
      
      def start_date_persian
        return start_date unless start_date && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(start_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          start_date.strftime('%Y/%m/%d')
        end
      end
      
      def due_date_persian
        return due_date unless due_date && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(due_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          due_date.strftime('%Y/%m/%d')
        end
      end
    end
    
    # Override TimeEntry model for consistent Persian dates
    TimeEntry.class_eval do
      def spent_on_persian
        return spent_on unless spent_on && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(spent_on)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          spent_on.strftime('%Y/%m/%d')
        end
      end
      
      def created_on_persian
        return created_on unless created_on && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(created_on.to_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          created_on.strftime('%Y/%m/%d')
        end
      end
    end
    
    # Override WikiPage model for Persian dates
    WikiPage.class_eval do
      def created_on_persian
        return created_on unless created_on && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(created_on.to_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          created_on.strftime('%Y/%m/%d')
        end
      end
      
      def updated_on_persian
        return updated_on unless updated_on && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(updated_on.to_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          updated_on.strftime('%Y/%m/%d')
        end
      end
    end
    
    # Override Version model for Persian dates
    Version.class_eval do
      def effective_date_persian
        return effective_date unless effective_date && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(effective_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          effective_date.strftime('%Y/%m/%d')
        end
      end
      
      def created_on_persian
        return created_on unless created_on && Redmine::PersianCalendar.enabled?
        
        begin
          persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(created_on.to_date)
          "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
        rescue
          created_on.strftime('%Y/%m/%d')
        end
      end
    end
    
    # Override Date class globally for Persian display
    Date.class_eval do
      alias_method :original_to_formatted_s, :to_formatted_s
      
      def to_formatted_s(format = :default)
        if Redmine::PersianCalendar.enabled? && format == :default
          begin
            persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(self)
            return "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
          rescue
            # Fall back to original if conversion fails
          end
        end
        original_to_formatted_s(format)
      end
    end
    
    # Override Time class for Persian display
    Time.class_eval do
      alias_method :original_to_formatted_s, :to_formatted_s
      
      def to_formatted_s(format = :default)
        if Redmine::PersianCalendar.enabled? && format == :default
          begin
            # Convert to user's local timezone first
            local_time = User.current ? User.current.convert_time_to_user_timezone(self) : self
            persian_result = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(local_time.to_date)
            persian_date = "#{persian_result[:year]}/#{persian_result[:month].to_s.rjust(2, '0')}/#{persian_result[:day].to_s.rjust(2, '0')}"
            time_part = local_time.strftime('%H:%M')
            return "#{persian_date} #{time_part}"
          rescue
            # Fall back to original if conversion fails
          end
        end
        original_to_formatted_s(format)
      end
    end
  rescue => error
    Rails.logger.error("[PersianCalendar] UI integration failed: #{error.message}")
  end
end
