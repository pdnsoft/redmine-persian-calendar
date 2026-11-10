#!/bin/bash
set -o pipefail

# ============================================================
#   PDNSoft Jalali Calendar for Redmine — Installer
#   Version 1.0.0
# ============================================================

detect_redmine_dir() {
    local candidate
    for candidate in "${REDMINE_DIR:-}" /opt/redmine /var/www/redmine /srv/redmine /usr/share/redmine /var/www/html/redmine; do
        [ -n "$candidate" ] || continue
        if [ -f "$candidate/Gemfile" ] && [ -d "$candidate/app/models" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    candidate="$(find /opt /var/www /srv /usr/share -maxdepth 3 -type f -name Gemfile -path '*redmine*' 2>/dev/null | head -n 1)"
    if [ -n "$candidate" ]; then
        dirname "$candidate"
        return 0
    fi
    printf '%s' "${REDMINE_DIR:-/opt/redmine}"
}

REDMINE_DIR="$(detect_redmine_dir)"
PLUGIN_NAME="redmine_persian_calendar"
PLUGIN_DIR="$REDMINE_DIR/plugins/$PLUGIN_NAME"
ASSETS_DIR="$REDMINE_DIR/public/plugin_assets/$PLUGIN_NAME"
THEME_NAME="persian"
THEME_DIR="$REDMINE_DIR/themes/$THEME_NAME"
# Redmine 7 compiles CSS through Propshaft; the plugin ships its overrides as
# static files under public/plugin_assets, so nothing is written into core.
PLUGIN_ARCHIVE="${PLUGIN_ARCHIVE:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo -e "${BOLD}Usage:${NC} install.sh [command]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  (none)          interactive menu"
    echo "  install         install everything (plugin + picker + theme + language)"
    echo "  install-plugin  install plugin only (picker; theme and language untouched)"
    echo "  uninstall       remove plugin, assets and theme"
    echo "  status          show plugin, theme and Apache status"
    echo "  help, -h, --help  show this help"
    echo ""
    echo -e "${BOLD}Environment variables:${NC}"
    echo "  REDMINE_DIR     Redmine root directory (default: auto-detect)"
    echo "  PLUGIN_ARCHIVE  path to redmine_persian_calendar.tar.gz (default: auto-detect)"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./install.sh"
    echo "  ./install.sh install"
    echo "  REDMINE_DIR=/var/www/redmine ./install.sh install-plugin"
    echo "  PLUGIN_ARCHIVE=/tmp/redmine_persian_calendar.tar.gz ./install.sh install"
}

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ================================================"
    echo "    PDNSoft Jalali Calendar for Redmine"
    echo "    تقویم جلالی برای ردماین"
    echo "    Version 1.0.0"
    echo "  ================================================"
    echo -e "${NC}"
}

show_menu() {
    echo -e "  ${BOLD}Choose an option:${NC}"
    echo ""
    echo -e "    ${CYAN}1)${NC} Install everything (plugin + picker + theme + language)"
    echo -e "    ${CYAN}2)${NC} Install plugin only (picker, no theme/language changes)"
    echo -e "    ${CYAN}3)${NC} Uninstall Persian Calendar"
    echo -e "    ${CYAN}4)${NC} Check Status"
    echo -e "    ${CYAN}5)${NC} Exit"
    echo ""
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}[ERROR] Run as root${NC}"
        exit 1
    fi
}

check_redmine() {
    if [ ! -f "$REDMINE_DIR/Gemfile" ]; then
        echo -e "${RED}[ERROR] Redmine not found at $REDMINE_DIR${NC}"
        exit 1
    fi
}

find_plugin_tar() {
    local tar_path=""

    for location in \
        "$PLUGIN_ARCHIVE" \
        "$SCRIPT_DIR/$PLUGIN_NAME.tar.gz" \
        "$PWD/$PLUGIN_NAME.tar.gz" \
        "/tmp/$PLUGIN_NAME.tar.gz"; do
        [ -z "$location" ] && continue
        if [ -f "$location" ]; then
            tar_path="$location"
            break
        fi
    done

    printf '%s' "$tar_path"
}

