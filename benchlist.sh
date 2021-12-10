#!/bin/sh
mirrors=$(curl http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-2-DVD-aarch64-Build24.5-Media.iso.mirrorlist|perl -ne 'm!^\s*<li><a href="([^"]+)"! && $1!~m!\.(meta4|metalink|torrent|magnet)$! && print "$1\n"')

for m in $mirrors ; do ./bench-one.pl $m ; done
