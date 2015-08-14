#!/usr/bin/perl

use MongoDB;
use MongoDB::OID;
use SOC_funcs qw(getCgiInput);

print "Content-Type: text/html \n\n";

my %input = %{getCgiInput()};
my @errors = ();
my $client = MongoDB::MongoClient->new;
my $db = $client->get_database('barrel');
my $collectionName, $collection;

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
   push @errors, "Missing Arguments";
} 
if ($input{"binning_factor"} < 0 || $input{"binning_factor"} > 16) {
   push @errors, "Invalid Binning Level";
} 
if ($input{'pktstarttime'} >= $input{'pktendtime'}) {
   push @errors, "pktstarttime must be less than pktendtime.";
}

$collectionName = $input{'apid'}.$input{'object'};
if ($input{'binning_factor'}) {
   $collectionName .= '.'.$input{'binning_factor'};
}
$collection = $db->get_collection($collectionName);
if (!$collection) {
  push @errors, "Could not open database for " . $collectionName;
}

if (@errors == 0) {
   printData();
}
printMetadata();

print '}';
if ($input{'jsonp'}) {
   print ')';
}

sub printData {
   my $cursor = $collection->find();
   my @timeStamps = ();
   my @data = ();
   while (my $doc = $cursor->next){ 
      push @timeStamps, ${$doc}{'_id'};
      push @data, ${$doc}{$input{'mnemonic'}};
   }
   print '"data" : [';
   print '"["' . join('", "', @timeStamps) . '"], ';
   print '"["' . join('", "', @data) . '"]';
   print '],';
}

sub printMetadata {
   print '"meta": {';
   print '"req_id": "'.$input{'req_id'}.'", ';
   print '"object": "'.$input{'object'}.'", ';
   print '"apid": "'.$input{'apid'}.'", ';
   print '"mnemonic": "'.$input{'mnemonic'}.'", ';
   print '"binning_factor": "'.$input{'binning_factor'}.'", ';
   print '"last_insert": "'.$input{'last_insert'}.'"';
   if (@errors) {
      printErrors();
   }
   print '}';
}

sub printErrors {
   my $errorString = @errors > 1 ?
      '["' . join('", "', @errors). '"]':
      '"' . $errors[0] . '"';
   
   print ', "error": "' . $errorString . '"';
}
