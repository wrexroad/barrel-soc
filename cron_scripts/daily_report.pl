#!/usr/bin/perl

use SOC_config qw(%configVals %dsContact);

#turn off output buffering
$|=1;
my $line;
my @payloads, @contacts;
my %data;

#get a list of balloons
open ACTIVE, $configVals{'socNas'}.'/datafiles/enablelist' or die;
while($line = <ACTIVE>){
   chomp $line;
   my @parts = split $line, ';';
   push @payloads, $parts[0];
}
foreach @payloads{
print $_ . "\n";
}
close ACTIVE;


#get the email list

#send the messages
