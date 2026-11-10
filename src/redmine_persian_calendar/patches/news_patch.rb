# frozen_string_literal: true
module RedminePersianCalendar
  module NewsPatch
    def self.included(base)
      base.class_eval do
        include PersianDateSupport unless included_modules.include?(PersianDateSupport)
      end
    end
  end
end
News.include RedminePersianCalendar::NewsPatch unless News.included_modules.include?(RedminePersianCalendar::NewsPatch)
