#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ver="$(cat "$DIR/magisk_version" 2>/dev/null || echo -n 'none')"

if [ "x$1" = "xcanary" ]
then
	nver="canary"
	magisk_link="https://github.com/topjohnwu/magisk-files/raw/${nver}/app-debug.apk"
elif [ "x$1" = "xalpha" ]
then
	nver="alpha"
	magisk_link="https://github.com/vvb2060/magisk_files/raw/${nver}/app-release.apk"
else
	if [ "x$1" = "x" ]; then
		nver="$(curl -s https://github.com/topjohnwu/Magisk/releases | grep -Poe 'Magisk v[\d\.]+' | head -n 1 | cut -d ' ' -f 2)"
	else
		nver="$1"
	fi
	magisk_link="https://github.com/topjohnwu/Magisk/releases/download/${nver}/Magisk-${nver}.apk"
fi

if [ \( -n "$nver" \) -a \( "$nver" != "$ver" \) -o ! \( -f "$DIR/magiskinit" \) -o \( "$nver" = "canary" \) -o \( "$nver" = "alpha" \) ]
then
	echo "Updating Magisk from $ver to $nver"
	curl -s --output "$DIR/magisk.zip" -L "$magisk_link"
	if fgrep 'Not Found' "$DIR/magisk.zip"; then
		curl -s --output "$DIR/magisk.zip" -L "${magisk_link%.apk}.zip"
	fi

	unzip -o "$DIR/magisk.zip" \
		lib/arm64-v8a/libmagiskinit.so \
		lib/arm64-v8a/libmagisk.so \
		lib/arm64-v8a/libinit-ld.so \
		assets/stub.apk \
		-d "$DIR"

	mv -f "$DIR/lib/arm64-v8a/libmagiskinit.so" "$DIR/magiskinit"
	mv -f "$DIR/lib/arm64-v8a/libmagisk.so" "$DIR/magisk"
	mv -f "$DIR/lib/arm64-v8a/libinit-ld.so" "$DIR/init-ld"
	mv -f "$DIR/assets/stub.apk" "$DIR/stub"
	rm -rf "$DIR/lib" "$DIR/assets"

	xz --force --check=crc32 "$DIR/magisk" "$DIR/init-ld" "$DIR/stub"

	echo -n "$nver" > "$DIR/magisk_version"
	rm "$DIR/magisk.zip"
	touch "$DIR/initramfs_list"
else
	echo "Nothing to be done: Magisk version $nver"
fi