validate_styles_source() {
    local plugin_source_dir="$1"
    local custom_styles_dir="$plugin_source_dir/custom_styles"
    local hook_file="$plugin_source_dir/lib/redmine_persian_calendar/hooks.rb"
    local font_css="$plugin_source_dir/app/assets/stylesheets/vazirmatn_fonts.css"
    local fonts_dir="$plugin_source_dir/app/assets/fonts"
    local font_file
    local stylesheet

    if [ ! -f "$hook_file" ] ||
       ! grep -q "jalali_date_picker.css" "$hook_file"; then
        echo -e "${RED}[ERROR] Selected package does not load the Jalali picker assets${NC}" >&2
        echo -e "${YELLOW}Checked: $hook_file${NC}" >&2
        return 1
    fi

    if [ ! -f "$font_css" ] ||
       ! grep -q "Force Vazirmatn everywhere" "$font_css" ||
       grep -q "webfonts/" "$font_css"; then
        echo -e "${RED}[ERROR] Selected package does not contain global Vazirmatn enforcement${NC}" >&2
        echo -e "${YELLOW}Checked: $font_css${NC}" >&2
        return 1
    fi

    for font_file in Thin ExtraLight Light Regular Medium SemiBold Bold ExtraBold Black; do
        if [ ! -s "$fonts_dir/Vazirmatn-FD-NL-$font_file.woff2" ]; then
            echo -e "${RED}[ERROR] Selected package is missing a Vazirmatn font file${NC}" >&2
            echo -e "${YELLOW}Checked: $fonts_dir/Vazirmatn-FD-NL-$font_file.woff2${NC}" >&2
            return 1
        fi
    done

    if [ ! -s "$custom_styles_dir/custom_overrides.css" ]; then
        echo -e "${RED}[ERROR] Selected package is missing the Redmine 7 override stylesheet${NC}" >&2
        echo -e "${YELLOW}Checked: $custom_styles_dir/custom_overrides.css${NC}" >&2
        return 1
    fi

    local theme_css="$plugin_source_dir/themes/$THEME_NAME/stylesheets/application.css"
    local theme_js="$plugin_source_dir/themes/$THEME_NAME/javascripts/theme.js"
    if [ ! -f "$theme_css" ] ||
       ! grep -q "custom_overrides.css" "$theme_css" ||
       ! grep -q "vazirmatn_fonts.css" "$theme_css" ||
       [ ! -f "$theme_js" ]; then
        echo -e "${RED}[ERROR] Selected package is missing the Persian theme${NC}" >&2
        echo -e "${YELLOW}Checked: $theme_css and $theme_js${NC}" >&2
        return 1
    fi

    if ! grep -q "tr.time-entry" "$custom_styles_dir/custom_overrides.css" ||
       ! grep -q "Center table headers and distinguish columns" "$custom_styles_dir/custom_overrides.css" ||
       ! grep -q "Time-entry columns: center date, user, activity and hours" "$custom_styles_dir/custom_overrides.css" ||
       ! grep -q "Production issue property layout" "$custom_styles_dir/custom_overrides.css" ||
       ! grep -q "div.issue.details > .avatar-with-child > .avatar-child" "$custom_styles_dir/custom_overrides.css" ||
       ! grep -q 'html\[dir="rtl"\] div.issue .avatar' "$custom_styles_dir/custom_overrides.css" ||
       grep -v 'arrow_right' "$custom_styles_dir/custom_overrides.css" |
         grep -q "/assets/.*-[0-9a-f]\{8\}\.\(png\|gif\|svg\)"; then
        echo -e "${RED}[ERROR] custom_overrides.css is missing the expected Redmine 7 rules or still references old digest assets${NC}" >&2
        echo -e "${YELLOW}Checked: $custom_styles_dir/custom_overrides.css${NC}" >&2
        return 1
    fi

    return 0
}

