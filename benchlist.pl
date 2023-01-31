#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;
use LWP::Simple;
use Time::HiRes qw(gettimeofday tv_interval);
use WWW::Curl::Easy;
use WWW::Curl::Multi;

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
my @rtts = ();
my $curl_id = 1;
my $active_handles = 0;
my @body;
my %easy;
my $curlm = WWW::Curl::Multi->new;
for my $m (@mirrors) {
    $m =~ s/[^a-zA-Z0-9.:\/_-]/XX/g; #sanitize
    $m =~ s/^https/http/;
    #print "add $m\n";
    my $curl = WWW::Curl::Easy->new;
    $easy{$curl_id} = $curl;
    $curl->setopt(CURLOPT_PRIVATE,$curl_id);
    $curl->setopt(CURLOPT_URL, $m);
    $curl->setopt(CURLOPT_HEADER, 1);
    $curl->setopt(CURLOPT_NOBODY, 1);
    #$curl->setopt(CURLOPT_SHARE, $curlsh);
    $curl->setopt(CURLOPT_TIMEOUT_MS, 500);
    # Add an easy handle
    $curlm->add_handle($curl);
    my $response_body;
    $curl->setopt(CURLOPT_WRITEDATA,\$response_body);
    push(@body, \$response_body);
    $active_handles++;
    $curl_id++;
}


my @fastmirrors;
# launch parallel requests
alarm(5);
my $t0 = [gettimeofday];
while ($active_handles && @fastmirrors < 30) {
        my $active_transfers = $curlm->perform;
        if ($active_transfers != $active_handles) {
                while (my ($id,$return_value) = $curlm->info_read) {
                        if ($id) {
                                $active_handles--;
                                my $actual_easy_handle = $easy{$id};
                                # do the usual result/error checking routine here
                                my $elapsed = tv_interval ( $t0 );
                                #print "XXX $id $mirrors[$id-1] $return_value $active_handles $elapsed\n";
                                push(@fastmirrors, {url=>$mirrors[$id-1], time2=>$elapsed});
                                # letting the curl handle get garbage collected, or we leak memory.
                                delete $easy{$id};
                        }
                }
        }
}
alarm 0;
foreach my $m (@fastmirrors) {
    #print "$m->{url}:$m->{time2}\n";
    my $bench = `timeout 2m $FindBin::Bin/bench-one.pl $m->{url}`;
    print $bench;
}
