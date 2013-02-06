#!/usr/bin/perl

# fileLister.pl v0.1 12.06.28
# 
# Produces a listing of all data files for a specific payload/date
#

use SOC_config qw(%configVals %dataTypes);
use SOC_funcs qw(getDirListing getCgiInput);

print "Content-Type: text/html \n\n";

if(%input = %{getCgiInput()}){
   my $path = 
      $configVals{"socNas"} . "/" . $input{"payload"} . 
      "/raw/" . $input{"date"} . "/";
   my @listing = getDirListing($path, "file", "pkt");
   
   foreach(@listing){print $_ . "\n";}  
}

1;
