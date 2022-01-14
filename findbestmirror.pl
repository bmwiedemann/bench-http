#!/usr/bin/perl -w
use strict;

my @mirrors=();
while(<>) {
  my @a = split(":");
  my $m = { url=>"$a[0]:$a[1]", reply=>$a[2], RTT=>$a[3], d1=>$a[4], dataspeed=>$a[5], datasize=>$a[6]};
  next unless $m->{datasize} == 10230000;
  push(@mirrors, $m);
}

sub metric($) { $_[0]->{dataspeed} + 2*$_[0]->{d1} + 6*$_[0]->{RTT} }
@mirrors = sort {metric($a) <=> metric($b)} @mirrors;

print "fastest mirrors were:\n";
foreach(@mirrors[0..3]) {
  my $url = $_->{url};
  $url =~ s{distribution/leap/..../iso/.*}{};
  print "RTT=$_->{RTT}s 10M=$_->{dataspeed}s $url\n";
}
