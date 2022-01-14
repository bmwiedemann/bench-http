#!/bin/sh
url=http://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso.mirrorlist
# fonts file does not get updated as often, so more mirrors will be considered, which might be good or bad
url=http://download.opensuse.org/tumbleweed/repo/oss/boot/x86_64/un-fonts.rpm.mirrorlist
if grep -q 'ID="opensuse-leap"' /etc/os-release ; then
    url=http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Media.iso.mirrorlist
fi
mirrors=$(curl $url|perl -ne 'm!^\s*<li><a href="([^"]+)"! && $1!~m!\.(meta4|metalink|torrent|magnet)$! && print "$1\n"')

for m in $mirrors ; do
    timeout 2m ./bench-one.pl $m
done
