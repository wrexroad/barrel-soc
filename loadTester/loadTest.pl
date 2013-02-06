#!/usr/bin/perl
use strict;
use Time::HiRes ("usleep");
#turn off output buffering
$|=1;

#init main hash
my %loadTest = {
	iniFile => "",
	startTime => "",
	curFrame => "",
	frameLength => "",
	outputDir => "",
	outFullPath => "",
	outputFile => "",
	dropCallProb => "",
	badCSProb => "",
	truncFrameProb => "",
	frameNum => 0,
	frameTime => 0,
	chcksmVal => 0,
	payloadNum => 0,
	frameRead =>0
};

#set ini file
if(scalar(@ARGV)>0){$loadTest{'iniFile'}=$ARGV[0];}
else{die "Must indicate ini file.\n";}

doINI(\%loadTest);

setDateFilename(\%loadTest);

openOut(\%loadTest);

openIn(\%loadTest);

#set start time
$loadTest{'startTime'}=time();

while(1){ #loop forever	
	if(($loadTest{'startTime'}+$loadTest{'frameSpeed'}) <= time()){
		getNextFrame(\%loadTest);
		if($loadTest{'frameRead'}==1){#try to get the next frame in the input file	
			if(rand()<=$loadTest{'dropCallProb'}){#check if we should drop the call
				dropCall(\%loadTest);
			}
			else{
				#print the next frame
				writeOut(\%loadTest);
			}
		}
		else{
			#clear frame buffer
			$loadTest{'curFrame'}="";
			
			#reset read position
			seek INPUT,0,0;
			print "Restarted input file. \n";
		}
		#set start time
		$loadTest{'startTime'}=time();
	}
	else{usleep(10);}
}

closeOut(\%loadTest);

1;

#define functions
sub doINI{
	#get args
	my $mainHash = $_[0];
	
	#Fill main object with ini values
	my ($line,$key,$value,$comment)="";
	open CONFIG, $$mainHash{'iniFile'};
	while($line=<CONFIG>){
		chomp($line);
		($line, $comment)=split /;/,$line;
		($key, $value)=split /=/,$line;
		$$mainHash{$key}=$value;
	}
	close CONFIG;
	
	#make sure the output directory is created
	`mkdir -p $$mainHash{'outputDir'}`;
	
	#format the payload number
	$$mainHash{'payloadNum'}=sprintf "%06b", $$mainHash{'payloadNum'};
}

sub setDateFilename{ #return a unique filename based on current date and time
	#get args
	my $mainHash = $_[0];
	
	#get date array
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my @date=localtime(time);
	
	#ensure all the date fields are two digit
	for(my $date_i=0; $date_i<scalar(@date); $date_i++){
	if($date[$date_i]<10){$date[$date_i]="0".$date[$date_i];}
	}
	
	#create a subdirectory path with the barrel convention
	$$mainHash{'outFullPath'}=$$mainHash{'outputDir'}.'/999'.$date[7].'/dat';
	
	`mkdir -p $$mainHash{'outFullPath'}`;
	
	#create output file name
	$$mainHash{'outputFile'}="999".$date[7]."_".$date[2].$date[1].$date[0].".bar";
}

sub openIn{
	#get args
	my $mainHash = $_[0];
	
	#open the input file
	open INPUT, $$mainHash{'inputFile'};
	binmode INPUT;
}

sub closeIn{
	close INPUT
}

sub openOut{
	#get args
	my $mainHash = $_[0];
	
	#open the output file for binary output and no buffering
	open OUTPUT, ">>".$$mainHash{'outFullPath'}.'/'.$$mainHash{'outputFile'};
	binmode OUTPUT;
	my $ofh = select OUTPUT;
	$| = 1; #turn off line buffering
	select $ofh;
	print 'Output file set to '.$$mainHash{'outFullPath'}.'/'.$$mainHash{'outputFile'}."\n";
}