deploy_custom_styles() {
    local source_dir="$1"
    local plugin_source_dir="${2:-$PLUGIN_DIR}"
    local backup_dir
    local installed_custom_dir="$PLUGIN_DIR/custom_styles"
    local installed_assets_dir="$PLUGIN_DIR/app/assets/stylesheets"
    local installed_fonts_dir="$PLUGIN_DIR/app/assets/fonts"
    local installed_hooks_dir="$PLUGIN_DIR/lib/redmine_persian_calendar"

    if [ ! -d "$source_dir" ]; then
        echo -e "${RED}Styles source not found: $source_dir${NC}"
        return 1
    fi

    backup_dir="$REDMINE_DIR/.stylesheets_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir" "$ASSETS_DIR"
    if [ -d "$PLUGIN_DIR" ]; then
        mkdir -p "$installed_custom_dir" "$installed_assets_dir" "$installed_fonts_dir" "$installed_hooks_dir"
    fi

    for stylesheet in custom_overrides.css; do
        if [ ! -f "$source_dir/$stylesheet" ]; then
            echo -e "${RED}Missing stylesheet: $source_dir/$stylesheet${NC}"
            return 1
        fi
        [ -f "$ASSETS_DIR/$stylesheet" ] && cp "$ASSETS_DIR/$stylesheet" "$backup_dir/public_$stylesheet"
        cp "$source_dir/$stylesheet" "$ASSETS_DIR/$stylesheet"
        if [ -d "$PLUGIN_DIR" ] && [ "$source_dir" != "$installed_custom_dir" ]; then
            cp "$source_dir/$stylesheet" "$installed_custom_dir/$stylesheet"
        fi
    done

    if [ -f "$plugin_source_dir/app/assets/stylesheets/vazirmatn_fonts.css" ]; then
        cp "$plugin_source_dir/app/assets/stylesheets/vazirmatn_fonts.css" "$ASSETS_DIR/vazirmatn_fonts.css"
        if [ -d "$PLUGIN_DIR" ] && [ "$plugin_source_dir" != "$PLUGIN_DIR" ]; then
            cp "$plugin_source_dir/app/assets/stylesheets/vazirmatn_fonts.css" "$installed_assets_dir/vazirmatn_fonts.css"
        fi
    fi
    if [ -d "$plugin_source_dir/app/assets/fonts" ]; then
        mkdir -p "$ASSETS_DIR/fonts"
        cp "$plugin_source_dir/app/assets/fonts/"*.woff2 "$ASSETS_DIR/fonts/"
        if [ -d "$PLUGIN_DIR" ] && [ "$plugin_source_dir" != "$PLUGIN_DIR" ]; then
            cp "$plugin_source_dir/app/assets/fonts/"*.woff2 "$installed_fonts_dir/"
        fi
    fi
    if [ -f "$plugin_source_dir/lib/redmine_persian_calendar/hooks.rb" ] &&
       [ -d "$PLUGIN_DIR" ] &&
       [ "$plugin_source_dir" != "$PLUGIN_DIR" ]; then
        cp "$plugin_source_dir/lib/redmine_persian_calendar/hooks.rb" "$installed_hooks_dir/hooks.rb"
    fi

    chown -R www-data:www-data "$ASSETS_DIR"
    [ -d "$PLUGIN_DIR" ] && chown -R www-data:www-data "$installed_custom_dir" "$installed_assets_dir" "$installed_fonts_dir" "$installed_hooks_dir"
    chmod -R 755 "$ASSETS_DIR"

    echo -e "${GREEN}[OK] Redmine 7 overrides copied to plugin and public assets${NC}"
    echo -e "${GREEN}[OK] Backup: $backup_dir${NC}"
}

