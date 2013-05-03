#!/usr/bin/perl

use SOC_config qw(%configVals %dataTypes %dsContact);
use SOC_funcs qw(getDirListing getVarInfo);

#turn off output buffering
$|=1;

sub init{
	our ($line,$data) = "";
	my ($continue,$key,$value,$input,$title_i) = "";
	our %fileObject = ();
	our %savedData = ();
	our %alerts = ();
   our %limits = ();
   
   #create a buffer to hold 60 seconds worth of 
	our @gpsAltBuf = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

	#create an initial time for the timout timer
	$fileObject{'timeoutStartTime'} = time();
	
	#create a cross reference of subcoms to variabl names
	our %varNames = ();
	foreach my $type (keys %dataTypes){
      $varNames{$type} = ();
		
		foreach my $var (keys $dataTypes{$type}){
		  my $i = $dataTypes{$type}{$var}{"subcom"};
		  $varNames{$type}[$i] = $var;
		}
	}

	#get arguments
	foreach(@ARGV){
		($key,$value)=split /=/;
		$fileObject{$key}=$value;
	}
	@ARGV=();
	
	#get list of variables and subcoms
	our %varList=();
	getVarInfo(\%dataTypes,\%varList);
	
	#set the first working date
	$fileObject{'currentDate'}=$fileObject{'startdate'};

	#Initialize folder and data files
	unless(-d $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/'){
		mkdir $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/'
		or print "Could not create payload directory" . $! and die;
	}
	unless(-d $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/raw/'){
		mkdir $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/raw/'
		or print "Could not create raw file directory" . $! and die;;
	}
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.translog'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.sysout'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.tempsci'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.temphouse'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.lastRead'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.transfile'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.newhex'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.newdata'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.newmedspec'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.newslowspec'
   );
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.errorlist'
   );
   writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.alertTimer'
   );
	
   #generate first set of empty data files
	newDataFiles();
	
	#set the current date for all the other programs
	writeFile(
      $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.currentdate',
      $fileObject{'currentDate'}
   );
	
	writetolog('Date set to '.$fileObject{'currentDate'}, 1);
	
	#create directory listing
	our @filelist=();
	@filelist =
      getDirListing(
         $configVals{'mocNas'} . '/payload' . $fileObject{'payload'}.
            '/' . $fileObject{'currentDate'} . '/dat/', 'file', 'pkt'
      ) or die
         'Could not read file list (' .
            $configVals{'mocNas'} . '/payload'.$fileObject{'payload'} .
            '/'.$fileObject{'currentDate'}.'/dat/) for payload ' .
            $fileObject{'payload'} . '!' . "\n" . $!;
   
   #get first set of limits
   getLimits();
}

sub mainLoop{
	PAYLOADCYCLE:{
		my ($newdates, $currenttime) = 0;
		my $line = "";
		
		#check if there have been any files previously read for this payload
		open LASTREAD, $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.lastRead'
         or die 'Could not read file .lastRead!'."\n".'Died:'.$!;	
		chomp($fileObject{'lastfile'} = <LASTREAD>);
		chomp($fileObject{'lasttime'} = <LASTREAD>);
		close LASTREAD;
		
		 if ($fileObject{'lastfile'} eq ""){ #no files previously read, write temp files with first file
		 	$fileObject{'fileName'}=shift(@filelist);
			$fileObject{'bytecount'}=0;
         
			trans();
			last PAYLOADCYCLE;
		 }
		 
		 else{ #some file has already been read
		 
			#get the timestamp of the current data file and compare it to the timestamp of the previous run
			@stat=stat($configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'lastfile'});
			$currenttime = $stat[9]; 
			
			if ($currenttime == $fileObject{'lasttime'} and scalar(@filelist) > 0){
		      #There is another file in this date directory
				#no new data will be recorded for this file
				#clear the byte count for this file and get the next file name
				$fileObject{'fileName'}=shift(@filelist);
				$fileObject{'bytecount'}=0;
				
				#now that the file is complete, copy it to the soc-nas or delete it if its empty
				if($stat[7] > 0){
					unless(-d $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/raw/'.$fileObject{'currentDate'}){
						mkdir $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/raw/'.$fileObject{'currentDate'};
					}
					copy(
						$configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'lastfile'}, 
						$configVals{'socNas'}."/payload".$fileObject{'payload'}."/raw/".$fileObject{'currentDate'}."/".$fileObject{'lastfile'}, 
						">"
					);
				}else{
					unlink $configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'lastfile'};
				}
				
            #start translating next file
            trans(); 
				
				last PAYLOADCYCLE;
			}
			
			elsif ($currenttime != $fileObject{'lasttime'}) #new data so rerun translator 
			{
				trans();			
				
				last PAYLOADCYCLE;
			}
			 
			elsif ($currenttime == $fileObject{'lasttime'} and scalar(@filelist) == 0) #nothing to do, so check for next days directory
			{
				datechange();
				
				last PAYLOADCYCLE
			}
	 	}
	}
}

#open the log file and add a new line to the top
#keep the length <= 50 lines
#first argument is the message, second argument is a boolean to print a date
sub writetolog{ 
	my $message=$_[0];
	my $printDate=$_[1];
	my ($line,$lineCount,$newline)="";
	my @lines=();
	
	open LOG, "<".$configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.translog' or print 'Can\'t open log for reading. '.$!."\n";;
	while($line=<LOG>){
		push @lines, $line;
	}
	close LOG;
	
	open LOG, ">".$configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.translog' or print 'Can\'t open log for writing. '.$!."\n";;
		if($printDate){#check if we should print a date before the log entry
			my @time=localtime(time);
			#make dates prettier
			$time[4]+=1;
			$time[5]-=100;
			for(my $time_i=0;$time_i<=5;$time_i++){
				if($time[$time_i]<10){$time[$time_i]="0".$time[$time_i];}
			}
			
			#print time and date
			$newline=$time[2].':'.$time[1].':'.$time[0].' '.$time[4].'/'.$time[3].'/'.$time[5];
		}
		if($printDate and $message){
			$newline = $newline.' - ';
		}
		if($message){
			$newline = $newline.$message;
		}
		print LOG $newline."\n";
		while($lineCount<49 && scalar(@lines)>=1){
			print LOG shift(@lines);
			$lineCount++;
		}
	close LOG;
	
}

sub copy{
	my($infile,$outfile,$mode)=@_;
	my $buffer='';
	
	open INFILE, $infile or print 'Can\'t open '.$infile.' for reading. '.$!."\n";
	open OUTFILE, $mode.$outfile or print 'Can\'t open '.$outfile.' for writing. '.$!."\n";
	binmode INFILE;
	binmode OUTFILE;
	
	while(read (INFILE, $buffer, 65536)){print OUTFILE $buffer; }
	
	close INFILE;
	close OUTFILE;
}

