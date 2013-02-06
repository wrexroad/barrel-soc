#!/usr/bin/perl

use SOC_config qw(%configVals %payloadLabels);

@allPayloads=sort(keys(%payloadLabels));

print "Content-Type: text/html \n\n";

open(CONFIG,"$configVals{socNas}/datafiles/tempConfig") or print "Can't open configuration file at $configVals{socNas}/datafiles/tempConfig \n" and die;
$i=0;
while($line=<CONFIG>)
{		
	chop($line);
	(@holder)=split(/,/,$line);
	$n=0;
	while ($n<28)
	{
		@{"var$n"}[$i] = @holder[$n];
		$n++;
	}
	$i++;
}

if($configVals{socMode}==1){
print << "BEGCODE1";
	<html>
	<head><title>BARREL Balloon Configuration</title></head>
	<body>
	<center><h1>Temerature Warning Configurator</h1></center>
	<form  action="configwriter.pl" method="post">
	<table cellpadding=0 border=1>
	<tr>
BEGCODE1
}
else{
print << "BEGCODE";
	<html>
	<head><title>BARREL Balloon Configuration</title></head>
	<body>
	<center><h1>Temerature Warning Configurator</h1></center>
	<form>
	<table cellpadding=0 border=1>
	<tr>
BEGCODE
}

$varNum=0;
while($varNum<=27) #cycle through 27 data columns
{
	$payloadIndex=0;
	print "<td>&nbsp</td>" if $varNum==0 or $varNum==27;
	print "<td><b><font size=2>",@{"var$varNum"}[0],"</font></b></td>" if $varNum>0 and $varNum<27;
	$payloadIndex++;
	while($payloadIndex<=20) #cycle through 20 balloons
	{
		print "<td><center><font size=2><b>Balloon $allPayloads[$payloadIndex-1]</font></b></center></td>" if $varNum==0 or $varNum==27;
		
		print "<td><center><input type=text name=",@{"var$varNum"}[0]," size=3 value=",@{"var$varNum"}[$payloadIndex]," /></font></center></td>" if $varNum>0 and $varNum<27;
		$payloadIndex++;
	}
	print "<td><b><font size=2>",@{"var$varNum"}[0],"</font></b></td>" if $varNum>0 and $varNum<27;
	print "<td>&nbsp</td>" if $varNum==0 or $varNum==27;
	print "</tr><tr>";
	print "<td colspan=22><hr size=0.5 /><td></tr><tr>" if $varNum==0 or $varNum==2 or $varNum==4 or $varNum==6 or $varNum==8 or $varNum==10 or $varNum==12 or $varNum==14  or $varNum==16 or $varNum==18 or $varNum==20 or $varNum==22 or $varNum==24;
	$varNum++;
}
	print << "ENDTABLE";
	</tr>
	</table>
ENDTABLE
	
	print '<button type="submit" name="submit" value="temp">Submit</button>' if $configVals{socMode}==1;
		
	print << "ENDCODE";
	</form>
	</body>
	</html>
ENDCODE
