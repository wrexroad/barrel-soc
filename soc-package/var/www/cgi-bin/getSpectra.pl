#!/usr/bin/perl

use SOC_config qw(%configVals @slowSpectraWidths @medSpectraWidths);

print "Content-Type: text/html \n\n";

my $input="";
my @input=();
my %input=();
my $key="";
my $value="";
my $linesInFile=0;
my $line_i=0;
my @data=();
my $bin_i=0;
my $binSum=0;
my $output="";
my $null="";
my @aveBinVals=();
my @labels=();
my $label_i=0;
my $numOfBins=0;
my $medSpecOffset=42;
my $totalLines=0;

#figure out what job to do
$input = $ENV{'QUERY_STRING'};
@input = split(/&/, $input);
foreach(@input){
	($key,$value)=split(/=/, $_);
	$input{$key}=$value;
}

#create title line
$output="FrameGroup";
if($input{'type'} eq 'slow'){
	$numOfBins=256;
	$labels[0]=$slowSpectraWidths[0]*$input{'energyCal'};
	$output=$output.",".$labels[0];
	for($label_i=1; $label_i<$numOfBins; $label_i++){
		$labels[$label_i]=sprintf("%d",$labels[$label_i-1]+($slowSpectraWidths[$label_i]*$input{'energyCal'}));
		$output=$output.",".$labels[$label_i];
	}
}
else{
	$numOfBins=48;
	$labels[0]=($medSpecOffset+$slowSpectraWidths[0])*$input{'energyCal'};
	$output=$output.",".$labels[0];
	for($label_i=1; $label_i<$numOfBins; $label_i++){
		$labels[$label_i]=sprintf("%d",$labels[$label_i-1]+(($medSpectraWidths[$label_i])*$input{'energyCal'}));
		$output=$output.",".$labels[$label_i];
	}
}
$output=$output."\n";

#open spectra data file
open DATA, "<".$configVals{'socNas'}.'/payload'.$input{'payload'}.'/.'.$input{'type'}.'spec'.$input{'date'};

#skip the title line
<DATA>;

#count the number of lines in the file
$linesInFile=0;
while($null=<DATA>){$linesInFile++;}

#move the file pointer to the start of the needed lines
seek DATA,0,0;
<DATA>; #skip the line of labels
for($line_i=0; $line_i<($linesInFile-$input{'numOfLines'}); $line_i++){<DATA>;}

#get the needed number of lines from the end of the file
$line_i=0;
while($line=<DATA>){
	chomp $line;
	@{$data[$line_i]}=split /,/,$line;
	$line_i++;	
}
$totalLines=$line_i; #save the total number of lines to use in the average

#start the output string with the frame group
$output=$output.$data[0][0];

#average all the gathered lines together
#start at bin_i=1 because bin_0 is the frame group
$binSum=0;
for($bin_i=1; $bin_i<scalar(@{$data[0]}); $bin_i++){
	for($line_i=0; $line_i<scalar(@data); $line_i++){
		$binSum+=$data[$line_i][$bin_i];
	}
	push @aveBinVals,($binSum/$totalLines);
	$binSum=0;
}

#clear the @data array
@data=();

#correct all the values for the bin width (channels/bin) and average over the collection interval (32sec for slow / 4sec for med)
if($input{'type'} eq 'slow'){
	for($bin_i=0; $bin_i<scalar(@aveBinVals); $bin_i++){
		$output = $output.','.$input{'countMultiplier'}*$aveBinVals[$bin_i]/($slowSpectraWidths[$bin_i]*32);
	}
}else{
	for($bin_i=0; $bin_i<scalar(@aveBinVals); $bin_i++){
		$output = $output.','.$input{'countMultiplier'}*$aveBinVals[$bin_i]/($medSpectraWidths[$bin_i]*4);
	}
}

print $output."\n";

1;	