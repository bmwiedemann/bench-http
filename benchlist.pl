#!/usr/bin/perl -w
use strict;
use LWP::Simple;
my $url = "http://download.opensuse.org/tumbleweed/repo/oss/boot/x86_64/un-fonts.rpm.mirrorlist";
my $ret = system("grep", "-q", 'ID="opensuse-leap"', "/etc/os-release");
if ($ret == 0) { # is Leap
  $url = "http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Media.iso.mirrorlist"
}
my $mirrors = get $url;
my @mirrors = ();
for (split("\n", $mirrors)) {
  m!^\s*<li><a href="([^"]+)"! && $1!~m!\.(meta4|metalink|torrent|magnet)$! && push @mirrors, $1;
}
for my $m (@mirrors) {
  $m =~ s/[^a-zA-Z0-9.:\/_-]/XX/g; #sanitize
  $m =~ s/^https/http/;
  my $bench = `timeout 2m ./bench-one.pl $m`;
  print $bench;
}
