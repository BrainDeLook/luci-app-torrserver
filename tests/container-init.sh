#!/bin/sh
set -eu

mkdir -p /var/lock /var/run
for service in network firewall dnsmasq odhcpd sysntpd; do
	if [ -x "/etc/init.d/$service" ]; then
		"/etc/init.d/$service" disable
	fi
done
exec /sbin/init
