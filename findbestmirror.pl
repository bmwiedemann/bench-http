#!/usr/bin/perl -w
use strict;
our $debug = 1;
our $updaterepos = 1;

my @mirrors=();
while(<>) {
  my @a = split(":");
  my $m = { url=>"$a[0]:$a[1]", reply=>$a[2], RTT=>$a[3], d1=>$a[4], dataspeed=>$a[5], datasize=>$a[6]};
  $m->{url} =~ s{distribution/leap/..../iso/.*}{};
  $m->{url} =~ s{tumbleweed/iso/.*}{};
  $m->{url} =~ s{tumbleweed/repo/oss/.*}{};
  $m->{url} =~ s{^https}{http};
  next unless $m->{datasize} == 10230000;
  push(@mirrors, $m);
}

sub metric($) { $_[0]->{dataspeed} + 2*$_[0]->{d1} + 6*$_[0]->{RTT} }
@mirrors = sort {metric($a) <=> metric($b)} @mirrors;

print "fastest mirrors were:\n";
foreach(@mirrors[0..3]) {
  print "RTT=$_->{RTT}s 10M=$_->{dataspeed}s $_->{url}\n";
}
my $besturl=$mirrors[0]->{url};

print "apply best mirror\n" if $updaterepos;
REPO:
for my $repo (</etc/zypp/repos.d/*.repo>) {
  open(my $fd, "<", $repo) or die "could not read $repo: $!";
  my @lines = <$fd>;
  close($fd);
  my $changed = 0;
  for(my $li=$#lines; $li>=0; $li--) {
    my $l = $lines[$li];
    if($l=~m{^baseurl=http.?://download.opensuse.org/(.*)}) {
      my $newline = "baseurl=$besturl$1\n";
      if($l !~ m{/repositories/} and $lines[$li-1] !~ /^baseurl=/) {
        splice(@lines, $li, 0, $newline);
        $changed = 1;
      }
    }
    if($l =~ /^enabled=0$/) {
      next REPO;
    }
  }
  next unless $changed;
  print "\n>$repo:\n", @lines if $debug;
  if($updaterepos) {
    open($fd, ">", $repo) or die "could not write $repo: $!";
    print $fd @lines;
    close $fd;
  }
}
