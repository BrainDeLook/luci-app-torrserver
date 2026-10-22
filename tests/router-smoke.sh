#!/bin/sh
set -eu

wait_http() {
	local attempt=0
	until wget -q -O /tmp/torrserver-echo http://127.0.0.1:18090/echo; do
		attempt=$((attempt + 1))
		[ "$attempt" -lt 40 ] || { logread -e torrserver; return 1; }
		sleep 2
	done
}

apk update
apk add --allow-untrusted /packages/torrserver-*.apk /packages/luci-app-torrserver-*.apk
test "$(stat -c %a /etc/config/torrserver)" = 600
/usr/bin/torrserver --version | grep -F MatriX.147
ubus -v list luci.torrserver
/usr/libexec/rpcd/luci.torrserver list | jsonfilter -e '@.status'
uci set torrserver.main.ip=127.0.0.1
uci set torrserver.main.port=18090
uci commit torrserver
/etc/init.d/torrserver restart
wait_http
wget -q -O /tmp/torrserver-web http://127.0.0.1:18090/
test -s /tmp/torrserver-web
ubus call luci.torrserver status | jsonfilter -e '@.service.running' | grep -x true
before="$(ubus call luci.torrserver status | jsonfilter -e '@.service.pid')"
test "$before" -gt 0
if tr '\0' '\n' < "/proc/$before/cmdline" | grep -x -- --dontkill; then
	echo 'Service must not ignore SIGTERM' >&2
	exit 1
fi
started="$(date +%s)"
/etc/init.d/torrserver stop
sleep 2
test ! -d "/proc/$before"
test "$(($(date +%s) - started))" -lt 15
/etc/init.d/torrserver start
wait_http
uci set torrserver.main.httpauth=1
uci set torrserver.main.auth_user=smoke
uci set torrserver.main.auth_password='test-"quote\slash'
uci commit torrserver
/etc/init.d/torrserver restart
wait_http
test "$(stat -c %a /opt/torrserver/accs.db)" = 600
test "$(jsonfilter -i /opt/torrserver/accs.db -e '@.smoke')" = 'test-"quote\slash'
if wget -q --post-data='{"action":"list"}' -O /tmp/torrserver-private http://127.0.0.1:18090/torrents; then
	echo 'Protected API accepted an unauthenticated request' >&2
	exit 1
fi
credentials="$(printf '%s' 'smoke:test-"quote\slash' | base64 | tr -d '\n')"
wget -q --header="Authorization: Basic $credentials" --post-data='{"action":"list"}' -O /tmp/torrserver-private http://127.0.0.1:18090/torrents
apk add --allow-untrusted --force-reinstall /packages/torrserver-*.apk
wait_http
wget -q --header="Authorization: Basic $credentials" --post-data='{"action":"list"}' -O /tmp/torrserver-private http://127.0.0.1:18090/torrents
test "$(uci get torrserver.main.port)" = 18090
test -s /opt/torrserver/accs.db
uci set torrserver.main.enabled=0
uci commit torrserver
/etc/init.d/torrserver restart
sleep 2
ubus call luci.torrserver status | jsonfilter -e '@.service.running' | grep -x false
apk del luci-app-torrserver torrserver
test -s /opt/torrserver/accs.db
printf '%s\n' 'PASS: install, API, web UI, RPC, graceful stop, auth, reinstall, config retention, disabled service, removal'
