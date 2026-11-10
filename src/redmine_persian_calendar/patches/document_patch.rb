# frozen_string_literal: true
module RedminePersianCalendar
  module DocumentPatch
    def self.included(base)
      base.class_eval do
        include PersianDateSupport unless included_modules.include?(PersianDateSupport)
      end
    end
  end
end
Document.include RedminePersianCalendar::DocumentPatch unless Document.included_modules.include?(RedminePersianCalendar::DocumentPatch)
