#!/usr/bin/perl

use SOC_config qw(%configVals @payloads);

print "Content-Type: text/html \n\n";
#parse user input
my @input = split "=", $ENV{'QUERY_STRING'};

#we should only accept one key/value pair for input
if(@input > 2){print "Invalid input...\n";}

#get the list of currently ignored payloads
open IGNORE, $configVals{'socNas'} . "/datafiles/ignoredPayloads";
   my $ignored = <IGNORE>;
   chomp $ignored;
close IGNORE;

   #either add to or subtract from ignore list 
   if(@input == 2){
      if($input[1] eq "1"){ #adding payload to the ignore list
         $ignored .= $input[0] . ",";
      }
      elsif($input[1] eq "0"){ #remove payload from the ignore list
         #remove payload
         $ignored =~ s/($input[0])//g;
         #remove extra commas
         $ignored =~ s/,,/,/g;
      }
      

      open IGNORE, ">" . $configVals{'socNas'} . "/datafiles/ignoredPayloads";
         print IGNORE $ignored . "\n";
      close IGNORE;
   }

close IGNORE;

chomp($ignored);

#print the HTML document
print q(
   <!doctype html>
   <html>
      <head>
         <title>
            Disable Payload Alerts
         </title>
      </head>
      <body>
      Disable alerts for the following payloads:
      <br />
);     

foreach (@payloads){
   print $_ . '<input type="checkbox" name="' . $_ . '"';
   if($ignored =~ /($_)/){ print " checked ";}
   print 'onchange="setunset(this)"';
   print ' />' . "\n" . '<br />' . "\n";
}

print q(
      <script>
         function setunset(payload){
            var checked = payload.checked ? 1 : 0;
            var url = window.location.toString().split("?");
            window.location =
               url[0] + "?" + payload.name + "=" + checked;
         }
      </script>
      </body>
   </html>
);
