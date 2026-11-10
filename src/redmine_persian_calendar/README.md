# Redmine Persian Calendar | تقویم شمسی ردماین

Jalali (Persian) calendar, date picker and Persian theme for Redmine 6/7.

[نسخه فارسی](README.fa.md)

## Requirements

- Redmine 6.x or 7.x (tested on 7.0.1)
- Ruby (Redmine 7 needs 3.2+)
- Root SSH access to the server

## Install

Download `redmine_persian_calendar.tar.gz` from the
[Releases](https://github.com/pdnsoft/redmine-persian-calendar/releases) page.
If you changed the sources, rebuild it first:

```bash
./build.sh
```

Upload the tarball and the installer, then run the installer as root:

```bash
scp redmine_persian_calendar.tar.gz install.sh root@YOUR_SERVER:/tmp/
```

```bash
ssh root@YOUR_SERVER
chmod +x /tmp/install.sh
/tmp/install.sh
```

Choose **1) Install everything**. The installer finds Redmine automatically
(`/opt/redmine`, `/var/www/redmine`, …; override with `REDMINE_DIR=/path`) and:

1. extracts the plugin to `plugins/redmine_persian_calendar`
2. validates files and styles
3. deploys the stylesheets, fonts and the **PDN Persian** theme (`themes/persian`)
4. runs migrations and recompiles assets
5. asks three questions and applies your answers:
   - enable the Jalali date picker and Persian calendar?
   - make **PDN Persian** the default theme?
   - set Persian (`fa`) as the default language for all users?
6. restarts Apache

Menu options:

1. install everything (plugin + picker + theme + language)
2. install plugin only (picker; theme and language untouched)
3. uninstall
4. status
5. exit

Non-interactive commands:

```bash
/tmp/install.sh install          # everything; recommended answers
/tmp/install.sh install-plugin   # plugin only, no theme/language change
/tmp/install.sh uninstall
/tmp/install.sh status
/tmp/install.sh --help           # options and environment variables
```

Environment variables:

- `REDMINE_DIR` — Redmine root directory (default: auto-detect)
- `PLUGIN_ARCHIVE` — path to the tarball (default: auto-detect)

```bash
REDMINE_DIR=/var/www/redmine ./install.sh install
```

## After install

- **Settings** — Administration → Plugins → «تقویم شمسی ردماین» → Configure
  (enable/disable the calendar, conversion cache).
- **Theme** — Administration → Settings → Display → Theme → **PDN Persian**.
  Persian fonts, table styling, centered hours and the corrected RTL context
  menu load only while this theme is selected; any other theme stays stock.
- **Language** — Persian translations come with the plugin locale (`fa`). The
  installer can force Persian for every visitor (logged-in and anonymous);
  toggle it in Administration → Settings → Display → Language.

## Uninstall

Choose **2) Uninstall Persian Calendar** (or `/tmp/install.sh uninstall`).
It switches the theme back to default, removes the plugin, assets and theme.
The `fa` locale and your database data are untouched.

## Status

```bash
/tmp/install.sh status
```

Shows plugin, assets, theme (installed + active) and Apache status.

## Manual install

```bash
cd /path/to/redmine/plugins
tar xzf /tmp/redmine_persian_calendar.tar.gz
chown -R www-data:www-data redmine_persian_calendar
cd ..
RAILS_ENV=production bundle exec rake redmine:plugins:migrate
cp -a plugins/redmine_persian_calendar/themes/persian themes/
cp -a plugins/redmine_persian_calendar/custom_styles/. public/plugin_assets/redmine_persian_calendar/
cp -a plugins/redmine_persian_calendar/app/assets/{fonts,javascripts,stylesheets}/. public/plugin_assets/redmine_persian_calendar/
chown -R www-data:www-data public/plugin_assets/redmine_persian_calendar themes/persian
RAILS_ENV=production bundle exec rails assets:precompile
systemctl restart apache2
```

Then select **PDN Persian** in Administration → Settings → Display.

## Important

- Run the installer as **root**.
- Back up your database and files first. See `DISCLAIMER.md`.
- Server clock must be correct (time entry dates depend on it).
- Developer: PDNSoft Dev Team · Version 1.0.0 · MIT
