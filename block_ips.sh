#!/bin/bash
# آدرس گیت‌هاب برای دریافت لیست IP ها
GITHUB_URL="https://raw.githubusercontent.com/mohammad051/ipblock/refs/heads/main/ip"

# تابع برای بروزرسانی لیست IP ها و اعمال تغییرات
update_blocked_ips() {
  echo "در حال دریافت لیست IP ها از گیت‌هاب..."
  ips=$(curl -s "$GITHUB_URL")
  if [[ -z "$ips" ]]; then
    echo "لیست IP ها از گیت‌هاب دریافت نشد. لطفاً لینک را بررسی کنید."
    return 1
  fi

  # حذف قوانین قبلی مرتبط با IP ها که توسط این اسکریپت اضافه شده‌اند
  echo "در حال حذف قوانین قبلی مرتبط با مسدودسازی..."
  iptables -D INPUT -j BLOCKED_IPS 2>/dev/null
  iptables -D OUTPUT -j BLOCKED_IPS 2>/dev/null
  iptables -F BLOCKED_IPS 2>/dev/null
  iptables -X BLOCKED_IPS 2>/dev/null

  # ایجاد زنجیره جدید برای مسدود کردن IP ها
  iptables -N BLOCKED_IPS

  # حذف مقادیر تکراری و مسدود کردن هر IP جدید با استفاده از iptables
  echo "در حال اعمال قوانین جدید..."
  unique_ips=$(echo "$ips" | tr -d '\r' | xargs -n1 | sort -u)
  while IFS= read -r ip; do
    # بررسی معتبر بودن فرمت آی‌پی یا رنج
    if [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?$ ]]; then
      # اضافه کردن قانون برای مسدود کردن IP به صورت یک‌باره
      iptables -A BLOCKED_IPS -s "$ip" -j DROP
      iptables -A BLOCKED_IPS -d "$ip" -j DROP
    fi
  done <<< "$unique_ips"

  # اعمال زنجیره جدید به INPUT و OUTPUT
  iptables -A INPUT -j BLOCKED_IPS
  iptables -A OUTPUT -j BLOCKED_IPS

  echo "تمام IP های دریافت شده از گیت‌هاب با موفقیت مسدود شدند."
}

# تابع برای باز کردن پورت‌های مشخص شده
allow_ports() {
  # لیست پورت‌هایی که باید باز شوند
  ports=(22 2053 443 8443 54879 80)

  # فعال کردن UFW
  echo "در حال فعال‌سازی UFW..."
  echo "y" | ufw enable  # تایید خودکار برای فعال کردن UFW

  # باز کردن پورت‌ها
  for port in "${ports[@]}"; do
    ufw allow "$port"
  done

  echo "پورت‌های زیر با موفقیت باز شدند: ${ports[*]}"
}

# اجرای اولیه اسکریپت
update_blocked_ips
allow_ports

# تنظیم کرون جاب برای اجرای خودکار هر چند روز
setup_cron_job() {
  echo "در حال تنظیم کرون جاب برای بروزرسانی خودکار..."
  (crontab -l 2>/dev/null; echo "0 0 */3 * * $(realpath $0)") | crontab -
  echo "کرون جاب تنظیم شد: اسکریپت هر 3 روز یک بار اجرا خواهد شد."
}
setup_cron_job
