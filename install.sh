#!/usr/bin/env bash
# Install redBus analytics skills into Cursor's personal skills folder.
# Usage: ./install.sh [--copy] [--with-rules] [skill-name ...]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DEST="${HOME}/.cursor/skills"
RULES_DEST="${HOME}/.cursor/rules"
MODE="link"
WITH_RULES=0
SELECTED=()

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --with-rules) WITH_RULES=1 ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) SELECTED+=("$arg") ;;
  esac
done

if [ ${#SELECTED[@]} -eq 0 ]; then
  for d in "$REPO_DIR"/skills/*/; do SELECTED+=("$(basename "$d")"); done
fi

install_item() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      echo "  up to date  $(basename "$dest")"
      return
    fi
    mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  backed up existing $(basename "$dest")"
  fi
  if [ "$MODE" = "link" ]; then ln -s "$src" "$dest"; else cp -R "$src" "$dest"; fi
  echo "  installed   $(basename "$dest") ($MODE)"
}

mkdir -p "$SKILLS_DEST"
echo "Skills -> $SKILLS_DEST"
for name in "${SELECTED[@]}"; do
  src="$REPO_DIR/skills/$name"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "  skipped     $name (no skills/$name/SKILL.md)"
    continue
  fi
  install_item "$src" "$SKILLS_DEST/$name"
done

if [ "$WITH_RULES" -eq 1 ]; then
  mkdir -p "$RULES_DEST"
  echo "Rules -> $RULES_DEST"
  for rule in "$REPO_DIR"/rules/*.mdc; do
    [ -e "$rule" ] && install_item "$rule" "$RULES_DEST/$(basename "$rule")"
  done
fi

echo "Done. Restart Cursor or open a new chat to load the skills."