sub closeOut{
	#get args
	my $mainHash = $_[0];
	
	#see if there is a final frame to output
	if($$mainHash{'curFrame'} ne ""){
		#check if the last frame should be truncated before closing the file
		if(rand()<=$$mainHash{'tuncFrameProb'}){
			print "Truncating frame. \n";
			
			#truncate a random number of bits (with a max being set to 8 time the frame length)
			$$mainHash{'curFrame'} = $$mainHash{'curFrame'} >> (rand()*($$mainHash{'frameLength'}*8));
		}
	}
	close OUTPUT;
}

sub getNextFrame{ #grabs the next data frame from the binary file
	#get args
	my $mainHash = $_[0];
	my $buf=0;
	
	#read the next frame
	if(read INPUT, $$mainHash{'curFrame'}, $$mainHash{'frameLength'}){
		$$mainHash{'frameRead'}=1; #flag a sucessful read
		
		#unpack the binary
		$$mainHash{'curFrame'} = unpack "B*", $$mainHash{'curFrame'};
		
		#take apart the incoming frame counter words
		my $curFrameNum = substr($$mainHash{'curFrame'}, 27, 21);	
		
		#advance the local frame counter and time if out of sync (could create a data gap within a file)
		my $fcdiff = (oct("0b".$curFrameNum) % 40) - ($$mainHash{'frameNum'} % 40);
		if($fcdiff>0){
			print "Frame counted set forward by ".$fcdiff."\n";
			$$mainHash{'frameNum'} += $fcdiff;
			#$$mainHash{'frameTime'} += $fcdiff;
		}
		elsif($fcdiff<0){
			print "Frame counted set forward by ".(40+$fcdiff)."\n";
			$$mainHash{'frameNum'} += (40+$fcdiff);
			#$$mainHash{'frameTime'} += (40+$fcdiff);
		}
		
		#replace the frame counter words
		substr($$mainHash{'curFrame'}, 21, 27) = $$mainHash{'payloadNum'}.sprintf("%021b", $$mainHash{'frameNum'});
		
		#decide if we should make a checksum error
		if(rand()<=$loadTest{'badCSProb'}){#check if the checksum should be garbled
			badCheckSum(\%loadTest);
		}
		
		#repack into binary format
		$$mainHash{'curFrame'} = pack "B*", $$mainHash{'curFrame'};
		
		advCounters($mainHash);
	}
	else{
		$$mainHash{'frameRead'}=0; #flag failed read
	}
}

sub advCounters{ #advanced time based counters
	#get args
	my $mainHash = $_[0];

	#incriment frame counter and time
	$$mainHash{'frameNum'}++;
	#$$mainHash{'frameTime'}++;
	
	#make sure the time remains within a 24h period
	#if($$mainHash{'frameTime'}>=86400){
	#	$$mainHash{'frameTime'}=0;
	#}
}

sub writeOut{
	#get args
	my $mainHash = $_[0];
	
	#read the input file and copy 1 frame/second to the output
	my $frame_i=0;
	print OUTPUT $$mainHash{'curFrame'};
	print "Writing frame number ".$$mainHash{'frameNum'}." to " . $$mainHash{'outFullPath'} . '/' . $$mainHash{'outputFile'}."\n";
	
	#clear frame buffer
	$loadTest{'curFrame'}="";
}

sub dropCall{
	#get args
	my $mainHash = $_[0];
	
	print "Dropping call. \n";
	closeOut($mainHash);
	
	#create a data gap between files
	for(my $dropTime_i=0; $dropTime_i<$$mainHash{'dropCallGap'}; $dropTime_i++){
		advCounters($mainHash);
		sleep 1;
	}
	
	setDateFilename($mainHash);
	openOut($mainHash);
	print "Starting new call with file $$mainHash{'outputFile'}. \n";
}

sub badCheckSum{
	#get args
	my $mainHash = $_[0];
	
	#set the checksum to a random integer between 1 and 500
	print "Bad checksum in frame ".$$mainHash{'frameNum'}.". \n";
	substr($$mainHash{'curFrame'}, 212, 2) = sprintf("%016b", int(rand()*500));
}