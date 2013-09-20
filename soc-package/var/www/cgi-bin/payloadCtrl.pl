#!/usr/bin/perl

use SOC_config qw(%configVals);
use SOC_funcs qw(getDirListing);

print "Content-Type: text/html \n\n";

my $input = "";
my @input = ();
my %input = ();
my $key = "";
my $value = "";
my $list = "";
my @list = ();
my @line = ();
my @dates = ();
my $dates = "";

#figure out what job to do
$input = $ENV{'QUERY_STRING'};
@input = split(/&/, $input);
foreach(@input){
	($key,$value)=split(/=/, $_);
	$input{$key}=$value;
}

if(!$input{"command"}){
   print "No Command Specified!\n" and die;
   
}elsif($input{"command"} eq "fetch"){
   my @temp;
   my $site = "---";
   
   #search for a line indicating the payload status
   open LIST, "<" . $configVals{'socNas'} . "/datafiles/enablelist";
   while(my $line = <LIST>){
      @temp = split(";", $line);
      if($temp[0] eq $input{"payload"}){
         $site = $temp[1];
         break;
      }
   }
   close LIST;
   
   @dates = 
      getDirListing(
         $configVals{'mocNas'} . "/payload" . $input{'payload'} . "/","dir"
      );
   
   if($site ne "---"){
      print 'fetch!!on!!' . $site . "!!@dates\n";
   }else{
      print 'fetch!!off!!' . $site . "!!@dates\n";
   }
   
}elsif($input{"command"} eq "start"){
   my %list;
   my @sortedKeys;
   
   #read list of currently running payloads
   open LIST, "<" . $configVals{'socNas'} . "/datafiles/enablelist";
   while(my $line = <LIST>){
      @temp = split ";", $line;
      $list{$temp[0]} = $temp[1];
   }
   close LIST;
   
   #add the new payload to list
   $list{$input{'payload'}} = $input{'site'};
   
   #sort the list and write it back to the file
   my @sortedKeys = sort keys %list;
   open LIST, ">" . $configVals{'socNas'} . "/datafiles/enablelist";
   for(my $key_i = 0; $key_i < @sortedKeys; $key_i++){
      print LIST $sortedKeys[$key_i].";".$list{$sortedKeys[$key_i]}."\n";
   }
   close LIST;
   
   #start the payload
   `nohup perl updater.pl payload=$input{payload} startdate=$input{startdate} mod40_Offset=$input{mod40_Offset} > $configVals{socNas}/payload$input{payload}/.sysout 2> $configVals{socNas}/payload$input{payload}/.sysout < /dev/null &`;
   print "started!!\n";
   
}elsif($input{"command"} eq "stop"){
   my %list;
   my @sortedKeys;
   
   #read list of currently running payloads
   open LIST, "<" . $configVals{'socNas'} . "/datafiles/enablelist";
   while(my $line = <LIST>){
      @temp = split ";", $line;
      $list{$temp[0]} = $temp[1];
   }
   close LIST;
   
   #sort the list and write it back to the file without the stopped payload
   @sortedKeys = sort keys %list;
   open LIST, ">" . $configVals{'socNas'} . "/datafiles/enablelist";
   for(my $key_i = 0; $key_i < @sortedKeys; $key_i++){
      unless($sortedKeys[$key_i] eq $input{'payload'}){
         print LIST $sortedKeys[$key_i].";".$list{$sortedKeys[$key_i]}."\n";
      }
   }
   close LIST;
   
   #kill the payload process	
   $list=`ps aux | grep \"payload=$input{payload}\"`;
   @list=split(/\n/,$list);
   foreach(@list){
      @line=split(/\s+/,$_);
      `kill $line[1]`;
   }
   print "stopped!!\n";
}
