#!/bin/sh
mirrors=$(curl http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Media.iso.mirrorlist|perl -ne 'm!^\s*<li><a href="([^"]+)"! && $1!~m!\.(meta4|metalink|torrent|magnet)$! && print "$1\n"')

for m in $mirrors ; do
    timeout 2m ./bench-one.pl $m
done
