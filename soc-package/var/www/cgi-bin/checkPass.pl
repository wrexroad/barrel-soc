#!/usr/bin/perl
use SOC_config qw(%configVals);

print "Content-Type: text/html \n\n";

if ($ENV{'QUERY_STRING'} eq "pass=".$configVals{"adminPass"}){
print << "HTML";
<div id="nav">
   <input type="button" value="Start/Stop Payloads" onclick='document.getElementById("content").src="/payloadCtrl.html";' />
   <input type="button" value="Active Payloads" onclick='document.getElementById("content").src="/cgi-bin/setPayloads.pl";' />
   <input type="button" value="General Configurator" onclick='document.getElementById("content").src="/cgi-bin/genconfig.pl";' />
   <input type="button" value="Voltage Configurator" onclick='document.getElementById("content").src="/cgi-bin/voltconfig.pl";' />
   <input type="button" value="Current Configurator" onclick='document.getElementById("content").src="/cgi-bin/ampconfig.pl";' />
   <input type="button" value="Temprature Configurator" onclick='document.getElementById("content").src="/cgi-bin/tempconfig.pl";' />
</div>
<div style="position:relative;bottom:0;right:0;left:0;top:0">
   <iframe id="content" width="100%" height="100%" scrolling=auto src="/payloadCtrl.html"></iframe>
</div>
HTML

}
else{
print << "HTML";
Failure!
<br />
Password:<input id="password" type="password" /><input type="button" value="Submit" onclick="passCheck(document.getElementById('password').value);" />
HTML

}

1;