sync_public_plugin_styles() {
    local source_dir="${1:-$PLUGIN_DIR/custom_styles}"
    local plugin_source_dir="${2:-$PLUGIN_DIR}"
    local installed_custom_dir="$PLUGIN_DIR/custom_styles"
    local installed_assets_dir="$PLUGIN_DIR/app/assets/stylesheets"
    local installed_fonts_dir="$PLUGIN_DIR/app/assets/fonts"
    local source_font_css="$plugin_source_dir/app/assets/stylesheets/vazirmatn_fonts.css"
    local source_fonts_dir="$plugin_source_dir/app/assets/fonts"
    local stylesheet

    mkdir -p "$installed_custom_dir" "$installed_assets_dir" "$installed_fonts_dir"
    mkdir -p "$ASSETS_DIR" "$ASSETS_DIR/fonts"

    for stylesheet in custom_overrides.css; do
        if [ ! -f "$source_dir/$stylesheet" ]; then
            echo -e "${RED}[ERROR] Source plugin stylesheet is missing: $source_dir/$stylesheet${NC}"
            return 1
        fi
        if [ "$source_dir/$stylesheet" != "$installed_custom_dir/$stylesheet" ]; then
            cp "$source_dir/$stylesheet" "$installed_custom_dir/$stylesheet"
        fi
        cp "$source_dir/$stylesheet" "$ASSETS_DIR/$stylesheet"
    done

    if [ ! -f "$source_font_css" ]; then
        echo -e "${RED}[ERROR] Source Vazirmatn stylesheet is missing${NC}"
        echo -e "${YELLOW}Checked: $source_font_css${NC}"
        return 1
    fi
    if [ "$source_font_css" != "$installed_assets_dir/vazirmatn_fonts.css" ]; then
        cp "$source_font_css" "$installed_assets_dir/vazirmatn_fonts.css"
    fi
    cp "$source_font_css" "$ASSETS_DIR/vazirmatn_fonts.css"

    if compgen -G "$source_fonts_dir/*.woff2" >/dev/null; then
        if [ "$source_fonts_dir" != "$installed_fonts_dir" ]; then
            cp "$source_fonts_dir/"*.woff2 "$installed_fonts_dir/"
        fi
        cp "$source_fonts_dir/"*.woff2 "$ASSETS_DIR/fonts/"
    fi

    # Hooks reference these by flat /plugin_assets URL, so they must exist as static files
    for asset in "$plugin_source_dir/app/assets/stylesheets/"*.css \
                 "$plugin_source_dir/app/assets/javascripts/"*.js; do
        [ -f "$asset" ] || continue
        cp "$asset" "$ASSETS_DIR/"
    done

    chown -R www-data:www-data "$installed_custom_dir" "$installed_assets_dir" "$installed_fonts_dir" "$ASSETS_DIR"
    chmod -R 755 "$ASSETS_DIR"
    find "$installed_custom_dir" "$installed_assets_dir" -maxdepth 1 -name '*.css' -exec chmod 644 {} +
    find "$ASSETS_DIR" -maxdepth 1 -name '*.css' -exec chmod 644 {} +

    echo -e "${GREEN}[OK] Plugin, Redmine, and public styles re-synchronized after asset compilation${NC}"
}

verify_deployed_styles() {
    local installed_custom_dir="$PLUGIN_DIR/custom_styles"
    local public_css="$ASSETS_DIR/vazirmatn_fonts.css"
    local installed_font_css="$PLUGIN_DIR/app/assets/stylesheets/vazirmatn_fonts.css"
    local installed_hook="$PLUGIN_DIR/lib/redmine_persian_calendar/hooks.rb"
    local stylesheet

    if [ ! -f "$public_css" ] ||
       ! grep -q "Force Vazirmatn everywhere" "$public_css"; then
        echo -e "${RED}[ERROR] Public Vazirmatn enforcement CSS is missing or outdated${NC}"
        echo -e "${YELLOW}Checked: $public_css${NC}"
        return 1
    fi

    if [ ! -f "$installed_font_css" ] || ! cmp -s "$installed_font_css" "$public_css"; then
        echo -e "${RED}[ERROR] Installed and public font stylesheets differ${NC}"
        echo -e "${YELLOW}Checked: $installed_font_css and $public_css${NC}"
        return 1
    fi

    for stylesheet in custom_overrides.css; do
        if [ ! -f "$installed_custom_dir/$stylesheet" ] ||
           ! cmp -s "$installed_custom_dir/$stylesheet" "$ASSETS_DIR/$stylesheet"; then
            echo -e "${RED}[ERROR] Deployed copies differ for $stylesheet${NC}"
            return 1
        fi
    done

    if [ ! -f "$installed_hook" ] ||
       ! grep -q "jalali_date_picker.css" "$installed_hook"; then
        echo -e "${RED}[ERROR] Installed plugin does not load the Jalali picker assets${NC}"
        echo -e "${YELLOW}Checked: $installed_hook${NC}"
        return 1
    fi

    echo -e "${GREEN}[OK] Redmine, plugin, and public style copies exactly match${NC}"
    echo -e "${GREEN}[OK] Global Vazirmatn enforcement is deployed${NC}"
}