sub trans{
	my ($i,$j,$k)=0;
	my @stat;
	
   #make sure the timeout flag is clear
   $fileObject{'timeout'} = 0;

	#update .lastread file
	@stat=stat $configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'fileName'};
	writeFile($configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.lastRead',$fileObject{'fileName'}."\n".$stat[9]."\n");
	
	#freeze the possibly changing raw data file by copying it to to .transfile
	copy($configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'fileName'}, $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.transfile',">");
	
	#clear frame error counters
	$fileObject{'noFC'}=0;
	$fileObject{'badSums'}=0;
	$fileObject{'shortFrames'}=0;
	
	$fileObject{'completedFrames'}=splitframes($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.transfile");
	
	#make sure the file does not have 0 length
	$fileObject{'fileSize'} = -s $configVals{'mocNas'}."/payload".$fileObject{'payload'}."/".$fileObject{'currentDate'}."/dat/".$fileObject{'fileName'};
	if ($fileObject{'fileSize'}==0){
		writetolog("File ".$configVals{'mocNas'}."/payload".$fileObject{'payload'}."/".$fileObject{'currentDate'}."/dat/".$fileObject{'fileName'}. " is empty.",1);
		return;
	}
	
	$fileObject{'completedFrames'} = 0 if !$fileObject{'completedFrames'};
	
	writetolog('----------------------------------------------------------------------');
	writetolog('Filename:'.$configVals{'mocNas'}."/payload".$fileObject{'payload'}."/".$fileObject{'currentDate'}."/dat/".$fileObject{'fileName'}."\n".
				  ' Size:'.$fileObject{'fileSize'}.
				  ', Total Frames:'.($fileObject{'noFC'}+$fileObject{'shortFrames'}+$fileObject{'badSums'}+$fileObject{'completedFrames'}).
				  ', Extracted Frames:'.$fileObject{'completedFrames'}.
				  ', Bad Checksums:'.$fileObject{'badSums'}.
				  ', Short Frames:'.$fileObject{'shortFrames'}.
				  ', No FC:'.$fileObject{'noFC'});
	writetolog('----------------------------------------------------------------------');
	writetolog(0,1);
}

sub datechange{
	my $newdates="";
	my @datelist=();

	#get a list of dates fromt the MOC
	@datelist=getDirListing($configVals{'mocNas'}."/payload".$fileObject{'payload'}."/","dir");
	
	until($datelist[0]==$fileObject{'currentDate'}) {shift(@datelist);}
	
	if (@datelist>1) #there is a new date folder to look in
	{
		  
      #now that the file is complete, copy it to the soc-nas or delete it if its empty
      if($stat[7] > 0){
      unless(-d $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/raw/'.$fileObject{'currentDate'}){
         mkdir $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/raw/'.$fileObject{'currentDate'};
      }
      copy(
         $configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'lastfile'}, 
         $configVals{'socNas'}."/payload".$fileObject{'payload'}."/raw/".$fileObject{'currentDate'}."/".$fileObject{'lastfile'}, 
         ">"
      );
      }else{
         unlink $configVals{'mocNas'}.'/payload'.$fileObject{'payload'}.'/'.$fileObject{'currentDate'}.'/dat/'.$fileObject{'lastfile'};
      }
		
		writetolog("Finished with ".$fileObject{'currentDate'},1);
		
		shift(@datelist);
		$fileObject{'currentDate'}=shift(@datelist);
		if ($fileObject{'enddate'} and $fileObject{'currentDate'}>$fileObject{'endate'}){writetolog("Extracted from $fileObject{'startdate'} to $fileObject{'enddate'} on payload $fileObject{'payload'}",1) and exit 1;}
		
		#regenerate directory listing
		@filelist=();
		@filelist=getDirListing($configVals{'mocNas'}."/payload".$fileObject{'payload'}."/".$fileObject{currentDate}."/dat/","file","pkt") or die "Could not read file list (".$configVals{mocNas}."/payload".$fileObject{'payload'}."/".$fileObject{'currentDate'}."/dat/) for payload $fileObject{payload}!\nDied:$!";
		
		#update .currentdate
		writeFile($configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.currentdate', $fileObject{'currentDate'});
		
		#clear .lastread
		writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.lastRead");
		
		#generate a new set of empty data files
		newDataFiles();
	
		writetolog("Ready for ".$fileObject{'currentDate'},1);
	}else{
		#No new date folders found. Check for data timeout
		if((time() - $fileObject{'timeoutStartTime'}) > $configVals{'timeout'}){
         #too long since last data, print a timeout alert
         
         my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
            localtime(time);
         my @lines = ();
         
         open(ALERTS,
            "<" . $configVals{"socNas"} .
            "/payload" . $fileObject{'payload'} . "/.errorlist");
            
            while(my $line = <ALERTS>){
               push @lines, $line;
            }
         close ALERTS;
         
         open(ALERTS,
            ">" . $configVals{"socNas"} .
            "/payload" . $fileObject{'payload'} . "/.errorlist");
            
            foreach my $line (@lines){
               #dont print old timeout line
               if(index($line, "Timeout!") == -1){
                  print ALERTS $line;
               }
            }
            
            #print new timeout line
            print ALERTS
               "Timeout! - " . $hour . ":" . $min . ":" . $sec . "\n";               
         close ALERTS;
         
         redFlagTimer();
      }
      
      #Wait for a bit and start over
		writetolog("Waiting for new data in ".$fileObject{'currentDate'},1);
		sleep $configVals{'updaterSleepTime'};
		
		#regenerate directory listing
		@filelist=();
		@filelist=getDirListing($configVals{'mocNas'}."/payload".$fileObject{'payload'}."/".$fileObject{'currentDate'}."/dat/","file","pkt") or die "Could not read file list (".$configVals{mocNas}."/payload".$fileObject{payload}."/".$fileObject{currentDate}."/dat/) for payload $fileObject{payload}!\nDied:$!";
		
		#discard all previously read files from the list
		until($filelist[0] eq $fileObject{'fileName'} or scalar(@filelist)==1){shift(@filelist);}
		$fileObject{'fileName'}=shift(@filelist);
	}
}

sub splitframes{
	my $filename=$_[0];
	my %frames=();
	my $word="";
	my ($i,$j,$k,$completedFrames,$shortFrame,$sum,$null);

	#clear old temp files
	open CLEAR, ">".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.tempsci" or die "Could not clear tempsci! $!\n";
	close CLEAR;
	open CLEAR, ">".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.temphouse" or die "Could not clear temphouse! $!\n";
	close CLEAR;

	open RAWDAT, "$filename" or writetolog("Could not open $filename! $! Skipping...",1);
	binmode RAWDAT;
	
	#dump any part of the file that was already read
	read (RAWDAT, $null, $fileObject{'bytecount'});
	
	#start getting words 
	($i,$j,$k)=(0,0,0);
	while (read (RAWDAT, $word, 2)) { #read data file 1 word at a time
		$word=unpack "H*", $word; 
		$fileObject{'bytecount'}+=2;
		
		if ($word ne 'eb90'){
			$frames{$i}[$j]=$word;
			$j++;
		}
		else{
			if (scalar @{$frames{$i}}==$configVals{'frameLength'}){ #We have a full frame, process and start over
				completeFrame(\@{$frames{$i}}); #just reference the frames location
				($i,$shortFrame)=0;
				%frames=();
				$word="";
				$completedFrames++;
			}
			
			elsif(scalar @{$frames{$i}}>$configVals{'frameLength'}){ # Frame is too long, dump and start over
				($i,$shortFrame)=0;
				%frames=();
				$word="";
				$fileObject{'shortFrames'}+=2;
			}
				
			else{ # Frame is too short
				if($shortFrame!=0){ #add up all of the pieces and see if we have a whole frame
					($k,$sum)=0;
					while($k<$i){
						$sum+=scalar @{$frames{$k}}+1; #add the length of each frame piece plus one for the missing syncword
						$k++;
					}
					
					if ($sum==$configVals{'frameLength'}){ #got all the pieces, put a frame together and process							
						$k=0;
						while($k<$i){
							push @{$frames{0}},('eb90',@{$frames{$k}});
							$k++;
						}
						completeFrame(\@{$frames{0}}); #just reference the frames location
						($i,$shortFrame)=0;
						%frames=();
						$completedFrames++;
					}
					elsif($sum>$configVals{'frameLength'}){ #Frame is too long, check if the newest piece is a whole frame
						if(scalar @{$frames{$i}}==$configVals{'frameLength'}){#good frame length found. Process.
							completeFrame(\@{$frames{$i}});
							$fileObject{'shortFrames'}=$shortFrame-1;
							($i,$shortFrame)=0;
							%frames=();
							$completedFrames++;
						}
						else{ #all pieces are the wrong length, dump and start over
							$fileObject{'shortFrames'}=$shortFrame;
							($i,$shortFrame)=0;
							%frames=();
						}
					}
					else{ #Frame is still too short, so grab another piece
						$shortFrame++;
						$i++;
					}
				}
				else { #Frame is too short, look for another piece
						$shortFrame++;
						$i++;
					}
			}
			$j=0;
		}
	}
	close RAWDAT;
	
	#update the timeout counter to the current time if we processed any data
	if($completedFrames > 0){
      $fileObject{'timeoutStartTime'} = time();
	}
	
	return $completedFrames
}

sub completeFrame{

	my $frameRef = $_[0];
	my ($i,$j,$counter,$testsum) = 0;
	my $timeoffset=0;
	my $tempfile="";
	my %newData=();
	
	#verify checksum
	$newData{'cksm'} = hex($$frameRef[105]);
	$newData{'calcsum'} = hex(eb90); #need to add 0xEB90 into the checksum becasue it is out frame splitting value
	for(my $i=0; $i < 105; $i++){$newData{'calcsum'}+=hex($$frameRef[$i])} 
	$newData{'calcsum'} = $newData{'calcsum'} & 0b1111111111111111;
	if ($newData{'calcsum'} != $newData{'cksm'}){
		$fileObject{'badSums'}++;
		return;
	}
	
	#Build a hash of translated frame values. Values with mod>1 are arrays inside hash elements
	
	#translate frame counter words
	$newData{'version'} = hex($$frameRef[0].$$frameRef[1]) >> 27;
	$newData{'payload'} = (hex($$frameRef[0].$$frameRef[1]) & 0b00000111111000000000000000000000) >> 21;
	$newData{'frameNumber'} = hex($$frameRef[0].$$frameRef[1]) & 0b111111111111111111111;
	
	#Skip if there is no valid frame counter.
	if(!$newData{'frameNumber'}){
		$fileObject{noFC}++;
		return;
	}
	
	#get current mod indices
	my %modIndex=();
		$modIndex{'2'} = $newData{'frameNumber'} % 2;
		$modIndex{'4'} = $newData{'frameNumber'} % 4;
		$modIndex{'32'} = $newData{'frameNumber'} % 32;
		$modIndex{'40'} = $newData{'frameNumber'} % 40;
	
	#GPS Data
		$tempgps = hex($$frameRef[2].$$frameRef[3]);
		
		#gps coord data is read as a signed, 2-byte int
		$newData{'gps'}[$modIndex{'4'}] =
         $tempgps >> 31 ? $tempgps - 2 ** 32 : $tempgps;
		
		#scale the data
		$newData{'gps'}[$modIndex{'4'}] =
         scaleData($newData{'gps'}[$modIndex{'4'}], 'gps', $modIndex{'4'});
		
		#if this is GPS_Alt, add it to the averaging buffer
		if($modIndex{'4'} == 0){
		   shift @gpsAltBuf;
		   push @gpsAltBuf, $newData{'gps'}[$modIndex{'4'}];
         
		   #find average ascent rate by summing all the "instantaneous" sink rates 
		   # and dividing by the length of the buffer.
		   # Altitudes are transmitted every 4 seconds.
		   # Because this is labeled "Ascent Rate": ascent is positive, decent is negative
		   
		   my $sum = 0;
		   for(my $alt_i = 0; $alt_i < scalar(@gpsAltBuf - 1); $alt_i++){ 
			   $sum += ($gpsAltBuf[$alt_i + 1] - $gpsAltBuf[$alt_i]) / 4;
		   }
         
         #average the speeds and convert from km/s to m/s
		   $newData{'ascentRate'} = ($sum / scalar(@gpsAltBuf - 1)) * 1000;
		}
	
	#GPS Pulse Per Second
		$newData{'pps'} = hex($$frameRef[4]);
	
	#Mag Data
		#three vectors are returned at 4Hz each. Each value is 3bytes
		$newData{'bx1'} =
         (hex(substr($$frameRef[5].$$frameRef[6], 0, -2))-8388608.0)/83886.070;
		$newData{'by1'} =
		   ((hex(substr($$frameRef[6], -2).$$frameRef[7]))-8388608.0)/83886.070;
		$newData{'bz1'} =
		   (hex(substr($$frameRef[8].$$frameRef[9], 0, -2))-8388608.0)/83886.070;
		$newData{'bx2'} =
		   ((hex(substr($$frameRef[9], -2).$$frameRef[10]))-8388608.0)/83886.070;
		$newData{'by2'} =
		   (hex(substr($$frameRef[11].$$frameRef[12], 0, -2))-8388608.0)/83886.070;
		$newData{'bz2'} =
		   ((hex(substr($$frameRef[12], -2).$$frameRef[13]))-8388608.0)/83886.070;
		$newData{'bx3'} =
		   (hex(substr($$frameRef[14].$$frameRef[15], 0, -2))-8388608.0)/83886.070;
		$newData{'by3'} =
		   ((hex(substr($$frameRef[15], -2).$$frameRef[16]))-8388608.0)/83886.070;
		$newData{'bz3'} =
		   (hex(substr($$frameRef[17].$$frameRef[18], 0, -2))-8388608.0)/83886.070;
		$newData{'bx4'} =
		   ((hex(substr($$frameRef[18], -2).$$frameRef[19]))-8388608.0)/83886.070;
		$newData{'by4'} =
		   (hex(substr($$frameRef[20].$$frameRef[21], 0, -2))-8388608.0)/83886.070;
		$newData{'bz4'} =
		   ((hex(substr($$frameRef[21], -2).$$frameRef[22]))-8388608.0)/83886.070;
		$newData{'bx'} =
		   ($newData{'bx1'}+$newData{'bx2'}+$newData{'bx3'}+$newData{'bx4'})/4;
		$newData{'by'} =
		   ($newData{'by1'}+$newData{'by2'}+$newData{'by3'}+$newData{'by4'})/4;
		$newData{'bz'} =
		   ($newData{'bz1'}+$newData{'bz2'}+$newData{'bz3'}+$newData{'bz4'})/4;
		
	#Light Curve Data
		#4 energy levels, 20 elements each. lc1 and lc2 are 2 byte values, lc3 and lc4 are 1 byte values.
		($i,$j)=(0,0);
		while($i<60){
			$newData{'LC1'}[$j]=hex($$frameRef[24+$i]); 
			$newData{'LC2'}[$j]=hex($$frameRef[25+$i]);
			$newData{'LC3'}[$j]=hex($$frameRef[26+$i]) >> 8;
			$newData{'LC4'}[$j]=hex($$frameRef[26+$i]) & 0b11111111;
			$i+=3;
			$j++;
		}
		($newData{'lc1'},$newData{'lc2'},$newData{'lc3'},$newData{'lc4'})=(0,0,0,0);
		foreach(@{$newData{'LC1'}}){$newData{'lc1'}+=$_;}
		foreach(@{$newData{'LC2'}}){$newData{'lc2'}+=$_;}
		foreach(@{$newData{'LC3'}}){$newData{'lc3'}+=$_;}
		foreach(@{$newData{'LC4'}}){$newData{'lc4'}+=$_;}
		
	#Medium Specral Data
	getSpectralData($newData{'frameNumber'},$modIndex{'4'},3,84,12,"medspec",$frameRef);
	
	#Slow Spectral Data
	getSpectralData($newData{'frameNumber'},$modIndex{'32'},31,96,8,"slowspec",$frameRef);
	
	#Rate counters
	$newData{"rc"}[$modIndex{"4"}]=hex($$frameRef[104])/4; #convert to cnts/sec
	
	#House Data
	if ($modIndex{"40"}<=35){
		$newData{"hk"}[$modIndex{'40'}] = scaleData(hex($$frameRef[23]),'hk',$modIndex{'40'});
	}
	elsif($modIndex{"40"}==36){
		$newData{'numOfSats'}=hex($$frameRef[23]) >> 8;
		$newData{'timeOffset'}=hex($$frameRef[23]) & 0b11111111;
	}
	elsif($modIndex{"40"}==37){
		$newData{'weeks'}=hex($$frameRef[23]);
		}
	elsif($modIndex{"40"}==38){
		$newData{'termStatus'}=hex($$frameRef[23]) >> 15;
		$newData{'cmdCounter'}=hex($$frameRef[23]) & 0b111111111111111;
	}
	elsif($modIndex{"40"}==39){
		$newData{'dcdCounter'}=hex($$frameRef[23]) >> 8;
		$newData{'modemCounter'}=hex($$frameRef[23]) & 0b11111111;
	}
	
	#Save the newsest data 
	if($newData{'gps'}[1]){ #if there is no time sent for this frame, set $newData{gps}[1] to be the last frame's time plus 1
		$savedData{'Time'} = $newData{'gps'}[1];
	}
	else{
		$newData{'gps'}[1] = $savedData{'Time'} + 1000;
		$savedData{'Time'} = ($savedData{'Time'} + 1000) . "*";
	}	
	saveNewValue($fileObject{'fileName'},"fileName");
	saveNewValue($newData{'version'},"version");
	$savedData{'frameNumber'} = $newData{frameNumber};# If we got this far, we already know we have a good frame number
	saveNewValue($newData{'numOfSats'},"numOfSats");
	saveNewValue($newData{'timeOffset'},"timeOffset");
	saveNewValue($newData{'termStatus'},"termStatus");
	saveNewValue($newData{'cmdCounter'},"cmdCounter");
	saveNewValue($newData{'modemCounter'},"modemCounter");
	saveNewValue($newData{'dcdCounter'},"dcdCounter");
	saveNewValue($newData{'weeks'},"weeks");
	
	saveFormattedNewValue($newData{'gps'}[2],"GPS_Lat","%.2f");
	saveFormattedNewValue($newData{'gps'}[3],"GPS_Lon","%.2f");
	saveFormattedNewValue($newData{'gps'}[0],"GPS_Alt","%.3f");
   saveFormattedNewValue($newData{'ascentRate'}, "GPS_Ascent_Rate","%.3f");
	saveFormattedNewValue($newData{'rc'}[1],"LowLevel","%.2f");
	saveFormattedNewValue($newData{'rc'}[2],"PeakDet","%.2f");
	saveFormattedNewValue($newData{'rc'}[3],"HighLevel","%.2f");
	saveFormattedNewValue($newData{'rc'}[0],"Interrupt","%.2f");
	saveFormattedNewValue($newData{'bx'},"MAG_X","%.2f");
	saveFormattedNewValue($newData{'by'},"MAG_Y","%.2f");
	saveFormattedNewValue($newData{'bz'},"MAG_Z","%.2f");
	saveNewValue($newData{'lc1'},"LC1");
	saveNewValue($newData{'lc2'},"LC2");
	saveNewValue($newData{'lc3'},"LC3");
	saveNewValue($newData{'lc4'},"LC4");
	saveNewValue($newData{'pps'},"GPS_PPS");
	
	#save temperature data
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T00_Scint'}{'subcom'}],'T00_Scint',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T01_Mag'}{'subcom'}],'T01_Mag',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T02_ChargeCont'}{'subcom'}],'T02_ChargeCont',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T03_Battery'}{'subcom'}],'T03_Battery',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T04_PowerConv'}{'subcom'}],'T04_PowerConv',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T05_DPU'}{'subcom'}],'T05_DPU',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T06_Modem'}{'subcom'}],'T06_Modem',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T07_Structure'}{'subcom'}],'T07_Structure',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T08_Solar1'}{'subcom'}],'T08_Solar1',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T09_Solar2'}{'subcom'}],'T09_Solar2',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T10_Solar3'}{'subcom'}],'T10_Solar3',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T11_Solar4'}{'subcom'}],'T11_Solar4',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T12_TermTemp'}{'subcom'}],'T12_TermTemp',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T13_TermBatt'}{'subcom'}],'T13_TermBatt',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T14_TermCap'}{'subcom'}],'T14_TermCap',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'T15_CCStat'}{'subcom'}],'T15_CCStat',"%.2f");
	
	#save voltage data
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V00_VoltAtLoad'}{'subcom'}],'V00_VoltAtLoad',"%.2f"); 
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V01_Battery'}{'subcom'}],'V01_Battery',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V02_Solar1'}{'subcom'}],'V02_Solar1',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V03_+DPU'}{'subcom'}],'V03_+DPU',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V04_+XRayDet'}{'subcom'}],'V04_+XRayDet',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V05_Modem'}{'subcom'}],'V05_Modem',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V06_-XRayDet'}{'subcom'}],'V06_-XRayDet',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V07_-DPU'}{'subcom'}],'V07_-DPU',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V08_Mag'}{'subcom'}],'V08_Mag',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V09_Solar2'}{'subcom'}],'V09_Solar2',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V10_Solar3'}{'subcom'}],'V10_Solar3',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'V11_Solar4'}{'subcom'}],'V11_Solar4',"%.2f");
	
	#save current data
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I00_TotalLoad'}{'subcom'}],'I00_TotalLoad',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I01_TotalSolar'}{'subcom'}],'I01_TotalSolar',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I02_Solar1'}{'subcom'}],'I02_Solar1',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I03_+DPU'}{'subcom'}],'I03_+DPU',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I04_+XRayDet'}{'subcom'}],'I04_+XRayDet',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I05_Modem'}{'subcom'}],'I05_Modem',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I06_-XRayDet'}{'subcom'}],'I06_-XRayDet',"%.2f");
	saveFormattedNewValue($newData{'hk'}[$dataTypes{'hk'}{'I07_-DPU'}{'subcom'}],'I07_-DPU',"%.2f");
	
	#save hex data
	$savedData{"hex"}="eb90";
	for ($i=0; $i < $configVals{'frameLength'}; $i++){
		$savedData{"hex"}=$savedData{"hex"}.",".$$frameRef[$i];
	}

	#Do a check for any out of range data
	checkLimits(\%newData, \%modIndex);
	
	#print the .newdata file
	open OUTPUT, ">".$configVals{socNas}."/payload".$fileObject{payload}."/.newdata";
		print OUTPUT "{\n";
		foreach my $var (sort keys %savedData){
			print OUTPUT "\t".'"'.$var.'": "'.$savedData{$var}.'",'."\n";
		}
		print OUTPUT 
         "\t".'"magOfB": "' . 
         sqrt(
            $savedData{"MAG_X"} ** 2 + 
            $savedData{"MAG_Y"} ** 2 + 
            $savedData{"MAG_Z"} ** 2
         ) . 
         '",'."\n";
		print OUTPUT "}\n";
	close OUTPUT;
	
	#Write next line of the gps coordinate file
	if(abs($savedData{'frameNumber'}-$savedData{'oldFrame'})>900){
		open OUTPUT, ">>".$configVals{'socNas'}.'/payload'.$fileObject{payload}.'/.flightpath';
			print OUTPUT
            $fileObject{'currentDate'} . "," .
            (0 + $savedData{'frameNumber'}) . "," .
            (0 + $savedData{'Time'}) . "," .
            (0 + $savedData{'GPS_Lat'}) . "," .
            (0 + $savedData{'GPS_Lon'}) . "," .
            (0 + $savedData{'GPS_Alt'}) . "\n";
		close OUTPUT;
		$savedData{'oldFrame'} = $savedData{'frameNumber'};
	}
	
	#Write next line of data files
	open OUTPUT,">>".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.datasci".$fileObject{'currentDate'};
		print OUTPUT $newData{'frameNumber'}.",";
		print OUTPUT $newData{'gps'}[1].",";
		writeFormattedValue($newData{'gps'}[2],"%.3f");
		writeFormattedValue($newData{'gps'}[3],"%.3f");
		writeFormattedValue($newData{'gps'}[0],"%.3f");
		writeFormattedValue($newData{'rc'}[1],"%.3f");
		writeFormattedValue($newData{'rc'}[2],"%.3f");	
		writeFormattedValue($newData{'rc'}[3],"%.3f");
		writeFormattedValue($newData{'rc'}[0],"%.3f");
		writeFormattedValue($newData{'bx'},"%.3f");	
		writeFormattedValue($newData{'by'},"%.3f");	
		writeFormattedValue($newData{'bz'},"%.3f");	
		writeValue($newData{'lc1'});	
		writeValue($newData{'lc2'});	
		writeValue($newData{'lc3'});	
		writeValue($newData{'lc4'});
		writeValue($newData{'pps'},"%.3f");		
		print OUTPUT "\n";
	close OUTPUT;
	
	#Write next line of gps file
	open OUTPUT,">>".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.gps".$fileObject{'currentDate'};
		print OUTPUT $newData{'frameNumber'}.",";
		print OUTPUT $newData{'gps'}[1].",";	
		writeFormattedValue($newData{'gps'}[2],"%.3f");
		writeFormattedValue($newData{'gps'}[3],"%.3f");
		writeFormattedValue($newData{'gps'}[0],"%.3f");
		writeValue($newData{'pps'},"%.3f");		
		print OUTPUT "\n";
	close OUTPUT;
	
	#Write next line of rate counter file
	open OUTPUT,">>".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.rc".$fileObject{'currentDate'};
		print OUTPUT $newData{'frameNumber'}.",";
		print OUTPUT $newData{'gps'}[1].",";
		writeFormattedValue($newData{'rc'}[1],"%.3f");
		writeFormattedValue($newData{'rc'}[2],"%.3f");	
		writeFormattedValue($newData{'rc'}[3],"%.3f");
		writeFormattedValue($newData{'rc'}[0],"%.3f");
		print OUTPUT "\n";
	close OUTPUT;
	
	#Write next line of mag file
	open OUTPUT,">>".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.mag".$fileObject{'currentDate'};
		print OUTPUT $newData{'frameNumber'}.",";
		print OUTPUT $newData{'gps'}[1].",";
		
		writeFormattedValue($newData{'bx1'},"%.3f");
		writeFormattedValue($newData{'bx2'},"%.3f");
		writeFormattedValue($newData{'bx3'},"%.3f");
		writeFormattedValue($newData{'bx4'},"%.3f");
		writeFormattedValue($newData{'bx'},"%.3f");	
		
		writeFormattedValue($newData{'by1'},"%.3f");
		writeFormattedValue($newData{'by2'},"%.3f");
		writeFormattedValue($newData{'by3'},"%.3f");
		writeFormattedValue($newData{'by4'},"%.3f");
		writeFormattedValue($newData{'by'},"%.3f");
		
		writeFormattedValue($newData{'bz1'},"%.3f");
		writeFormattedValue($newData{'bz2'},"%.3f");
		writeFormattedValue($newData{'bz3'},"%.3f");
		writeFormattedValue($newData{'bz4'},"%.3f");
		writeFormattedValue($newData{'bz'},"%.3f");

		print OUTPUT "\n";
	close OUTPUT;
	
	#Write next line of lightcurve file
	open OUTPUT,">>".$configVals{'socNas'}."/payload".$fileObject{'payload'}."/.lc".$fileObject{'currentDate'};
		print OUTPUT $newData{'frameNumber'}.",";
		print OUTPUT $newData{'gps'}[1].",";
		writeValue($newData{'lc1'});	
		writeValue($newData{'lc2'});	
		writeValue($newData{'lc3'});	
		writeValue($newData{'lc4'});
		print OUTPUT "\n";
	close OUTPUT;
	
	# write next line of housekeeping file
	open OUTPUT,">>".$configVals{socNas}."/payload".$fileObject{payload}."/.datahouse".$fileObject{currentDate};
		print OUTPUT $newData{frameNumber}.",";
		print OUTPUT $newData{gps}[1].",";
		
		#print temperature data
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T00_Scint'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T01_Mag'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T02_ChargeCont'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T03_Battery'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T04_PowerConv'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T05_DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T06_Modem'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T07_Structure'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T08_Solar1'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T09_Solar2'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T10_Solar3'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T11_Solar4'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T12_TermTemp'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T13_TermBatt'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T14_TermCap'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T15_CCStat'}{'subcom'}],"%.3f");
	
		#print voltage data
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V00_VoltAtLoad'}{'subcom'}],"%.3f"); 
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V01_Battery'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V02_Solar1'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V03_+DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V04_+XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V05_Modem'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V06_-XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V07_-DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V08_Mag'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V09_Solar2'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V10_Solar3'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V11_Solar4'}{'subcom'}],"%.3f");
		
		#print current data
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I00_TotalLoad'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I01_TotalSolar'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I02_Solar1'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I03_+DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I04_+XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I05_Modem'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I06_-XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I07_-DPU'}{'subcom'}],"%.3f");
		
		print OUTPUT "\n";
	close OUTPUT;
	
	#write next line of temperature file
	open OUTPUT,">>".$configVals{socNas}."/payload".$fileObject{payload}."/.T".$fileObject{currentDate};
		print OUTPUT $newData{frameNumber}.",";
		print OUTPUT $newData{gps}[1].",";
		
		#print temperature data
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T00_Scint'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T01_Mag'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T02_ChargeCont'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T03_Battery'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T04_PowerConv'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T05_DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T06_Modem'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T07_Structure'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T08_Solar1'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T09_Solar2'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T10_Solar3'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T11_Solar4'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T12_TermTemp'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T13_TermBatt'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T14_TermCap'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'T15_CCStat'}{'subcom'}],"%.3f");
	
		print OUTPUT "\n";
	close OUTPUT;
	
	#write next line of current file
	open OUTPUT,">>".$configVals{socNas}."/payload".$fileObject{payload}."/.C".$fileObject{currentDate};
		print OUTPUT $newData{frameNumber}.",";
		print OUTPUT $newData{gps}[1].",";
		
		#print current data
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I00_TotalLoad'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I01_TotalSolar'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I02_Solar1'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I03_+DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I04_+XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I05_Modem'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I06_-XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'I07_-DPU'}{'subcom'}],"%.3f");
		
		print OUTPUT "\n";
	close OUTPUT;
	
	#write next line of voltage file
	open OUTPUT,">>".$configVals{socNas}."/payload".$fileObject{payload}."/.V".$fileObject{currentDate};
		print OUTPUT $newData{frameNumber}.",";
		print OUTPUT $newData{gps}[1].",";
		
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V00_VoltAtLoad'}{'subcom'}],"%.3f"); 
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V01_Battery'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V02_Solar1'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V03_+DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V04_+XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V05_Modem'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V06_-XRayDet'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V07_-DPU'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V08_Mag'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V09_Solar2'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V10_Solar3'}{'subcom'}],"%.3f");
		writeFormattedValue($newData{"hk"}[$dataTypes{'hk'}{'V11_Solar4'}{'subcom'}],"%.3f");
		
		print OUTPUT "\n";
	close OUTPUT;	
}

