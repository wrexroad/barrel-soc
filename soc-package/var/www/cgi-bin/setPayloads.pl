#!/usr/bin/perl

use SOC_config qw(%payloadLabels %configVals);
use SOC_funcs qw(getCgiInput);

print "Content-Type: text/html \n\n";

#Get all the payload names in a sorted array
my @allPayloads=sort(keys(%payloadLabels));

if($ENV{'QUERY_STRING'}){
   #if input was found, break it into a hash and write a new enablelist
   my $inputref=getCgiInput();
   
   open ENABLES, ">$configVals{socNas}/datafiles/enablelist.new" or print "Could not open ".$configVals{"socNas"}."/datafiles/enablelist.new for writing\n" and die;
   for (my $pay_i=0; $pay_i < scalar @allPayloads; $pay_i++){
      if(${$inputref}{$allPayloads[$pay_i]} eq "on"){print ENABLES "1\n";}
      else{print ${$inputreg}{$allPayloads[$pay_i]};print ENABLES "0\n";}
   }
   close ENABLES;
}

#read enablelist
my @enables=();
open ENABLES,$configVals{"socNas"}."/datafiles/enablelist.new" or print "Could not open ".$configVals{"socNas"}."/datafiles/enablelist.new\n" and die;
while(my $line = <ENABLES>){
   chomp $line;
   push @enables, $line;
}
close ENABLES;

#generate code for 
my $payCode="";
for($pay_i=0; $pay_i<scalar @allPayloads; $pay_i++){
   $payCode=$payCode.$allPayloads[$pay_i].'<input type="checkbox" name="'.$allPayloads[$pay_i].'"';
   if($enables[$pay_i] eq "1"){$payCode=$payCode." checked ";}
   $payCode=$payCode.' />'."\n";
}

print << "HTML";
<!DOCTYPE html>
<html>
<head>
</head>
<body>
   <h1>Select Active Payloads</h1>
   <form method="get" action="/cgi-bin/setPayloads.pl">
      $payCode
      <input type="submit" />
   </form
</body>
</html>
HTML

1;