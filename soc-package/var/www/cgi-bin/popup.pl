#!/usr/bin/perl

use SOC_config qw(%configVals);

print "Content-Type: text/html \n\n";

@input = split /&/,$ENV{'QUERY_STRING'};

if($input[1] eq "clear"){
	#write a timestamp to the timer file
	open TIMER, ">" . $configVals{socNas} . "/payload" . $input[0] . "/.alertTimer" or
		print "Can't open timer file for writing. - " . $! and die;
		print TIMER time();
	close TIMER;
}

my $currentTime = localtime time();

open TIMER, "<" . $configVals{socNas} . "/payload" . $input[0] . "/.alertTimer" or
	print "Can't read timer file. - " . $! and die;
	my $lastTime = <TIMER>;
	chomp $lastTime;
	$lastTime = localtime $lastTime;
close TIMER;

print << "HTML";
<!DOCTYPE html>
<html>
<body bgcolor=red>
	<p>Payload $input[0] has critical alerts, please attend to this immediately!</p>
	<p>Timer was last reset: $lastTime. </p>
	<p>It is now: $currentTime.</p>
	<p>The timer must be reset every 5 minutes until the red alert has cleared.</p>
	<button type="button"
	   onClick="window.location='popup.pl?$input[0]&clear&' + Math.random()"
	>Reset</button>
</body>
</html>
HTML
