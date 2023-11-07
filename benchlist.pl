#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;
use LWP::Simple;
use Time::HiRes qw(gettimeofday tv_interval);
use Net::Curl::Easy qw(:constants);
use Net::Curl::Multi;

my $url = "http://download.opensuse.org/tumbleweed/repo/oss/boot/x86_64/un-fonts.rpm.mirrorlist";
my $ret = system("grep", "-q", 'ID="opensuse-leap"', "/etc/os-release");
if ($ret == 0) { # is Leap
  $url = "https://download.opensuse.org/distribution/leap/15.4/iso/openSUSE-Leap-15.4-NET-x86_64-Build243.2-Media.iso.mirrorlist"
}
my $mirrors = get $url;
my @mirrors = ();
for (split("\n", $mirrors)) {
  m!^\s*<li><a href="([^"]+)"! && $1!~m!\.(meta4|metalink|torrent|magnet)$! && push @mirrors, $1;
}
my $active_handles = 0;
my $curlm = Net::Curl::Multi->new;
for my $m (@mirrors) {
    $m =~ s/[^a-zA-Z0-9.:\/_-]/XX/g; #sanitize
    if($m=~/(fedora.md)|(karneval.cz)|(opensuse.id)|(opensuse.ic.ufmt.br)|(opensuse.unc.edu.ar)|(mirror.isoc.org.il)/) {
        $m =~ s/^http/https/;
    } else { $m =~ s/^https/http/ }
    my $curl = Net::Curl::Easy->new([$m]);
    $curl->setopt(CURLOPT_URL, $m);
    $curl->setopt(CURLOPT_HEADER, 1);
    $curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
    $curl->setopt(CURLOPT_NOBODY, 1);
    #$curl->setopt(CURLOPT_SHARE, $curlsh);
    $curl->setopt(CURLOPT_TIMEOUT_MS, 900);
    $curl->setopt(CURLOPT_WRITEDATA, [$m]);
    $curl->setopt(CURLOPT_WRITEFUNCTION, \&callback_write);
    # Add an easy handle to Multi
    $curlm->add_handle($curl);
    $active_handles++;
}

my @fastmirrors;
# launch parallel requests
alarm(9);
my $t0 = [gettimeofday];

sub callback_write
{   my($easy, $httpdata, $writedata) = @_;
    if($httpdata =~ /200 OK/) {
        my $elapsed = tv_interval ( $t0 );
        push(@fastmirrors, {url=>$writedata->[0], time2=>$elapsed});
    }
    return length $httpdata;
}

while ($active_handles && @fastmirrors < 30) {

        my $active_transfers = $curlm->perform;
        while (my ( $msg, $easy, $result ) = $curlm->info_read) {
                $curlm->remove_handle($easy);
                $active_handles--;
        }
}
alarm 0;
foreach my $m (@fastmirrors) {
    #print "$m->{url}:$m->{time2}\n";
    my $bench = `timeout 2m $FindBin::Bin/bench-one.pl $m->{url}`;
    print $bench;
}