sub scaleData{
	my $input = $_[0];
	my $group = $_[1];
	my $subcom = $_[2];
	
	#lookup the variable name by subcom and group name. 
	my $varName=$varList{'subcoms'}{$group}[$subcom];
	
	#use the variable name to look up the scaling factor and offset
	my $scale=$dataTypes{$group}{$varName}{'fullScale'};
	my $offset=$dataTypes{$group}{$varName}{'offset'};
	
	#multiply input by the scaling factor, add offset and return
	return ($input*$scale)+$offset;
}

sub getSpectralData{ #gets slow and medium spectra.
	my $frameNum=$_[0];
	my $modIndex=$_[1];
	my $finalMod=$_[2];
	my $startWord=$_[3];
	my $numOfBins=$_[4];
	my $type=$_[5];
	my $frameRef=$_[6];
	
	my $frame = 0;
	my $valueSet = 0;
	my $frame_i = 0;
	my $line = 0;
	my $output = 0;
	my @frames;
	my @valueSets;
	
	open TEMP, ">>".$configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.new'.$type;
		print TEMP $frameNum." ";
		for(my $offset_i = 0; $offset_i < $numOfBins; $offset_i++){
			print TEMP hex($$frameRef[$startWord+$offset_i]).',';
		}
		print TEMP "\n";
	close TEMP;
	
	if($modIndex == $finalMod){#last frame for this set, check that we have 4 consecutive frames saved
		#read all the bin values
		open TEMP, "<".$configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.new'.$type;
			$frame_i=0;
			while($line=<TEMP>){
				chomp $line;
				($frame,$valueSet) = split / /,$line;
				push @frames, $frame;
				push @valueSets, $valueSet;
				$frame_i++;
			}
		close TEMP;
		
		#clear the temp file
		open TEMP, ">" . $configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.new'.$type;
		close TEMP;
		
		#make sure we have $finalMod+1 lines (need to count the 0 index)
		#and that the first line is the correct number of frames from the last line
		if($frame_i==($finalMod+1) and $frames[0]==($frames[$finalMod]-$finalMod)){
			$output=$frames[0].','.join("",@valueSets);
			chop $output;
			
			open SPEC, ">>".$configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.'.$type.$fileObject{'currentDate'};
				print SPEC $output;
				print SPEC "\n";
			close SPEC;
		}
	}
}

