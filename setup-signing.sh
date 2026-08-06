#!/bin/bash
set -euo pipefail

# One-time setup: creates a local self-signed code-signing certificate and
# imports it into the login keychain. build.sh uses it instead of ad-hoc
# signing (--sign -), because ad-hoc signatures hash the raw binary with no
# identity string — so every rebuild changes the hash, and macOS silently
# drops any TCC grant (Accessibility, Screen Recording) keyed to it. A
# self-signed cert gives codesign a stable identity that survives rebuilds,
# so you only have to grant each permission once.
#
# Safe to re-run — skips creation if the cert already exists.

IDENTITY="MacTools Local Dev"

if security find-certificate -c "$IDENTITY" -a login.keychain-db >/dev/null 2>&1; then
    echo "✓ '$IDENTITY' already exists in the login keychain — nothing to do."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

openssl req -x509 -newkey rsa:2048 -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -days 3650 -nodes \
    -subj "/CN=$IDENTITY" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" >/dev/null 2>&1

PASS=$(openssl rand -base64 24)
# -legacy: macOS's Security framework doesn't support OpenSSL 3's default
# PKCS12 encryption; without this, `security import` fails MAC verification.
openssl pkcs12 -export -legacy -out "$TMP/cert.p12" -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -passout "pass:$PASS" >/dev/null 2>&1

security import "$TMP/cert.p12" -k ~/Library/Keychains/login.keychain-db -P "$PASS" \
    -T /usr/bin/codesign -T /usr/bin/security

echo "✓ Created and imported '$IDENTITY'. Future ./build.sh runs will sign with it."
echo "  Note: this changes the app's identity once — macOS will ask you to"
echo "  re-grant Accessibility/Screen Recording one more time after the next"
echo "  build, then it'll stick across all rebuilds going forward."
