# frozen_string_literal: true
module RedminePersianCalendar
  module AnonymousUserPatch
    def self.included(base)
      base.class_eval do
        def persian_calendar_enabled?
          Redmine::PersianCalendar.enabled?
        end
      end
    end
  end
end
AnonymousUser.include RedminePersianCalendar::AnonymousUserPatch unless AnonymousUser.included_modules.include?(RedminePersianCalendar::AnonymousUserPatch)