sub checkLimits{
   my ($dataRef, $modRef) = @_;
	
	#create an empty array for this frame in the alerts hash
	$alerts{$$dataRef{"frameNumber"}} = ();
	
	#calculate a formated time stamp
	my $rawTime = int($savedData{"Time"} / 1000); #convert from ms
	$rawTime = $rawTime % 86400; #get rid of any complete days
   my $hours = int($rawTime / 3600); #find complete hours
   $rawTime = $rawTime % 3600; #drop complete hours
   my $mins = int($rawTime / 60); #get complete minutes
   my $secs = int($rawTime % 60); #get leftover seconds
	my $time = sprintf("%02d:%02d:%02d", $hours, $mins, $secs);
   
   #foreach(keys %limits){print $_ . " = " .$limits{$_}."\n";}
   
	#read the limits file
	if(($$dataRef{"frameNumber"} % $configVals{"limCheckPeriod"}) == 0){
      getLimits();
   }
	
	#Check GPS 
   $alerts{$$dataRef{"frameNumber"}}{$varNames{"gps"}[$$modRef{"4"}]} = 
      checkDataPoint(
         $time,
         $$dataRef{"gps"}[$$modRef{"4"}],
         $limits{$varNames{"gps"}[$$modRef{"4"}] . "_Min"},
         $limits{$varNames{"gps"}[$$modRef{"4"}] . "_Max"}
      );

	#Check magnetometor
   $alerts{$$dataRef{"frameNumber"}}{"MAG_X"} = 
      checkDataPoint(
         $time, $$dataRef{"bx"}, $limits{"MAG_X_Min"}, $limits{"MAG_X_Max"}
      );
   $alerts{$$dataRef{"frameNumber"}}{"MAG_Y"} = 
      checkDataPoint(
         $time, $$dataRef{"by"}, $limits{"MAG_Y_Min"}, $limits{"MAG_Y_Max"}
      );
	$alerts{$$dataRef{"frameNumber"}}{"MAG_Z"} = 
      checkDataPoint(
         $time, $$dataRef{"bz"}, $limits{"MAG_Z_Min"}, $limits{"MAG_Z_Max"}
      );
		
	#Check Xray Counters
	$alerts{$$dataRef{"frameNumber"}}{"LC1"} = 
      checkDataPoint(
         $time, $$dataRef{"lc1"}, $limits{"LC1_Min"}, $limits{"LC1_Max"}
      );
	$alerts{$$dataRef{"frameNumber"}}{"LC2"} = 
      checkDataPoint(
         $time, $$dataRef{"lc2"}, $limits{"LC2_Min"}, $limits{"LC2_Max"}
      );
	$alerts{$$dataRef{"frameNumber"}}{"LC3"} = 
      checkDataPoint(
         $time, $$dataRef{"lc3"}, $limits{"LC3_Min"}, $limits{"LC3_Max"}
      );
   $alerts{$$dataRef{"frameNumber"}}{"LC4"} = 
      checkDataPoint(
         $time, $$dataRef{"lc4"}, $limits{"LC4_Min"}, $limits{"LC4_Max"}
      );

   #Check Rate Counters
   $alerts{$$dataRef{"frameNumber"}}{$varNames{"rc"}[$$modRef{"4"}]} = 
      checkDataPoint(
         $time,
         $$dataRef{"rc"}[$$modRef{"4"}], 
         $limits{$varNames{"rc"}[$$modRef{"4"}] . "_Min"},
         $limits{$varNames{"rc"}[$$modRef{"4"}] . "_Max"}
      );

	#Check Housekeeping data
   $alerts{$$dataRef{"frameNumber"}}{$varNames{"hk"}[$$modRef{"40"}]} = 
      checkDataPoint(
         $time,
         $$dataRef{"hk"}[$$modRef{"40"}],
         $limits{$varNames{"hk"}[$$modRef{"40"}] . "_Min"},
         $limits{$varNames{"hk"}[$$modRef{"40"}] . "_Max"}
      );
      
	#figure out the oldest accepted frame number
	my $oldFC = $$dataRef{"frameNumber"} - $configVals{"alertPeriod"};
	
   #create a list of printed alert variables
   my %printed = ();
   
   #Remove any records that are too old and print the rest
	open ALERTS, ">" . $configVals{"socNas"} . "/payload" . $fileObject{'payload'} . "/.errorlist";
	print ALERTS $fileObject{'payload'} . "\n";
   
   foreach my $fc (sort {$b <=> $a} keys %alerts){
      if($fc < $oldFC){
		  delete $alerts{$fc};
		}else{
         foreach my $key (sort keys $alerts{$fc}){
            #check if we already printed an alert for this variable
            unless($printed{$key} == 1 or $alerts{$fc}{$key} eq ""){   
               $printed{$key} = 1;
               print ALERTS $key . " - " . $alerts{$fc}{$key};
            }
         }
		}
	}
   
   #Check to see if there was an alert printed for gps altitude
   if((0 + $savedData{"GPS_Alt"}) < $limits{"GPS_Alt_Min"}){
      print ALERTS
		   "Altitude Low (" . $savedData{"GPS_Alt"} . ")! - " . $time . " \n";
      $printed{'altitude'} = 1;
   }
   
   #check for high sink rate
   if($$dataRef{"ascentRate"} < $configVals{"maxSinkRate"}){
      print ALERTS "Sinking! - " . $time . " \n";
      $printed{'sink'} = 1;
   }
   
   #check to see if any red flags were set. If so, we need to check the timer
   if(
      ($printed{'altitude'} != 1) &&
      ($printed{'sink'} != 1)
   ){
      #Make sure the red alert timer is clear
      $fileObject{'firstRedTime'} = 0;
   }else{
      redFlagTimer();
   }
   
   #check to see if we printed any alerts
   if(scalar keys %printed == 0){print ALERTS "OK";}
	close ALERTS;
}

