#!/usr/bin/env bash
# Generate source/ApiConfig.mc from .env so API_KEY and API_URL are not in the repo.
# Run from repo root: ./scripts/generate_config.sh
# Use the same API_KEY as GarminReadingApp; set API_URL to your meditation-sessions endpoint.

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
OUT_FILE="$REPO_ROOT/source/ApiConfig.mc"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing .env. Copy .env.example to .env and set API_KEY and API_URL."
  exit 1
fi

# Parse .env (skip comments and empty lines)
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ""|\#*) ;;
    *=*)
      key="${line%%=*}"; key="${key%"${key##*[![:space:]]}"}"
      val="${line#*=}"; val="${val#\"}"; val="${val%\"}"; val="${val#\'}"; val="${val%\'}"
      export "$key=$val"
      ;;
  esac
done < "$ENV_FILE"

if [ -z "$API_KEY" ] || [ -z "$API_URL" ]; then
  echo "Error: .env must define API_KEY and API_URL."
  exit 1
fi

# Escape for Monkey C string literals (backslash and double-quote)
escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
API_KEY_ESC=$(escape "$API_KEY")
API_URL_ESC=$(escape "$API_URL")

cat > "$OUT_FILE" << EOF
import Toybox.Lang;

// Generated from .env by scripts/generate_config.sh — do not edit by hand; edit .env and re-run the script.

class ApiConfig {
    static const API_KEY as String = "$API_KEY_ESC";
    static const API_URL as String = "$API_URL_ESC";
}
EOF

echo "Wrote $OUT_FILE from .env"
