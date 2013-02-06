package SOC_funcs;
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(getEnabledPayloads getDirListing getdata splitdata writeToLog getCgiInput getVarInfo getCrossRef);

sub getEnabledPayloads{
	open(ENABLELIST,"$configVals{socNas}/datafiles/enablelist") or print "Can't open list of active payloads\n";
	my ($line,$payloadName,$switch)="";
	my @enabledPayloads=();
	
	while(chomp($line=<ENABLELIST>))
	{
		($payloadName,$switch)=split /,/, $line;
		if ($switch == 1){push @enabledPayloads, $payloadName;}
	}
	close(ENABLELIST);

	return @enabledPayloads;
}

sub getdata{
	my ($sciOrHouse,$datafile,$numOfFrames)=@_;
	my $line="";
	my @data=();
	my $i=0;
	my $fh = File::ReadBackwards->new("$mainDir/payload$payNum/$datafile");
	
	while (defined($line = $fh->readline))
	{
		 $data[$i]=$line;
		if ($i==$numOfFrames){last;}
		$i++;
	}
	
	@data=reverse(@data);
	unshift(@{"$sciOrHouse"},@data);	
}

sub splitdata{
	my $sciOrHouse=@_[0];
	my $line="";
	my ($null,$houseFrames)="";
	
	$line=shift(@{"$sciOrHouse"});
	if ($sciOrHouse eq "sci")
	{
		my $i=0;
		while(@{"$sciOrHouse"})
		{
			$line=shift(@{"$sciOrHouse"});
			($frames[$i],$sciTime[$i],${"gpslat"}[$i],${"gpslon"}[$i],${"gpsalt"}[$i],${"ll"}[$i],${"pd"}[$i],${"hl"}[$i],${"irq"}[$i],${"tcmx"}[$i],${"tcmy"}[$i],${"tcmz"}[$i],${"LC1"}[$i],${"LC2"}[$i],${"LC3"}[$i],${"LC4"}[$i],${"pitch"}[$i],${"roll"}[$i],${"adcTemp"}[$i],${"magOffset"}[$i],${"pps"}[$i])=split(/	+/,$line);
			unless ($frames[$i]==0 || $frames[$i] eq "") {$i++;}
		}
	}

	if ($sciOrHouse eq "house")
	{
		my $i=0;
		while(@{"$sciOrHouse"})
		{
			$line=shift(@{"$sciOrHouse"});
			($houseFrame,$houseTime[$i],${"T0"}[$i],${"T1"}[$i],${"T2"}[$i],${"T3"}[$i],${"T4"}[$i],${"T5"}[$i],${"T6"}[$i],${"T7"}[$i],${"T8"}[$i],${"T9"}[$i],${"T10"}[$i],${"T11"}[$i],${"T12"}[$i],${"V0"}[$i],${"V1"}[$i],${"V2"}[$i],${"V3"}[$i],${"V4"}[$i],${"V5"}[$i],${"V6"}[$i],${"V7"}[$i],${"V8"}[$i],${"V9"}[$i],${"V10"}[$i],${"V11"}[$i],${"V12"}[$i],${"V13"}[$i],${"V14"}[$i],${"I0"}[$i],${"I1"}[$i],${"I2"}[$i],${"I3"}[$i],${"I4"}[$i],${"I5"}[$i],${"I6"}[$i],${"I7"}[$i])=split(/	+/,$line);
			unless ($houseFrame==0 || $houseFrame eq "") {$i++;}
		}		
	}
}

sub writeToLog{
	my $message=$_[0];
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = 1900 + $yearOffset;
	$message= $month.'/'.$dayOfWeek.'/'.$year.' '.$hour.':'.$minute.':'.$second.' - '.$message;
	
	`echo $message >> $configVals{socNas}/datafiles/activLog`;
}