sub checkDataPoint{
   my ($time, $data, $min, $max) = @_;
	
   if($data < $min){
      return "Low - " . $time . " \n";
   }elsif($data > $max){
      return "High - " . $time . " \n";
   }
	
	return "";
}

sub getLimits{
   foreach my $type (keys %dataTypes){
      if(!open LIMITS, "<".$configVals{"socNas"}."/datafiles/".$type."Config"){
         #could not open limits file
         next;
      }
      while(my $line = <LIMITS>){
         if($line =~ /$fileObject{'payload'}/){ #search for section for current payload
            while($line = <LIMITS>) {
               if($line =~ /}/){
                  #search for ending brace
                  last;
               }
               
               #Remove trailing newline, remove all whitespace, remove all quote marks and commas
               $line =~ s/\s//g;
               $line =~ s/"//g;
               $line =~ s/,//g;
               
               #get the key/value pair
               my @pair = split ":", $line;
               
               #save to the global alert hash
               unless($pair[0] eq ""){
                  $limits{$pair[0]} = $pair[1];
               }
            }
            #done with payload for this file
            last;
         }
      }
   }
}

sub redFlagTimer{
   #check to see if this is the first red flag detection
   if($fileObject{'firstRedTime'} == 0){
      $fileObject{'firstRedTime'} = time();
   }else{
      #check how long we have had a red flag for
      if((time() - $fileObject{'firstRedTime'}) > $configVals{'redFlagWait'}){
         
         #find the last time the mission monitor hit the clear button
         open TIMER,
            "<" . $configVals{'socNas'}. "/payload" . $fileObject{'payload'} .
            "/.alertTimer";
            my $clearTime = <TIMER>;
            chomp $clearTime;
         close TIMER;
         
         #check how long it has been since the button was clicked
         if((time() - $clearTime) > $configVals{'redFlagWait'}){
            #The MM has not hit the clear button in a while, send a text message
            
            my @contacts = ();
            
            open CONTACT, "<" . $configVals{'socNas'}. "/datafiles/dsContact";
               while(my $line = <CONTACT>){
                  chomp $line;
                  push @contacts, $dsContact{$line};
               }
            close CONTACT;
            
            my $message = "Red flag on payload " . $fileObject{'payload'} . "!";
            foreach(@contacts){`echo \"$message\" | mailx $_`;}
            
            #Reset the red alert timer
            $fileObject{'firstRedTime'} = 0;
         }else{
            #the clear button was clicked recently enough
            #update the first detection time
            $fileObject{'firstRedTime'} = $clearTime;
         }
      }else{
         my $diff = time() - $fileObject{'firstRedTime'};
      }
   }
}

