#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for script in kejilion.sh cn/kejilion.sh; do
	bash -n "$root/$script"
	grep -Fx 'KPANEL_WEB_CERTIFICATE_FORCE_RENEW_PROTOCOL_VERSION="1"' <(tr -d '\r' < "$root/$script") >/dev/null
done
if ! command -v flock >/dev/null; then
	printf 'force_renew=unavailable (requires Linux flock)\n'
	exit 0
fi
fixture_root="$(mktemp -d)"
trap 'rm -rf -- "$fixture_root"' EXIT
# Exercise only the certificate functions, never source the host-management entrypoint.
sed -n '/^kpanel_web_certificate_pair_valid()/,/^kpanel_web_certificate_available()/p;/^kpanel_web_force_renew_certificate()/,/^install_ssltls()/p' "$root/kejilion.sh" |
	sed -e '/^kpanel_web_certificate_available()/d' -e '/^install_ssltls()/d' \
		-e "s|/home/web|$fixture_root/web|g" -e "s|/etc/letsencrypt|$fixture_root/letsencrypt|g" -e "s|^\t\[ -d \"\$path\" \]|\t[ -d \"\$path\" ]|" > "$fixture_root/functions.sh"
# The fixture web root lives outside /home, so only the /home guard needs a stand-in.
sed -i "s| /home $fixture_root/web | $fixture_root |" "$fixture_root/functions.sh"
source "$fixture_root/functions.sh"

hash() { sha256sum "$1" | awk '{print $1}'; }
issue() { # name days issuer
	openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj "/O=$3/CN=issuer" -keyout "$fixture_root/$1-ca-key.pem" -out "$fixture_root/$1-ca.pem" >/dev/null 2>&1
	openssl req -newkey rsa:2048 -nodes -subj /CN=example.com -keyout "$fixture_root/$1-key.pem" -out "$fixture_root/$1.csr" >/dev/null 2>&1
	printf 'subjectAltName=DNS:example.com\n' > "$fixture_root/$1.ext"
	openssl x509 -req -in "$fixture_root/$1.csr" -CA "$fixture_root/$1-ca.pem" -CAkey "$fixture_root/$1-ca-key.pem" -CAcreateserial -days "$2" -extfile "$fixture_root/$1.ext" -out "$fixture_root/$1-cert.pem" >/dev/null 2>&1
}
issue old 10 "Let's Encrypt"
issue new 90 "Let's Encrypt"
issue foreign 10 "Example CA"

web="$fixture_root/web"; certs="$web/certs"
mkdir -p "$web/conf.d" "$certs" "$fixture_root/letsencrypt/live/example.com"
printf 'server { server_name example.com; }\n' > "$web/conf.d/example.com.conf"
reset() {
	cp "$fixture_root/${1:-old}-cert.pem" "$certs/example.com_cert.pem"
	cp "$fixture_root/${1:-old}-key.pem" "$certs/example.com_key.pem"
	chmod 600 "$certs/example.com_key.pem"
	rm -f "$certs/example.com.custom" "$fixture_root/calls"
}
docker() {
	printf '%s\n' "$*" >> "$fixture_root/calls"
	case " $* " in
		' ps '*) echo nginxid ;;
		*' certbot/certbot certonly '*)
			[ "${certbot:-ok}" = ok ] || return 1
			cp "$fixture_root/new-cert.pem" "$fixture_root/letsencrypt/live/example.com/fullchain.pem"
			cp "$fixture_root/new-key.pem" "$fixture_root/letsencrypt/live/example.com/privkey.pem" ;;
		*' nginx -t '*) [ "${nginx_test:-ok}" = ok ] || { [ -e "$fixture_root/rolled-back" ] || return 1; } ;;
	esac
	return 0
}
timeout() { shift; "$@"; }
run() { set +e; kpanel_web_force_renew_certificate "$@" > "$fixture_root/receipt"; status=$?; set -e; }
no_residue() { [ -z "$(find "$certs" -maxdepth 1 -name '.kpanel-renew.*' -print)" ]; }

