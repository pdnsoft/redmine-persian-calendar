# frozen_string_literal: true

require 'fileutils'

plugin_dir = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(plugin_dir, 'lib') unless $LOAD_PATH.include?(File.join(plugin_dir, 'lib'))

require 'redmine_persian_calendar/hooks'

# Best-effort copy of assets into public/plugin_assets.
# The authoritative copy is done by install.sh (as root); this fallback must never
# crash boot when www-data lacks write access to the Redmine tree.
begin
  assets_src = File.join(plugin_dir, 'app', 'assets')
  assets_dst = File.join(Rails.root, 'public', 'plugin_assets', 'redmine_persian_calendar')

  if File.directory?(assets_src) && File.directory?(File.dirname(assets_dst))
    FileUtils.mkdir_p(assets_dst)
    Dir.glob(File.join(assets_src, 'stylesheets', '*')).each { |f| FileUtils.cp(f, assets_dst) if File.file?(f) }
    Dir.glob(File.join(assets_src, 'javascripts', '*')).each { |f| FileUtils.cp(f, assets_dst) if File.file?(f) }
    fonts_dst = File.join(assets_dst, 'fonts')
    FileUtils.mkdir_p(fonts_dst)
    Dir.glob(File.join(assets_src, 'fonts', '*')).each { |f| FileUtils.cp(f, fonts_dst) if File.file?(f) }

    custom_src = File.join(plugin_dir, 'custom_styles')
    if File.directory?(custom_src)
      Dir.glob(File.join(custom_src, '*')).each { |f| FileUtils.cp(f, assets_dst) if File.file?(f) }
    end
  end
rescue => e
  Rails.logger.warn("[PersianCalendar] asset copy skipped: #{e.message}") if defined?(Rails) && Rails.logger
end

# NOTE: fa.yml is NOT copied into config/locales. Redmine 7 auto-loads any
# <plugin>/config/locales/*.yml from the plugin directory (see Redmine::Plugin.register),
# so the plugin's localized fa.yml overrides the core one without touching core files.

# Redmine names themes after their directory (persian -> "Persian").
module RedminePersianCalendar
  module ThemeNameOverride
    def name
      id == 'persian' ? 'PDN Persian' : super
    end
  end
end

Redmine::Plugin.register :redmine_persian_calendar do
  name 'تقویم شمسی ردماین'
  author 'PDNSoft Dev Team'
  description 'پشتیبانی از تقویم جلالی و انتخابگر تاریخ شمسی برای ردماین'
  version '1.0.0'

  settings default: {
    'enabled' => '1',
    'cache_enabled' => '1'
  }, partial: 'redmine_persian_calendar/settings'
end

Rails.application.config.after_initialize do
  # --- Theme display name ----------------------------------------------------
  begin
    Redmine::Themes::Theme.prepend(RedminePersianCalendar::ThemeNameOverride)
  rescue => error
    Rails.logger.error("[PersianCalendar] theme name override failed: #{error.message}")
  end

  # --- Persian calendar core -------------------------------------------------
  # Redmine adds the plugin lib/ to the Rails autoloader, so referencing the
  # constant loads lib/redmine/persian_calendar.rb exactly once (no manual load,
  # which would redefine the module constants and emit "already initialized" warnings).
  begin
    Redmine::PersianCalendar
  rescue => error
    Rails.logger.error("[PersianCalendar] core load failed: #{error.message}")
  end

  # --- Model patches ---------------------------------------------------------
  begin
    Dir.glob(File.join(plugin_dir, 'patches', '*.rb')).sort.each { |f| load f }
  rescue => error
    Rails.logger.error("[PersianCalendar] model patches failed: #{error.message}")
  end

  # --- Helper module ---------------------------------------------------------
  begin
    ApplicationHelper.include PersianCalendarHelper
  rescue => error
    Rails.logger.error("[PersianCalendar] helper include failed: #{error.message}")
  end

  # --- Date/time display overrides ------------------------------------------
  if defined?(Redmine::PersianCalendar) && !ApplicationHelper.instance_methods(false).include?(:_pc_orig_format_date)
    begin
      ApplicationHelper.class_eval do
        alias_method :_pc_orig_format_date, :format_date
        def format_date(date)
          return _pc_orig_format_date(date) unless date && Redmine::PersianCalendar.enabled?
          begin
            r = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(date)
            "#{r[:year]}/#{r[:month].to_s.rjust(2, '0')}/#{r[:day].to_s.rjust(2, '0')}"
          rescue
            _pc_orig_format_date(date)
          end
        end

        alias_method :_pc_orig_format_time, :format_time
        def format_time(time, include_date = true, user = nil)
          return _pc_orig_format_time(time, include_date, user) unless time && Redmine::PersianCalendar.enabled?
          begin
            if include_date
              r = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(time.to_date)
              "#{r[:year]}/#{r[:month].to_s.rjust(2, '0')}/#{r[:day].to_s.rjust(2, '0')} #{time.strftime('%H:%M')}"
            else
              time.strftime('%H:%M')
            end
          rescue
            _pc_orig_format_time(time, include_date, user)
          end
        end
      end
    rescue => error
      Rails.logger.error("[PersianCalendar] ApplicationHelper override failed: #{error.message}")
    end
  end

  if defined?(Redmine::PersianCalendar) && defined?(Redmine::I18n) && !Redmine::I18n.instance_methods(false).include?(:_pc_orig_format_date)
    begin
      Redmine::I18n.module_eval do
        alias_method :_pc_orig_format_date, :format_date
        def format_date(date)
          return _pc_orig_format_date(date) unless date && Redmine::PersianCalendar.enabled?
          begin
            r = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(date)
            "#{r[:year]}/#{r[:month].to_s.rjust(2, '0')}/#{r[:day].to_s.rjust(2, '0')}"
          rescue
            _pc_orig_format_date(date)
          end
        end
      end
    rescue => error
      Rails.logger.error("[PersianCalendar] Redmine::I18n override failed: #{error.message}")
    end
  end

  if defined?(Redmine::PersianCalendar) && !Date.instance_methods(false).include?(:_pc_orig_to_formatted_s)
    begin
      Date.class_eval do
        alias_method :_pc_orig_to_formatted_s, :to_formatted_s
        def to_formatted_s(format = :default)
          if Redmine::PersianCalendar.enabled? && format == :default
            begin
              r = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(self)
              return "#{r[:year]}/#{r[:month].to_s.rjust(2, '0')}/#{r[:day].to_s.rjust(2, '0')}"
            rescue
            end
          end
          _pc_orig_to_formatted_s(format)
        end
      end
    rescue => error
      Rails.logger.error("[PersianCalendar] Date override failed: #{error.message}")
    end
  end

  if defined?(Redmine::PersianCalendar) && !Time.instance_methods(false).include?(:_pc_orig_to_formatted_s)
    begin
      Time.class_eval do
        alias_method :_pc_orig_to_formatted_s, :to_formatted_s
        def to_formatted_s(format = :default)
          if Redmine::PersianCalendar.enabled? && format == :default
            begin
              r = Redmine::PersianCalendar::DateConverter.gregorian_to_jalali(self.to_date)
              "#{r[:year]}/#{r[:month].to_s.rjust(2, '0')}/#{r[:day].to_s.rjust(2, '0')} #{strftime('%H:%M')}"
            rescue
            end
          end
          _pc_orig_to_formatted_s(format)
        end
      end
    rescue => error
      Rails.logger.error("[PersianCalendar] Time override failed: #{error.message}")
    end
  end
end
