# frozen_string_literal: true

module RedminePersianCalendar; end

# Jalali date picker assets. Persian styling and fonts live in the "persian"
# theme (themes/persian), so selecting another theme keeps Redmine stock.
class RedminePersianCalendar::Hooks < Redmine::Hook::ViewListener
  ASSET_BASE = '/plugin_assets/redmine_persian_calendar'

  def view_layouts_base_html_head(context = {})
    return '' unless Setting.plugin_redmine_persian_calendar['enabled'] == '1'

    tags = ''.html_safe
    tags << "<link rel=\"stylesheet\" href=\"#{ASSET_BASE}/jalali_date_picker.css\" />".html_safe
    tags << "<script src=\"#{ASSET_BASE}/persian_date_converter.js\"></script>".html_safe
    tags << "<script src=\"#{ASSET_BASE}/jalali_date_picker.js\"></script>".html_safe
    tags
  end

  def view_layouts_base_body_bottom(context = {})
    return '' unless Setting.plugin_redmine_persian_calendar['enabled'] == '1'

    "<script src=\"#{ASSET_BASE}/jalali_filter_integration.js\"></script>".html_safe
  end
end
