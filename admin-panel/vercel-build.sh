#!/bin/bash
set -e

echo "=== Preparing Flutter SDK on Vercel ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"
flutter --version

echo "=== Building Admin Panel Web Release ==="
flutter config --no-analytics
flutter config --enable-web
flutter pub get

# Support custom backend API URL or default
API_URL="${API_BASE_URL:-https://alif-school-api.vercel.app/api}"
flutter build web --release --dart-define=API_BASE_URL="$API_URL"

echo "=== Admin Panel build completed in build/web ==="
