#!/bin/sh
set -eu

output=''
url=''
while [ "$#" -gt 0 ]; do
	case "$1" in
		-T) shift ;;
		--header=*) ;;
		-O) shift; output="$1" ;;
		https://*) url="$1" ;;
		*) exit 2 ;;
	esac
	shift
done
[ -n "$output" ] && [ -n "$url" ]
printf '%s\n' "$url" >> "$FETCH_TRACE"
[ "$FETCH_MODE" != fail ] || exit 7
case "$url" in
	https://api.github.com/*)
		[ "$FETCH_MODE" != fallback ] || exit 7
		case "$url" in
			*/releases/tags/v147-r2)
				printf '%s\n' '{"tag_name":"v147-r2","assets":[{"id":1,"name":"SHA256SUMS"},{"id":2,"name":"torrserver-147-r2.apk"},{"id":3,"name":"luci-app-torrserver-3.0.0-r2.apk"}]}' > "$output" ;;
			*/releases/assets/1) cp /packages/SHA256SUMS "$output" ;;
			*/releases/assets/2) cp /packages/torrserver-147-r2.apk "$output" ;;
			*/releases/assets/3) cp /packages/luci-app-torrserver-3.0.0-r2.apk "$output" ;;
			*) exit 2 ;;
		esac ;;
	https://github.com/BrainDeLook/luci-app-torrserver/releases/download/v147-r2/*)
		[ "$FETCH_MODE" = fallback ] || exit 7
		cp "/packages/${url##*/}" "$output" ;;
	*) exit 2 ;;
esac