sub newDataFiles{ #creates a fresh set of data files for the new data with a header printed for each data type
	my $header = "";
	
	$header = "frameGroup";
	for($header_i = 1; $header_i <= 48; $header_i++){
		$header = $header . ",bin" . $header_i;
	}
	writeFile($configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.medspec'.$fileObject{'currentDate'},$header."\n");
	
	$header = "frameGroup";
	for($header_i = 1; $header_i <= 256; $header_i++){
		$header = $header . ",bin" . $header_i;
	}
	writeFile($configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.slowspec'.$fileObject{'currentDate'}, $header."\n");
	
	$header = 'Frames,Time,GPS_Lat,GPS_Lon,GPS_Alt,LowLevel,PeakDet,HighLevel,Interrupt,MAG_X,MAG_Y,MAG_Z,LC1,LC2,LC3,LC4,GPS_PPS'."\n";
	writeFile($configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.datasci'.$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,'.
		'T00_Scint,T01_Mag,T02_ChargeCont,T03_Battery,T04_PowerConv,T05_DPU,T06_Modem,T07_Structure,T08_Solar1,T09_Solar2,T10_Solar3,T11_Solar4,T12_TermTemp,T13_TermBatt,T14_TermCap,T15_CCStat,'.
		'V0_VoltAtLoad,V01_Battery,V02_Solar1,V03_+DPU,V04_+XRayDet,V05_Modem,V06_-XRayDet,V07_-DPU,V08_Mag,V09_Solar2,V10_Solar3,V11_Solar4,'.
		'I0_TotalLoad,I01_TotalSolar,I02_Solar1,I03_+DPU,I04_+XRayDet,I05_Modem,I06_-XRayDet,I07_-DPU'."\n";
	writeFile($configVals{'socNas'}.'/payload'.$fileObject{'payload'}.'/.datahouse'.$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,GPS_Lat,GPS_Lon,GPS_Alt,GPS_PPS'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.gps".$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,LowLevel,PeakDet,HighLevel,Interrupt'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.rc".$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,MAG_X1,MAG_X2,MAG_X3,MAG_X4,MAG_X_Ave,MAG_Y1,MAG_Y2,MAG_Y3,MAG_Y4,MAG_Y_Ave,MAG_Z1,MAG_Z2,MAG_Z3,MAG_Z4,MAG_Z_Ave'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.mag".$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,LC1,LC2,LC3,LC4'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.lc".$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,T00_Scint,T01_Mag,T02_ChargeCont,T03_Battery,T04_PowerConv,T05_DPU,T06_Modem,T07_Structure,T08_Solar1,T09_Solar2,T10_Solar3,T11_Solar4,T12_TermTemp,T13_TermBatt,T14_TermCap,T15_CCStat'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.T".$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,I00_TotalLoad,I01_TotalSolar,I02_Solar1,I03_+DPU,I04_+XRayDet,I05_Modem,I06_-XRayDet,I07_-DPU'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.C".$fileObject{'currentDate'}, $header);
	
	$header = 'Frames,Time,V00_VoltAtLoad,V01_Battery,V02_Solar1,V03_+DPU,V04_+XRayDet,V05_Modem,V06_-XRayDet,V07_-DPU,V08_Mag,V09_Solar2,V10_Solar3,V11_Solar4'."\n";
	writeFile($configVals{'socNas'}."/payload".$fileObject{'payload'}."/.V".$fileObject{'currentDate'}, $header);
	
	return;
}

sub writeFile{
	my $path=$_[0];
	my $contents=$_[1];
	
	open FILE, ">".$path or print "Couldn't write to ".$path."\n";
		print FILE $contents;
	close FILE;
}

sub writeValue{
	my $value=$_[0];
	if($value ne ""){# if there is data in this variable, print it or print "--" to indicate missing value
		print OUTPUT $value;
	}
	else{
		print  OUTPUT "--";
	}
	print OUTPUT ",";
}

sub writeFormattedValue{ #exactly like writeValue(), but with printf
	my ($value,$format)=@_;
	if($value ne ""){									
		printf OUTPUT $format,$value;									
	}
	else{
		print  OUTPUT "--";			
	}	
	print OUTPUT ",";
}

sub saveNewValue{  #Add the newly translated values to the %savedData hash
	my ($value,$key)=@_;
	if($value ne ""){									
		$savedData{$key}=$value;					
	}
	else{									 
		$savedData{$key}=(1*$savedData{$key})."*";							
	}		
	print OUTPUT ",";
}

sub saveFormattedNewValue{  #Add the newly translated values to the %savedData hash
	my ($value,$key,$format)=@_;
	if($value ne ""){									
		$savedData{$key}=sprintf $format,$value;					
	}
	else{									 
		$savedData{$key}=(1*$savedData{$key})."*";							
	}		
	print OUTPUT ",";
}

sub ieeeconv {
	my $num=@_[0];
	
	my $sign = $num >> 31;
	if ($sign==0){$sign=1;}
	else {$sign=-1;}
	
	my $exponent = (($num & 0b1111111100000000000000000000000) >> 23) - 127;

	my $mantissa = $num & 0b11111111111111111111111;
	my ($sum,$i) = 0;
	while($i<23){
		if ((($mantissa >> $i) & 1) == 1){$sum+=2**(-1*(23-$i));}
		$i++;
	}
	$sum+=1;

	return $sign * 2**$exponent * $sum;
}

init();
for(;;){ #loop forever
	mainLoop();
}
