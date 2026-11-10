# frozen_string_literal: true
module RedminePersianCalendar
  module TimeEntryPatch
    def self.included(base)
      base.class_eval do
        include PersianDateSupport unless included_modules.include?(PersianDateSupport)
      end
    end
  end
end
TimeEntry.include RedminePersianCalendar::TimeEntryPatch unless TimeEntry.included_modules.include?(RedminePersianCalendar::TimeEntryPatch)
