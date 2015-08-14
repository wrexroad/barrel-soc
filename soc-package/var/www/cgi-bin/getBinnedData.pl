#!/usr/bin/perl

use MongoDB;
use MongoDB::OID;
use SOC_funcs qw(getCgiInput);

print "Content-Type: text/html \n\n";

my %input = %{getCgiInput()};
my $errors = 0;
my $client = MongoDB::MongoClient->new;
my $db = $client->get_database('barrel');

if ($input{'jsonp'}) {
   print $input{'jsonp'}.'(';
}
print '{';

if (
   !%input ||
   !$input{"object"} ||
   !$input{"pktstarttime"} ||
   !$input{"pktendtime"} ||
   !$input{"apid"} ||
   !$input{"mnemonic"}
){
   printError("Missing Arguments");
   $errors++;
} elsif ($input{"binning_factor"} < 0 || $input{"binning_factor"} > 16) {
   printError("Invalid Binning Level");
   $errors++;
} elsif ($input{'pktstarttime'} >= $input{'pktendtime'}) {
   printError("pktstarttime must be less than pktendtime.");
}

if ($errors == 0) {

}

print '}';
if ($input{'jsonp'}) {
   print ')';
}

sub printError {
   print '"meta": {';
   print '"req_id": "'.$input{'req_id'}.'", ';
   print '"object": "'.$input{'object'}.'", ';
   print '"apid": "'.$input{'apid'}.'", ';
   print '"mnemonic": "'.$input{'mnemonic'}.'", ';
   print '"binning_factor": "'.$input{'binning_factor'}.'", ';
   print '"last_insert": "'.$input{'last_insert'}.'", ';
   print '"error": "'.$_[0].'"';
   print '}';
}
