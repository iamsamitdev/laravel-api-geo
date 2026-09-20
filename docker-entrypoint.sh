#!/bin/sh
# Entrypoint สำหรับ Render: เตรียมฐานข้อมูล + token ทุกครั้งที่ container เกิดใหม่
# เหตุผล: filesystem ของ Render (และ PaaS ทั่วไป) เป็น ephemeral ไฟล์ SQLite จึงหายทุกครั้งที่
#        deploy / restart / ตื่นจากการหลับ เราจึงสร้างใหม่จาก migration + seeder ทุกครั้ง
set -e

: "${DB_CONNECTION:=sqlite}"
: "${PORT:=10000}"

if [ "$DB_CONNECTION" = "sqlite" ]; then
  DB_PATH="${DB_DATABASE:-/var/www/html/database/database.sqlite}"
  mkdir -p "$(dirname "$DB_PATH")"
  touch "$DB_PATH"
  echo "▶ sqlite ที่ $DB_PATH"
fi

echo "▶ migrate"
php artisan migrate --force --no-interaction

if [ "${SEED_ON_BOOT:-false}" = "true" ]; then
  echo "▶ seed (SEED_ON_BOOT=true)"
  php artisan db:seed --force --no-interaction
fi

# Sanctum token เก็บในฐานข้อมูล ถ้า DB รีเซ็ตทุกครั้ง token ที่เคยออกจะหายตาม
# จึงออก token ซ้ำจากค่าคงที่ใน env ทุกครั้ง (ค่าเดียวกับ API_TOKEN ฝั่ง Astro)
if [ -n "${BUILD_TOKEN:-}" ]; then
  echo "▶ ออก build token จาก BUILD_TOKEN"
  php artisan geo:issue-build-token --token="$BUILD_TOKEN" --no-interaction
fi

php artisan config:cache
php artisan route:cache

echo "▶ serve บนพอร์ต $PORT"
exec php artisan serve --host 0.0.0.0 --port "$PORT"
