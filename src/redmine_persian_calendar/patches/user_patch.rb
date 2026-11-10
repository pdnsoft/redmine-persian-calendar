# frozen_string_literal: true
module RedminePersianCalendar
  module UserPatch
    def self.included(base)
      base.class_eval do
        def persian_calendar_enabled?
          return false unless Redmine::PersianCalendar.enabled?
          pref_value = self.pref[:persian_calendar_enabled]
          pref_value.nil? ? true : pref_value
        end
        def persian_calendar_enabled=(value)
          self.pref[:persian_calendar_enabled] = ActiveRecord::Type::Boolean.new.deserialize(value)
        end
      end
    end
  end
end
User.include RedminePersianCalendar::UserPatch unless User.included_modules.include?(RedminePersianCalendar::UserPatch)
