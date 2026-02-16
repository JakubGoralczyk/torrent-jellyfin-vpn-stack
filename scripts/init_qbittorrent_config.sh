#!/bin/sh
set -eu

TARGET_ROOT="/config"
SEED_ROOT="/seed-config"
CONF="${TARGET_ROOT}/config/qBittorrent.conf"

mkdir -p \
  "${TARGET_ROOT}/config/rss" \
  "${TARGET_ROOT}/data/logs" \
  "${TARGET_ROOT}/data/BT_backup"

# If we are migrating from an existing bind mount, seed once.
if [ ! -f "${CONF}" ] && [ -f "${SEED_ROOT}/config/qBittorrent.conf" ]; then
  cp -a "${SEED_ROOT}/." "${TARGET_ROOT}/"
fi

# Bootstrap minimal config for first run.
if [ ! -f "${CONF}" ]; then
  cat > "${CONF}" <<'EOF'
[LegalNotice]
Accepted=true

[Preferences]
General\Locale=en
MailNotification\req_auth=true
EOF
fi

ensure_ini_key() {
  section="$1"
  key="$2"
  value="$3"

  awk -v section="${section}" -v key="${key}" -v value="${value}" '
    BEGIN { in_sec=0; sec_seen=0; key_set=0 }
    {
      if ($0 == "[" section "]") {
        in_sec=1
        sec_seen=1
        print
        next
      }

      if (in_sec && $0 ~ /^\[/) {
        if (!key_set) {
          print key "=" value
          key_set=1
        }
        in_sec=0
      }

      if (in_sec && index($0, key "=") == 1) {
        if (!key_set) {
          print key "=" value
          key_set=1
        }
        next
      }

      print
    }
    END {
      if (!sec_seen) {
        print "[" section "]"
      }
      if (!key_set) {
        print key "=" value
      }
    }
  ' "${CONF}" > "${CONF}.tmp"

  mv "${CONF}.tmp" "${CONF}"
}

: "${QBIT_DOMAIN:?QBIT_DOMAIN is required}"
: "${QBIT_TRUSTED_PROXY:?QBIT_TRUSTED_PROXY is required}"
: "${QBIT_BAN_DURATION:=21600}"
: "${QBIT_MAX_AUTH_FAIL_COUNT:=3}"
: "${QBIT_SESSION_TIMEOUT:=900}"

ensure_ini_key "LegalNotice" "Accepted" "true"

# Cleanup malformed keys created by older bootstraps.
sed -i \
  -e '/^WebUIHTTPSEnabled=/d' \
  -e '/^WebUIHTTPSCertificatePath=/d' \
  -e '/^WebUIHTTPSKeyPath=/d' \
  -e '/^WebUIReverseProxySupportEnabled=/d' \
  -e '/^WebUIServerDomains=/d' \
  -e '/^WebUITrustedReverseProxiesList=/d' \
  -e '/^WebUIMaxAuthenticationFailCount=/d' \
  -e '/^WebUIBanDuration=/d' \
  -e '/^WebUISessionTimeout=/d' \
  -e '/^WebUIHostHeaderValidation=/d' \
  -e '/^WebUICSRFProtection=/d' \
  -e '/^WebUIClickjackingProtection=/d' \
  -e '/^WebUISecureCookie=/d' \
  -e '/^WebUIUseUPnP=/d' \
  -e '/^WebUILocalHostAuth=/d' \
  "${CONF}"

ensure_ini_key "Preferences" "WebUI\\\\HTTPS\\\\Enabled" "true"
ensure_ini_key "Preferences" "WebUI\\\\HTTPS\\\\CertificatePath" "/run/qbit-tls/cert.pem"
ensure_ini_key "Preferences" "WebUI\\\\HTTPS\\\\KeyPath" "/run/qbit-tls/key.pem"
ensure_ini_key "Preferences" "WebUI\\\\ReverseProxySupportEnabled" "true"
ensure_ini_key "Preferences" "WebUI\\\\ServerDomains" "${QBIT_DOMAIN}"
ensure_ini_key "Preferences" "WebUI\\\\TrustedReverseProxiesList" "${QBIT_TRUSTED_PROXY}"
ensure_ini_key "Preferences" "WebUI\\\\MaxAuthenticationFailCount" "${QBIT_MAX_AUTH_FAIL_COUNT}"
ensure_ini_key "Preferences" "WebUI\\\\BanDuration" "${QBIT_BAN_DURATION}"
ensure_ini_key "Preferences" "WebUI\\\\SessionTimeout" "${QBIT_SESSION_TIMEOUT}"
ensure_ini_key "Preferences" "WebUI\\\\HostHeaderValidation" "true"
ensure_ini_key "Preferences" "WebUI\\\\CSRFProtection" "true"
ensure_ini_key "Preferences" "WebUI\\\\ClickjackingProtection" "true"
ensure_ini_key "Preferences" "WebUI\\\\SecureCookie" "true"
ensure_ini_key "Preferences" "WebUI\\\\UseUPnP" "false"
ensure_ini_key "Preferences" "WebUI\\\\LocalHostAuth" "true"
