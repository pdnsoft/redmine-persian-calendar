# تقویم شمسی ردماین

تقویم جلالی، انتخاب‌گر تاریخ شمسی و پوسته فارسی برای Redmine 6/7.

[English version](README.md)

## پیش‌نیازها

- Redmine نسخه 6.x یا 7.x (تست‌شده روی 7.0.1)
- Ruby (ردماین 7 به 3.2 یا بالاتر نیاز دارد)
- دسترسی SSH با کاربر root به سرور

## نصب

بسته `redmine_persian_calendar.tar.gz` را از صفحه
[Releases](https://github.com/pdnsoft/redmine-persian-calendar/releases) دانلود کنید.
اگر سورس‌ها را تغییر دادید، اول آن را دوباره بسازید:

```bash
./build.sh
```

سپس بسته و نصب‌کننده را آپلود و نصب‌کننده را با کاربر root اجرا کنید:

```bash
scp redmine_persian_calendar.tar.gz install.sh root@YOUR_SERVER:/tmp/
```

```bash
ssh root@YOUR_SERVER
chmod +x /tmp/install.sh
/tmp/install.sh
```

گزینه **1) نصب کامل** را انتخاب کنید، یا دو بخش را جدا نصب کنید.
افزونه (تقویم جلالی، انتخاب‌گر تاریخ، زبان `fa`) و پوسته **PDN Persian**
کاملاً مستقل‌اند: هر کدام را می‌توان بدون دست زدن به دیگری نصب، بازگردانی
یا حذف کرد. نصب‌کننده ردماین را خودکار پیدا می‌کند
(`/opt/redmine`، `/var/www/redmine` و …؛ با `REDMINE_DIR=/path` می‌توانید مسیر را دستی بدهید).

نصب کامل:

1. افزونه را در `plugins/redmine_persian_calendar` نصب می‌کند
2. پوسته را در `themes/persian` و استایل‌ها و فونت‌های آن را در
   `public/plugin_assets/persian_theme` نصب می‌کند
3. مایگریشن‌ها را اجرا و دارایی‌ها (assets) را دوباره کامپایل می‌کند
4. می‌پرسد و اعمال می‌کند:
   - انتخاب‌گر تاریخ شمسی و تقویم جلالی فعال شود؟
   - زبان پیش‌فرض برای همه کاربران فارسی (`fa`) شود؟
   - پوسته پیش‌فرض روی **PDN Persian** تنظیم شود؟
5. Apache را ری‌استارت می‌کند

گزینه‌های منو:

1. نصب کامل (افزونه + پوسته)
2. فقط نصب افزونه
3. فقط نصب پوسته
4. حذف کامل
5. فقط حذف افزونه (پوسته می‌ماند)
6. فقط حذف پوسته (افزونه می‌ماند)
7. وضعیت
8. خروج

دستورهای غیرتعاملی:

```bash
/tmp/install.sh install            # افزونه + پوسته با پاسخ‌های پیشنهادی
/tmp/install.sh install-plugin     # فقط افزونه
/tmp/install.sh install-theme      # فقط پوسته
/tmp/install.sh uninstall          # حذف هر دو
/tmp/install.sh uninstall-plugin   # حذف افزونه، پوسته می‌ماند
/tmp/install.sh uninstall-theme    # حذف پوسته، افزونه می‌ماند
/tmp/install.sh status
/tmp/install.sh --help             # نمایش گزینه‌ها و متغیرهای محیطی
```

متغیرهای محیطی:

- `REDMINE_DIR` — مسیر ریشه ردماین (پیش‌فرض: تشخیص خودکار)
- `PLUGIN_ARCHIVE` — مسیر فایل بسته (پیش‌فرض: تشخیص خودکار)

```bash
REDMINE_DIR=/var/www/redmine ./install.sh install
```

## بعد از نصب

- **تنظیمات** — مدیریت → افزونه‌ها → «تقویم شمسی ردماین» → پیکربندی
  (فعال/غیرفعال کردن تقویم، کش تبدیل تاریخ).
- **پوسته** — مدیریت → تنظیمات → نمایش → پوسته → **PDN Persian**.
  فونت فارسی، استایل جدول‌ها، وسط‌چین شدن ساعت‌ها و منوی کلیک‌راست اصلاح‌شده
  فقط وقتی این پوسته انتخاب شده بارگذاری می‌شوند؛ با هر پوسته دیگر ردماین
  پیش‌فرض و دست‌نخورده می‌ماند.
- **زبان** — ترجمه فارسی همراه افزونه (`fa`) نصب می‌شود. نصب‌کننده می‌تواند
  فارسی را برای همه بازدیدکنندگان (کاربران واردشده و مهمان) اجباری کند؛
  این گزینه در مدیریت → تنظیمات → نمایش → زبان قابل تغییر است.

## حذف

حذف هر دو، یا یکی از بخش‌ها:

```bash
/tmp/install.sh uninstall          # افزونه + پوسته
/tmp/install.sh uninstall-plugin   # فقط افزونه؛ پوسته کار می‌کند
/tmp/install.sh uninstall-theme    # فقط پوسته؛ افزونه کار می‌کند
```

با حذف پوسته، ردماین به پوسته پیش‌فرض برمی‌گردد. فایل زبان `fa` و داده‌های
دیتابیس شما دست‌نخورده می‌مانند.

## وضعیت

```bash
/tmp/install.sh status
```

افزونه و پوسته را جداگانه (نصب‌شده و پوسته فعال) و وضعیت Apache را نشان می‌دهد.

## نصب دستی

```bash
cd /path/to/redmine/plugins
tar xzf /tmp/redmine_persian_calendar.tar.gz
chown -R www-data:www-data redmine_persian_calendar
cd ..
RAILS_ENV=production bundle exec rake redmine:plugins:migrate
# پوسته: فایل‌های پوسته به‌همراه دارایی‌های ثابت خودش (مستقل از افزونه)
cp -a plugins/redmine_persian_calendar/themes/persian themes/
mkdir -p public/plugin_assets/persian_theme/fonts
cp plugins/redmine_persian_calendar/custom_styles/custom_overrides.css public/plugin_assets/persian_theme/
sed 's#/plugin_assets/redmine_persian_calendar/#/plugin_assets/persian_theme/#g' \
  plugins/redmine_persian_calendar/app/assets/stylesheets/vazirmatn_fonts.css \
  > public/plugin_assets/persian_theme/vazirmatn_fonts.css
cp plugins/redmine_persian_calendar/app/assets/fonts/*.woff2 public/plugin_assets/persian_theme/fonts/

# افزونه: فقط دارایی‌های انتخاب‌گر تاریخ
mkdir -p public/plugin_assets/redmine_persian_calendar
cp -a plugins/redmine_persian_calendar/app/assets/{javascripts,stylesheets}/. public/plugin_assets/redmine_persian_calendar/

chown -R www-data:www-data public/plugin_assets/persian_theme \
  public/plugin_assets/redmine_persian_calendar themes/persian
RAILS_ENV=production bundle exec rails assets:precompile
systemctl restart apache2
```

سپس در مدیریت → تنظیمات → نمایش، پوسته **PDN Persian** را انتخاب کنید.

## مهم

- نصب‌کننده را با کاربر **root** اجرا کنید.
- قبل از هر تغییر از دیتابیس و فایل‌ها پشتیبان بگیرید. فایل `DISCLAIMER.md` را ببینید.
- ساعت سرور باید درست باشد (تاریخ ثبت زمان به آن وابسته است).
- توسعه‌دهنده: PDNSoft Dev Team · نسخه 1.0.0 · MIT