# Success publishes the new pair only after Certbot, then restarts and reloads Nginx.
reset; certbot=ok nginx_test=ok run example.com
[ "$status" = 0 ]; grep -Fx 'KPANEL_CERTIFICATE renewed example.com' "$fixture_root/receipt"
cmp "$certs/example.com_cert.pem" "$fixture_root/new-cert.pem"; cmp "$certs/example.com_key.pem" "$fixture_root/new-key.pem"
[ "$(stat -c %a "$certs/example.com_key.pem")" = 600 ]; no_residue
grep -Fx 'start nginx' "$fixture_root/calls"; grep -F 'nginx -s reload' "$fixture_root/calls" >/dev/null
printf 'force_renew_success=pass\n'

# Failed issuance leaves the served pair untouched and Nginx running again.
reset; before_cert=$(hash "$certs/example.com_cert.pem"); before_key=$(hash "$certs/example.com_key.pem")
certbot=fail run example.com
[ "$status" = 1 ]; grep -Fx 'KPANEL_CERTIFICATE failed' "$fixture_root/receipt"
[ "$(hash "$certs/example.com_cert.pem")" = "$before_cert" ]; [ "$(hash "$certs/example.com_key.pem")" = "$before_key" ]
grep -Fx 'start nginx' "$fixture_root/calls"; no_residue
printf 'force_renew_failure_keeps_pair=pass\n'

# A rejected configuration rolls the files back and reloads the old pair.
reset; before_cert=$(hash "$certs/example.com_cert.pem")
docker() {
	printf '%s\n' "$*" >> "$fixture_root/calls"
	case " $* " in
		' ps '*) echo nginxid ;;
		*' certbot/certbot certonly '*)
			cp "$fixture_root/new-cert.pem" "$fixture_root/letsencrypt/live/example.com/fullchain.pem"
			cp "$fixture_root/new-key.pem" "$fixture_root/letsencrypt/live/example.com/privkey.pem" ;;
		*' nginx -t '*) [ "$(hash "$certs/example.com_cert.pem")" = "$before_cert" ] ;;
	esac
}
run example.com
[ "$status" = 1 ]; grep -Fx 'KPANEL_CERTIFICATE failed' "$fixture_root/receipt"
[ "$(hash "$certs/example.com_cert.pem")" = "$before_cert" ]; no_residue
[ "$(grep -c 'nginx -s reload' "$fixture_root/calls")" = 1 ]
printf 'force_renew_rollback=pass\n'

# Custom, foreign, missing and malformed inputs never reach Docker.
reset; touch "$certs/example.com.custom"; run example.com
[ "$status" = 2 ]; grep -Fx 'KPANEL_CERTIFICATE custom' "$fixture_root/receipt"; [ ! -e "$fixture_root/calls" ]
reset foreign; run example.com
[ "$status" = 2 ]; grep -Fx 'KPANEL_CERTIFICATE not_managed' "$fixture_root/receipt"; [ ! -e "$fixture_root/calls" ]
reset; run 10.0.0.1
[ "$status" = 2 ]; grep -Fx 'KPANEL_CERTIFICATE invalid' "$fixture_root/receipt"
run 'bad;domain.com'
[ "$status" = 2 ]; grep -Fx 'KPANEL_CERTIFICATE invalid' "$fixture_root/receipt"
rm "$certs/example.com_key.pem"; run example.com
[ "$status" = 2 ]; grep -Fx 'KPANEL_CERTIFICATE unavailable' "$fixture_root/receipt"; [ ! -e "$fixture_root/calls" ]
printf 'force_renew_guards=pass\n'

# The daily renewal job and replacement transaction share this lock.
reset
exec 8>"$certs/.kpanel-certificate.lock"; flock -x 8
sed -i 's/flock -w 10 9/flock -w 1 9/' "$fixture_root/functions.sh"; source "$fixture_root/functions.sh"
run example.com
flock -u 8
[ "$status" = 5 ]; grep -Fx 'KPANEL_CERTIFICATE busy' "$fixture_root/receipt"; ! grep -F "stop nginx" "$fixture_root/calls"
printf 'force_renew_lock=pass\n'
