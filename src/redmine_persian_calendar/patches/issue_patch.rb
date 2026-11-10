# frozen_string_literal: true
module RedminePersianCalendar
  module IssuePatch
    def self.included(base)
      base.class_eval do
        include PersianDateSupport unless included_modules.include?(PersianDateSupport)
      end
    end
  end
end
Issue.include RedminePersianCalendar::IssuePatch unless Issue.included_modules.include?(RedminePersianCalendar::IssuePatch)
