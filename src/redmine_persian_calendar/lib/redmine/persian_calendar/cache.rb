# frozen_string_literal: true

module Redmine
  module PersianCalendar
    # Cache management for Persian calendar operations
    class Cache
      class << self
        # Get cached value
        def get(key)
          return nil unless Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
          Rails.cache.read(cache_key(key))
        end
        
        # Set cached value
        def set(key, value, expires_in: nil)
          return false unless Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
          
          expires_in ||= 1.hour
          Rails.cache.write(cache_key(key), value, expires_in: expires_in)
        end
        
        # Delete cached value
        def delete(key)
          return false unless Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
          Rails.cache.delete(cache_key(key))
        end
        
        # Clear all Persian calendar cache
        def clear_all
          return false unless Setting.plugin_redmine_persian_calendar["cache_enabled"] == "1"
          
          # This is a simple implementation - in production you might want
          # to use cache namespacing for better performance
          Rails.cache.clear
        end
        
        private
        
        def cache_key(key)
          "persian_calendar:#{key}"
        end
      end
    end
  end
end