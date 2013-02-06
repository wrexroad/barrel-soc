#!/usr/bin/perl
use SOC_config qw(%configVals);

print "Content-Type: text/html \n\n";

print << "HTML";
<!doctype html>
<html>
<head>
<title>Admin Panel</title>


<style type="text/css">		
	#nav{
		border-style:inset; margin:0; padding:0; position:absolute; top:2px; left:2px; right:2px; height:25px
	}
	
	#contentDiv{
		position:absolute; top:30px; left:2px; right:2px; height:90%; width: 95%;
	}
</style>

</head>
<body>
HTML

if ($ENV{'QUERY_STRING'} eq "pass=".$configVals{"adminPass"}){
print << "HTML";
<div id="nav">
   <input type="button" value="Start/Stop Payloads" onclick='document.getElementById("content").src="/payloadCtrl.html";' />
   <input type="button" value="Configurator" onclick='document.getElementById("content").src="/cgi-bin/setLimits.pl";' />
   <input type="button" value="DS Contact" onclick='document.getElementById("content").src="/cgi-bin/setDS.pl";' />
</div>
<div id="contentDiv">
   <iframe id="content" width="100%" height="100%" scrolling=auto src="/payloadCtrl.html"></iframe>
</div>
HTML

}
else{
print << "HTML";
<form method="get" action="/cgi-bin/adminPanel.pl">
   Password:
   	<input id="password" name="pass" type="password" />
   	<input type="submit" value="Submit"  />
</form>
<script>document.getElementById("password").focus();</script>
HTML

}


print << "HTML";
</body>
</html>
HTML

1;
