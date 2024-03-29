#!/usr/bin/perl -w
use strict;
use IO::Socket::INET6;
use Time::HiRes qw(gettimeofday tv_interval);
my $maxrtt = $ENV{MAXRTT} || 4;

my $url = shift; #"http://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-2-NET-aarch64-Current.iso.sha256.mirrorlist";
#my $url = "http://opensuse.mirrors.theom.nz/distribution/leap/15.3/iso/openSUSE-Leap-15.3-2-DVD-aarch64-Build24.5-Media.iso.sha256";
$url=~m!^http(?:s)?://([^/]+)(.*)! or die "URL parser error: $url";
my $host = $1; #"download.opensuse.org";
my $port = 80;
my $resource = $2; #'/distribution/leap/15.3/iso/openSUSE-Leap-15.3-2-DVD-aarch64-Build24.5-Media.iso.sha256';
my $tcpto = 3;

my @t;
push(@t, [gettimeofday()]);
my $sock = new IO::Socket::INET(
                PeerAddr => "$host",
                PeerPort => "$port",
                Timeout  => "$tcpto",
                Proto    => "tcp",
            );
push(@t, [gettimeofday()]);
die "$url connection failed" unless $sock;
my $rtt = tv_interval($t[0], $t[1]);
if($rtt > $maxrtt) {
  die "skipped $url because of slow RTT=$rtt > $maxrtt";
}

my $req =
    "GET $resource HTTP/1.1\r\n"
   ."Host: $host\r\n"
   ."Range: bytes=0-10230000\r\n"
   ."\r\n";

print $sock $req;
my $reply = <$sock>;
$reply=~s/\r?\n//;
push(@t, [gettimeofday()]);
my $data;
read($sock, $data, 10230000);
push(@t, [gettimeofday()]);
print $url, ":", $reply, ":", $rtt, ":", tv_interval($t[1], $t[2]), ":", tv_interval($t[0], $t[3]), ":", length($data), "\n";
