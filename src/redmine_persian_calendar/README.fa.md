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

گزینه **1) نصب کامل** را انتخاب کنید. نصب‌کننده ردماین را خودکار پیدا می‌کند
(`/opt/redmine`، `/var/www/redmine` و …؛ با `REDMINE_DIR=/path` می‌توانید مسیر را دستی بدهید) و:

1. افزونه را در `plugins/redmine_persian_calendar` استخراج می‌کند
2. فایل‌ها و استایل‌ها را بررسی می‌کند
3. استایل‌ها، فونت‌ها و پوسته **PDN Persian** (`themes/persian`) را نصب می‌کند
4. مایگریشن‌ها را اجرا و دارایی‌ها (assets) را دوباره کامپایل می‌کند
5. سه سؤال می‌پرسد و پاسخ‌ها را اعمال می‌کند:
   - انتخاب‌گر تاریخ شمسی و تقویم جلالی فعال شود؟
   - پوسته پیش‌فرض روی **PDN Persian** تنظیم شود؟
   - زبان پیش‌فرض برای همه کاربران فارسی (`fa`) شود؟
6. Apache را ری‌استارت می‌کند

گزینه‌های منو:

1. نصب کامل (افزونه + انتخاب‌گر + پوسته + زبان)
2. فقط نصب افزونه (انتخاب‌گر؛ پوسته و زبان تغییر نمی‌کنند)
3. حذف
4. وضعیت
5. خروج

دستورهای غیرتعاملی:

```bash
/tmp/install.sh install          # نصب کامل با پاسخ‌های پیشنهادی
/tmp/install.sh install-plugin   # فقط افزونه، بدون تغییر پوسته و زبان
/tmp/install.sh uninstall
/tmp/install.sh status
/tmp/install.sh --help           # نمایش گزینه‌ها و متغیرهای محیطی
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

گزینه **3) حذف تقویم شمسی** را انتخاب کنید (یا `/tmp/install.sh uninstall`).
پوسته به حالت پیش‌فرض برمی‌گردد و افزونه، دارایی‌ها و پوسته حذف می‌شوند.
فایل زبان `fa` و داده‌های دیتابیس شما دست‌نخورده می‌مانند.

## وضعیت

```bash
/tmp/install.sh status
```

افزونه، دارایی‌ها، پوسته (نصب‌شده + فعال) و وضعیت Apache را نشان می‌دهد.

## نصب دستی

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

سپس در مدیریت → تنظیمات → نمایش، پوسته **PDN Persian** را انتخاب کنید.

## مهم

- نصب‌کننده را با کاربر **root** اجرا کنید.
- قبل از هر تغییر از دیتابیس و فایل‌ها پشتیبان بگیرید. فایل `DISCLAIMER.md` را ببینید.
- ساعت سرور باید درست باشد (تاریخ ثبت زمان به آن وابسته است).
- توسعه‌دهنده: PDNSoft Dev Team · نسخه 1.0.0 · MIT
