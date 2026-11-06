#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
VERSION="${RELEASE_TAG#v}"
VERSION="${VERSION:-0.0.0}"

OUT_DIR="$ROOT/dist"
STAGE="$OUT_DIR/OpenCode-Unlimited-$VERSION"
ZIP="$OUT_DIR/OpenCode-Unlimited-$VERSION.zip"

rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

for item in bin lib plugins install.sh install.ps1 package.json README.md; do
  if [ -e "$ROOT/$item" ]; then
    cp -r "$ROOT/$item" "$STAGE/"
  fi
done

cd "$STAGE"
zip -r -q "$ZIP" .
cd "$ROOT"

SHA256=$(sha256sum "$ZIP" | awk '{print $1}')
SIZE=$(du -h "$ZIP" | awk '{print $1}')

echo "artifact : $ZIP"
echo "size     : $SIZE"
echo "sha256   : $SHA256"
