# frozen_string_literal: true
module RedminePersianCalendar
  module VersionPatch
    def self.included(base)
      base.class_eval do
        include PersianDateSupport unless included_modules.include?(PersianDateSupport)
      end
    end
  end
end
Version.include RedminePersianCalendar::VersionPatch unless Version.included_modules.include?(RedminePersianCalendar::VersionPatch)
