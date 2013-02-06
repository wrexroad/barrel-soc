#!/usr/bin/perl

use SOC_config qw(%configVals %payloadLabels);

print "Content-Type: text/html \n\n";

$input = <STDIN>;

print "No input data!" and die unless ($input);

print "No Way Jose!" and die unless ($configVals{socMode}==1);

print << "BEGCODE";
<html>
<head>
<p>Saving Data....</p>
BEGCODE


#create a list of payload names because they are not passed through the $input variable
$nameList[0]='allPayloads';
@allPayloads=sort(keys(%payloadLabels));
unshift @allPayloads, "Payload";

#change input string into an array with each element being a name and value pair. 
#then name an array and fill with corresponding values. 0 position contains variable name.
@input = split(/&/, $input); 
$n=0;
while ($n<=@input) 
{
	$payloadIndex=0;
	while ($payloadIndex<$configVals{numOfPayloads})
	{
		
		$varNum=($n+1)/20;
		($varName,$varValue)=split(/=/, $input[$n]); 
		${"$varName"}[0]=$varName if($payloadIndex==0);
		${"$varName"}[($payloadIndex+1)]=$varValue;
		$nameList[$varNum+1]=$varName;
		$payloadIndex++;
		$n++;
	}
}


#rewrite config file
open(OUTPUT, ">$configVals{socNas}/datafiles/".$submit[1]."Config") or print "Can't open $configVals{socNas}/datafiles/".$submit[1]."Config for editing..." and die;

$rowNum=0;
while ($rowNum<=20)
{
	$colNum=0;
	while($colNum<=@nameList)
	{
		print OUTPUT ${"@nameList[$colNum]"}[$rowNum], ",";
		$colNum++;
	}
	print OUTPUT "\n";
	$rowNum++;
}

	print << "ENDCODE";
	<meta http-equiv="refresh" content="0;url=@submit[1]config.pl"
	</head>
	</html>
ENDCODE