sub getDirListing{
	my @listing;
	my ($location, $testType, $fileExt) = @_;

	opendir(FILELIST,$location) or die $!;	
	
	foreach(readdir FILELIST){				
		if ($testType eq "dir" and -d $location.$_){#if we are looking for a directory, push directories onto the stack
		   if($_ ne "." && $_ ne ".."){
		      push @listing, $_;
		   }
		} 
		
		elsif ($testType eq "file" and -f $location.$_){ #if we are looking for regular files, check if we only want a certain file extension type
			if ($_=~m/$fileExt$/){push @listing,$_;}
		}
	}
	closedir FILELIST;
	
	return sort @listing;
}

#takes 1 argument. if it is equal to "post" it will assume input from stdin, otherwise it will look for a query string
sub getCgiInput{
	my $input = "";
	my %output = ();
	
	if($_[0] eq "post"){
		$input = <STDIN>;
	}elsif($_[0] eq "get"){ 
	   $input = $ENV{'QUERY_STRING'}; 
	}else{
	   unless($input = $ENV{'QUERY_STRING'}){
	      $input = <STDIN>;
	   }
	}
	
	if ($input) {
		foreach my $pair (split(/&/, $input)){
		   if($pair =~ /%/){
		      $pair =~ s/%21/!/;
		      $pair =~ s/%23/#/;
		      $pair =~ s/%24/\$/;
		      $pair =~ s/%26/&/;
		      $pair =~ s/%27/'/;
		      $pair =~ s/%28/(/;
		      $pair =~ s/%29/)/;
		      $pair =~ s/%2A/*/;
		      $pair =~ s/%2B/+/;
		      $pair =~ s/%2C/,/;
		      $pair =~ s/%2F/\//;
		      $pair =~ s/%3A/:/;
		      $pair =~ s/%3B/\;/;
		      $pair =~ s/%3D/=/;
		      $pair =~ s/%3F/?/;
		      $pair =~ s/%40/\@/;
		      $pair =~ s/%5B/[/;
		      $pair =~ s/%5D/]/;
		   }
		   my ($keyPath,$val) = split(/=/, $pair);
		   my $hashPath = '$output{\'' . join('\'}{\'', split(/\*/, $keyPath)) . '\'}';
			eval ($hashPath . ' = "' . $val . '";');
		}
		
		return \%output;
	}
	else{
		return 0;
	}

}


# writes a hash to the $outputRef location that contains the variables listed 3 ways:
# @{$outputRef}{vars} is a list of variables as described by the "listorder" key in  %dataTypes
# %{$outputRef}{groups} is a hash whose keys are variable names and values are group names
# %{$outputRef}{subcoms} is a hash whose keys are variable names and values are the subcom
sub getVarInfo{
	my %input=%{$_[0]};
	my $outputRef=$_[1];
	my (@vars,@tempTypes,@tempVars) = ();
	my (%groups,%subcoms)=();
	my ($type_i, $var_i, $list_i) = 0;
	
	@tempTypes = sort keys %input;
	for($type_i = 0; $type_i < scalar @tempTypes; $type_i++){
	   @tempVars=sort keys %{$input{$tempTypes[$type_i]}};
	   for($var_i=0; $var_i < scalar @tempVars; $var_i++){
	      
	      #get variable list
	      $list_i=$input{$tempTypes[$type_i]}{$tempVars[$var_i]}{'listOrder'};
	      if($list_i != -1){
		$vars[$list_i]=$tempVars[$var_i];
	      }
	      
	      #get subcom list
	      $subcom_i=$input{$tempTypes[$type_i]}{$tempVars[$var_i]}{'subcom'};
	      ${$subcoms{$tempTypes[$type_i]}}[$subcom_i]=$tempVars[$var_i];
	      
	      #get group list
	      $groups{$tempVars[$var_i]}=$tempTypes[$type_i];
	   }
	}
	
	@{${$outputRef}{'vars'}}=@vars;
	%{${$outputRef}{'groups'}}=%groups;
	%{${$outputRef}{'subcoms'}}=%subcoms;
	
	return;
}

1;