deploy_theme() {
    local source_theme="$PLUGIN_DIR/themes/$THEME_NAME"

    if [ ! -f "$source_theme/stylesheets/application.css" ]; then
        echo -e "${RED}[ERROR] Plugin package is missing the Persian theme${NC}"
        echo -e "${YELLOW}Checked: $source_theme/stylesheets/application.css${NC}"
        return 1
    fi

    # Drop stale theme files from an older package before copying
    rm -rf "$THEME_DIR/stylesheets" "$THEME_DIR/javascripts"
    mkdir -p "$THEME_DIR"
    cp -a "$source_theme/." "$THEME_DIR/"
    chown -R www-data:www-data "$THEME_DIR"
    chmod -R 755 "$THEME_DIR"
    find "$THEME_DIR" -type f -name '*.css' -exec chmod 644 {} +

    echo -e "${GREEN}[OK] Theme '${THEME_NAME}' installed in $THEME_DIR${NC}"
    echo -e "  Select it in Administration > Settings > Display > Theme"
}

verify_theme() {
    if [ ! -f "$THEME_DIR/stylesheets/application.css" ] ||
       ! grep -q "custom_overrides.css" "$THEME_DIR/stylesheets/application.css" ||
       ! grep -q "vazirmatn_fonts.css" "$THEME_DIR/stylesheets/application.css" ||
       [ ! -f "$THEME_DIR/javascripts/theme.js" ]; then
        echo -e "${RED}[ERROR] Persian theme is missing or does not import the styles${NC}"
        return 1
    fi
    echo -e "${GREEN}[OK] Persian theme available in Administration > Settings > Display${NC}"
    echo -e "${GREEN}[OK] Persian styles load only while the theme is selected${NC}"
}

active_theme() {
    (cd "$REDMINE_DIR" &&
        RAILS_ENV=production bundle exec rails runner 'print Setting.ui_theme' 2>/dev/null |
        tail -n 1)
}

set_theme() {
    (cd "$REDMINE_DIR" &&
        RAILS_ENV=production bundle exec rails runner "Setting.ui_theme = %q{${1}}" >/dev/null 2>&1)
}

set_picker_enabled() {
    (cd "$REDMINE_DIR" &&
        RAILS_ENV=production bundle exec rails runner \
            "s = Setting.plugin_redmine_persian_calendar; s['enabled'] = '${1}'; Setting.plugin_redmine_persian_calendar = s" \
            >/dev/null 2>&1)
}

set_default_language() {
    (cd "$REDMINE_DIR" &&
        RAILS_ENV=production bundle exec rails runner \
            "Setting.default_language = %q{${1}}; Setting.force_default_language_for_loggedin = '1'; Setting.force_default_language_for_anonymous = '1'" \
            >/dev/null 2>&1)
}

ask_yes_no() {
    local prompt="$1" default="${2:-y}" answer
    if [ ! -t 0 ]; then
        [ "$default" = "y" ]
        return
    fi
    read -rp "  $prompt [Y/n]: " answer
    case "$answer" in
        y|Y|"") return 0 ;;
        n|N) return 1 ;;
        *) echo -e "${YELLOW}  Enter y or n${NC}"; ask_yes_no "$prompt" "$default" ;;
    esac
}

