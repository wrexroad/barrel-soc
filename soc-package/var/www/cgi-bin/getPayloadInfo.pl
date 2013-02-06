#!/usr/bin/perl

use SOC_config qw(%payloadLabels %dataTypes);

print "Content-Type: text/html \n\n";

#figure out what job to do
$input = $ENV{'QUERY_STRING'};
@input = split(/&/, $input);
foreach(@input){
	($key,$value)=split(/=/, $_);
	$input{$key}=$value;
}

if($input{"get"} eq "payloads"){
   foreach (sort keys %payloadLabels){ print $_."\n";}
}elsif($input{"get"} eq "var_cats"){
   foreach (sort keys %dataTypes){ print $_."\n";}
}else{
   print "Invalid request.";
}
