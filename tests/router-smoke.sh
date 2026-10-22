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
printf '%s\n' 'CHECK: package installation and executable version'
apk add --allow-untrusted /packages/torrserver-*.apk /packages/luci-app-torrserver-*.apk
test "$(ls -l /etc/config/torrserver | awk '{print $1}')" = '-rw-------'
/usr/bin/torrserver --version | grep -F MatriX.147
attempt=0
until ubus -v list luci.torrserver > /tmp/torrserver-rpc; do
	attempt=$((attempt + 1))
	[ "$attempt" -lt 20 ] || exit 1
	sleep 1
done
cat /tmp/torrserver-rpc
/usr/libexec/rpcd/luci.torrserver list | jsonfilter -e '@.status'
printf '%s\n' 'CHECK: HTTP API, embedded web UI and rpcd status'
uci set torrserver.main.ip=127.0.0.1
uci set torrserver.main.port=18090
uci commit torrserver
/etc/init.d/torrserver restart
wait_http
wget -q -O /tmp/torrserver-web http://127.0.0.1:18090/
test -s /tmp/torrserver-web
ubus call luci.torrserver status | jsonfilter -e '@.service.running' | grep -x true
before="$(ubus call luci.torrserver status | jsonfilter -e '@.service.pid')"
printf '%s\n' 'CHECK: graceful service stop'
test "$before" -gt 0
if tr '\0' '\n' < "/proc/$before/cmdline" | grep -x -- --dontkill; then
	echo 'Service must not ignore SIGTERM' >&2
	exit 1
fi
started="$(date +%s)"
/etc/init.d/torrserver stop
attempt=0
while [ -d "/proc/$before" ]; do
	attempt=$((attempt + 1))
	[ "$attempt" -lt 14 ] || exit 1
	sleep 1
done
test "$(($(date +%s) - started))" -lt 15
/etc/init.d/torrserver start
wait_http
printf '%s\n' 'CHECK: authentication and credential file permissions'
uci set torrserver.main.httpauth=1
uci set torrserver.main.auth_user=smoke
uci set torrserver.main.auth_password='test-"quote\slash'
uci commit torrserver
/etc/init.d/torrserver restart
wait_http
test "$(ls -l /opt/torrserver/accs.db | awk '{print $1}')" = '-rw-------'
test "$(jsonfilter -i /opt/torrserver/accs.db -e '@.smoke')" = 'test-"quote\slash'
if wget -q --post-data='{"action":"list"}' -O /tmp/torrserver-private http://127.0.0.1:18090/torrents; then
	echo 'Protected API accepted an unauthenticated request' >&2
	exit 1
fi
credentials='c21va2U6dGVzdC0icXVvdGVcc2xhc2g='
wget -q --header="Authorization: Basic $credentials" --post-data='{"action":"list"}' -O /tmp/torrserver-private http://127.0.0.1:18090/torrents
printf '%s\n' 'CHECK: reinstall and configuration retention'
apk add --allow-untrusted --force-reinstall /packages/torrserver-*.apk
wait_http
wget -q --header="Authorization: Basic $credentials" --post-data='{"action":"list"}' -O /tmp/torrserver-private http://127.0.0.1:18090/torrents
test "$(uci get torrserver.main.port)" = 18090
test -s /opt/torrserver/accs.db
uci set torrserver.main.enabled=0
printf '%s\n' 'CHECK: disabled service and package removal'
uci commit torrserver
/etc/init.d/torrserver restart
attempt=0
until [ "$(ubus call luci.torrserver status | jsonfilter -e '@.service.running')" = false ]; do
	attempt=$((attempt + 1))
	[ "$attempt" -lt 14 ] || exit 1
	sleep 1
done
apk del luci-app-torrserver torrserver
test -s /opt/torrserver/accs.db
printf '%s\n' 'PASS: install, API, web UI, RPC, graceful stop, auth, reinstall, config retention, disabled service, removal'