configure_defaults() {
    echo ""
    echo -e "${BLUE}Default settings:${NC}"

    if ask_yes_no "Enable the Jalali date picker and Persian calendar?" y; then
        set_picker_enabled 1
        echo -e "${GREEN}[OK] Jalali picker enabled${NC}"
    else
        set_picker_enabled 0
        echo -e "${YELLOW}[INFO] Jalali picker disabled; enable it later in Administration > Plugins${NC}"
    fi

    if ask_yes_no "Make 'PDN Persian' the default theme?" y; then
        set_theme "$THEME_NAME"
        echo -e "${GREEN}[OK] Theme enabled: PDN Persian${NC}"
    else
        echo -e "${YELLOW}[INFO] Theme not selected; you can pick it in Administration > Settings > Display${NC}"
    fi

    if ask_yes_no "Set Persian (fa) as the default language for all users?" y; then
        set_default_language fa
        echo -e "${GREEN}[OK] Persian set as default for all users${NC}"
    else
        echo -e "${YELLOW}[INFO] Default language unchanged${NC}"
    fi
}

deactivate_theme() {
    if [ "$(active_theme)" = "$THEME_NAME" ]; then
        set_theme ""
        echo -e "${GREEN}[OK] Theme switched back to Redmine default${NC}"
    fi
}

restart_redmine() {
    mkdir -p "$REDMINE_DIR/tmp"
    touch "$REDMINE_DIR/tmp/restart.txt"
    chown www-data:www-data "$REDMINE_DIR/tmp/restart.txt" 2>/dev/null || true
    pkill -9 -f "Passenger" 2>/dev/null || true
    pkill -9 -f "passenger" 2>/dev/null || true
    pkill -9 -f "Rack" 2>/dev/null || true
    if systemctl restart apache2 2>/dev/null; then
        :
    elif service apache2 restart 2>/dev/null; then
        :
    else
        echo -e "${YELLOW}[WARN] Apache restart command failed; restart it manually${NC}"
    fi
    sleep 5
}

do_install() {
    local tar_path custom_dir full_install="${1:-full}"

    echo -e "${BLUE}=== Installing Persian Calendar ===${NC}"
    echo ""

    tar_path="$(find_plugin_tar)"
    if [ -z "$tar_path" ]; then
        echo -e "${YELLOW}Enter path to $PLUGIN_NAME.tar.gz:${NC}"
        read -rp "> " tar_path
    fi
    if [ ! -f "$tar_path" ]; then
        echo -e "${RED}File not found: $tar_path${NC}"
        return 1
    fi
    echo -e "${GREEN}[OK] Found: $tar_path${NC}"

    rm -rf "$PLUGIN_DIR" "$ASSETS_DIR"

    cd "$REDMINE_DIR/plugins"
    # Package built on a machine whose clock is ahead of the server: the
    # "time stamp in the future" warnings are harmless, suppress them.
    if ! tar xzf "$tar_path" --warning=no-timestamp 2>/dev/null; then
        tar xzf "$tar_path" || return 1
    fi
    echo -e "${GREEN}[OK] Plugin extracted${NC}"

    validate_styles_source "$PLUGIN_DIR" || {
        rm -rf "$PLUGIN_DIR"
        echo -e "${RED}[ERROR] Invalid or incomplete plugin package${NC}"
        return 1
    }

    chown -R www-data:www-data "$PLUGIN_DIR"
    chmod -R 755 "$PLUGIN_DIR"

    custom_dir="$PLUGIN_DIR/custom_styles"
    if [ -d "$custom_dir" ]; then
        echo -e "${BLUE}Deploying custom stylesheets...${NC}"
        deploy_custom_styles "$custom_dir" || return 1
    fi

    cd "$REDMINE_DIR"
    echo -e "${BLUE}Running migrations...${NC}"
    RAILS_ENV=production bundle exec rake redmine:plugins:migrate 2>&1 | tail -3 || return 1
    echo -e "${GREEN}[OK] Migrations done${NC}"

    # Before precompile so Propshaft picks up the theme assets too
    if [ "$full_install" = "full" ]; then
        deploy_theme || return 1
    fi

    echo -e "${BLUE}Recompiling assets...${NC}"
    RAILS_ENV=production bundle exec rails assets:precompile 2>&1 | tail -3 || return 1
    echo -e "${GREEN}[OK] Assets recompiled${NC}"

    sync_public_plugin_styles "$custom_dir" "$PLUGIN_DIR" || return 1
    verify_deployed_styles || return 1
    if [ "$full_install" = "full" ]; then
        verify_theme || return 1
        configure_defaults
    fi

    restart_redmine
    echo -e "${GREEN}[OK] Apache restarted${NC}"

    echo ""
    echo -e "${GREEN}${BOLD}Installation complete!${NC}"
    echo -e "  The plugin has been automatically activated."
    echo -e "  Open: ${CYAN}http://REDMINE_SERVER_ADDRESS${NC}"
    echo ""
}

