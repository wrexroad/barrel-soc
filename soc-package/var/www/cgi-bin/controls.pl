#!/usr/bin/perl

use SOC_config qw(%configVals %payloadLabels @sciVars @tempVars @voltVars @currentVars);
use SOC_funcs qw(getEnabledPayloads);

print "Content-Type: text/html \n\n";
$input = $ENV{'QUERY_STRING'};
@input = split(/&/, $input); 
($null,$payNum) = split(/=/,$input[0]);
($null,$errorName) = split(/=/,$input[1]);

@allPayloads=sort(keys(%payloadLabels));

print<<"BEGCODE";
<html>
<head>

<BASE Target="graphsFrame">

<script language="javascript">
BEGCODE

#build some javaScript arrays
print "var varLabels = new Array(";

my @varLabels = (@sciVars,@tempVars,@voltVars,@currentVars);
foreach(@varLabels){print "\'$_\',";}
print "\'\');\n";
print "varLabels.pop();";

print "var payloads = new Array(";
foreach(@allPayloads){print "\'$_\',";}
print "\'\');\n";
print "payloads.pop();";

print << "JSFUNCTIONS";
function checkBrowser(){
	if (navigator.userAgent.indexOf("MSIE")!=-1){document.getElementById("form").action="graphHolder.pl";}
	else{document.getElementById("form").action="grapher.pl";}
}

function writeCookie() {
	var date = new Date();
	date.setTime(date.getTime()+(365*24*60*60*1000));
	var expires = "; expires="+date.toGMTString();
	
	var saves = new Array();

	for(var i=0;i < varLabels.length;i++) {
	
		for(var j=0;j < payloads.length;j++) {
			var labelId=varLabels[i]+payloads[j];
			var labelElement = document.getElementById(labelId);	
			if(labelElement && labelElement.checked) saves.push(labelId);
		}
	}
	saves=saves.join(",");
	document.cookie = "dataTypes="+saves+expires+"; path=/";
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function setGraphs() {
	var settings = readCookie('dataTypes');
	if (settings)
	{
		settings = settings.split(",");
		for(var i=0;i < settings.length;i++) {
			var checkBox=document.getElementById(settings[i]);
			if (checkBox != null) checkBox.checked=true;
		}
	}
}

function checkAll(payload) {
	if(document.getElementById("checkAll"+payload).checked) {
		for(var i=2;i < varLabels.length;i++) {
			labelId=varLabels[i]+payload;
			document.getElementById(labelId).checked=true;
		}
	}
	else {
		for(var i=2;i < varLabels.length;i++) {
			labelId=varLabels[i]+payload;
			document.getElementById(labelId).checked=false;
		}
	}
}

</script>
</head>
JSFUNCTIONS

print << "BODYCODE";
<body onLoad="checkBrowser();setGraphs();">

<form id="form" name="input" action="grapher.pl" method="get">

<div id=hiddenControls' style='display:none'>
	<INPUT id="yLimOn" type="radio" name="Limits" value="yes" checked /> 
	<INPUT id="yLimOff" type="radio" name="Limits" value="no" />
	<INPUT id="1Hour" type="radio" name="GraphLength" checked value="3600" />
	<INPUT id="6Hour" type="radio" name="GraphLength"  value="21600" />
	<INPUT id="24Hour" type="radio" name="GraphLength" value="86400" />
	<INPUT id="xTime" type="radio" name="xAxis" checked value="Time" />
	<INPUT id="xFrame" type="radio" name="xAxis" value="Frames"/>
	<input type="submit" value="Generate Plots" />
</div>

<table border=0>
<tr><td></td>
BODYCODE

@enabledPayloads=getEnabledPayloads();

$i=0;
while($i<@enabledPayloads)
{
	print "<td>$enabledPayloads[$i]</td>";
	$i++;
}
print "</tr>";

print "<tr><td><b>Check All</b></td>";
$i=0;
while($i<@enabledPayloads)
{
	print "<td><input onClick=checkAll(\"$enabledPayloads[$i]\"); type=checkbox id=checkAll$enabledPayloads[$i] /></td>";
	$i++;
}
print "</tr>";

$i=2;
while($i<@varLabels)
{
	print "<td>$varLabels[$i]</td>";
	$j=0;
	while($j<@enabledPayloads) 
	{
		print "<td><input type=checkbox id=".$varLabels[$i].$enabledPayloads[$j]." name=$varLabels[$i] value=$enabledPayloads[$j] /></td>";
		$j++;
	}
	print "</tr>";
	$i++;
}

print "<tr><td></td>";
$i=0;
while($i<@enabledPayloads)
{
	print "<td>$enabledPayloads[$i]</td>";
	$i++;
}
print "</tr>";

print<<"ENDCODE";
		</table>
</form>
</body>
</html>
ENDCODE


__END__

=pod
CHANGES:
Now uses SOC.pm for config values
changed @payloads to @enabledPayloads
uses @allPayloads from SOC.pm for payload names
grabs variable lables from arrays in SOC.pm 
=cut
