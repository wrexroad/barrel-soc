#!/usr/bin/perl

use SOC_config qw(%dsContact %configVals);

print "Content-Type: text/html \n\n";

if($ENV{'QUERY_STRING'} ne ""){
   setActive();
}
printPage();


sub setActive{
   
   my @input = split /&/, $ENV{'QUERY_STRING'};

   open DS, ">" . $configVals{"socNas"} . "/datafiles/dsContact" or
   print "Could not write to DS contact list - " . $! and die;
   foreach(@input){
      my @temp = split /=/, $_;
      
      if($temp[0] ne "submit"){
         print DS $temp[0] . "\n";
      }
   }
   close DS;
}

sub getActive{
   my %list = ();
   
   open DS, "<" . $configVals{"socNas"} . "/datafiles/dsContact" or
   print "Could not read DS contact list - " . $! and die;
   while(my $line = <DS>){
      chomp $line;
      $list{$line} = 1;
   }
   close DS;
   return \%list;
}


sub printPage{
   my $active = getActive();
   
   print '<!DOCTYPE html>'."\n";
   print '<html>'."\n";
   print '<head><title>Duty Scientist Activation</title></head>'."\n";
   print '<body>'."\n";
   print '  <form method="get" action="/cgi-bin/setDS.pl">'."\n";
   
   foreach my $name (sort keys %dsContact){
      print '     <input ';
      print 'type="checkbox" ';
      if(${$active}{$name} == 1){print ' checked ';}
      print 'name="' . $name . '"';
      print '> ' . $name . '<br />'."\n"
   }
   print '     <input type="submit" name="submit">'."\n";
   print '  </form>'."\n";
   print '</body>'."\n";
   print '</html>'."\n";
}