do_uninstall() {
    echo -e "${RED}This will remove the Persian Calendar plugin.${NC}"
    echo -e "${YELLOW}fa.yml and stylesheets will be kept.${NC}"
    read -rp "Continue? (y/n): " c
    [ "$c" != "y" ] && [ "$c" != "Y" ] && echo "Cancelled." && return

    deactivate_theme
    cd "$REDMINE_DIR"
    RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=$PLUGIN_NAME 2>&1 | tail -3 || return 1
    rm -rf "$PLUGIN_DIR" "$ASSETS_DIR" "$THEME_DIR"
    echo -e "${GREEN}Plugin and Persian theme removed${NC}"

    restart_redmine
    echo -e "${GREEN}Uninstall complete!${NC}"
    echo ""
}

do_status() {
    local http_status

    echo -e "${BOLD}Plugin Status:${NC}"
    [ -d "$PLUGIN_DIR" ] && echo -e "  Plugin:  ${GREEN}Installed${NC}" || echo -e "  Plugin:  ${RED}Not found${NC}"
    [ -d "$ASSETS_DIR" ] && echo -e "  Assets:  ${GREEN}Present${NC}" || echo -e "  Assets:  ${YELLOW}Missing${NC}"
    [ -f "$PLUGIN_DIR/config/locales/fa.yml" ] && echo -e "  fa.yml:  ${GREEN}Present${NC}" || echo -e "  fa.yml:  ${RED}Missing${NC}"
    if [ -f "$THEME_DIR/stylesheets/application.css" ]; then
        local current_theme
        current_theme="$(active_theme)"
        [ -z "$current_theme" ] && current_theme="default"
        echo -e "  Theme:   ${GREEN}PDN Persian installed${NC} (active: $current_theme)"
    else
        echo -e "  Theme:   ${RED}Not found${NC}"
    fi
    http_status="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1/" 2>/dev/null || true)"
    [ -n "$http_status" ] || http_status="000"
    [ "$http_status" = "200" ] && echo -e "  Apache:  ${GREEN}Running${NC}" || echo -e "  Apache:  ${RED}HTTP $http_status${NC}"
    echo ""
}

main_menu() {
    while true; do
        show_banner
        show_menu
        read -rp "  Enter choice [1-5]: " choice
        case $choice in
            1) check_root; check_redmine; do_install full; read -rp "Press Enter..." ;;
            2) check_root; check_redmine; do_install minimal; read -rp "Press Enter..." ;;
            3) check_root; check_redmine; do_uninstall; read -rp "Press Enter..." ;;
            4) check_redmine; do_status; read -rp "Press Enter..." ;;
            5) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

case "${1:-}" in
    install)        show_banner; check_root; check_redmine; do_install full ;;
    install-plugin) show_banner; check_root; check_redmine; do_install minimal ;;
    uninstall)      show_banner; check_root; check_redmine; do_uninstall ;;
    status)         show_banner; check_redmine; do_status ;;
    help|-h|--help) usage ;;
    "")             main_menu ;;
    *)              echo -e "${RED}Unknown command: $1${NC}"; echo ""; usage; exit 1 ;;
esac
