package SOC_config;
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(%dsContact %modValues %subcomValues %payloadLabels %configVals %dataTypes @payloads @statusVars @sciVars @tempVars @voltVars @currentVars @houseVars @slowSpectraWidths @medSpectraWidths);

our @payloads = qw(1Z 2A 2B 2C 2D 2E 2F 2G 2H 2I 2J 2K 2L 2M 2N 2O 2P 2Q 2R 2S 1E 1F 1P 1X 1Y 2U 2V 2W 2X 2Y 2Z);

our %dsContact = (
    'Warren' => '4083903235@txt.att.net',
);

our %dataTypes = (
	'frames' => {
		'frameNumber' => {
			"mux" => 1,
			"subcom" => 0,
			"noplot" => 1,
			"listOrder" => -1 
		}
	},
	'gps' => {
		'Time' => {
			"mux" => 4,
			"subcom" => 1,
			"noplot" => 1,
			"listOrder" => -1,
			"fullScale" => 1
		},
		'GPS_Lat' => {
			"mux" => 4,
			"subcom" => 2,
			"listOrder" => 7,
			"fullScale" => 8.38190317154*10**-8
		},
		'GPS_Lon' => {
			"mux" => 4,
			"subcom" => 3,
			"listOrder" => 8,
			"fullScale" => 8.38190317154*10**-8
		},
		'GPS_Alt' => {
			"mux" => 4,
			"subcom" => 0,
			"listOrder" => 9,
			"fullScale" => 10**-6
		}
	},
	'rc' => {
		'LowLevel' => {
			"mux" => 4,
			"subcom" => 1,
			"listOrder" => 10
		},
		'PeakDet' => {
			"mux" => 4,
			"subcom" => 2,
			"listOrder" => 11
		},
		'HighLevel' => {
			"mux" => 4,
			"subcom" => 3,
			"listOrder" => 12
		},
		'Interrupt' => {
			"mux" => 4,
			"subcom" => 0,
			"listOrder" => 13
		}
	},
	'mag' => {
		'MAG_X' => {
			"mux" => 1,
			"subcom" => 0,
			"fullScale" => 1/83886.070,
			"offset" => 100.000012,
			"listOrder" => 4
		},
		'MAG_Y' => {
			"mux" => 1,
			"subcom" => 0,
			"fullScale" => 1/83886.070,
			"offset" => 100.000012,
			"listOrder" => 5
		},
		'MAG_Z' => {
			"mux" => 1,
			"subcom" => 0,
			"fullScale" => 1/83886.070,
			"offset" => 100.000012,
			"listOrder" => 6
		}
	},
	'lc' => {
		'LC1' => {
			"mux" => 1,
			"subcom" => 0,
			"listOrder" => 0
		},
		'LC2' => {
			"mux" => 1,
			"subcom" => 0,
			"listOrder" => 1
		},
		'LC3' => {
			"mux" => 1,
			"subcom" => 0,
			"listOrder" => 2
		},
		'LC4' => {
			"mux" => 1,
			"subcom" => 0,
			"listOrder" => 3
		}
	},
	'pps' => {
		'GPS_PPS' => {
			"mux" => 1,
			"subcom" => 0,
			"noplot" => 1,
			"listOrder" => -1
		}
	},
	'hk' => {
		'T00_Scint' => {
			"mux" => 40,
			"subcom" => 16,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 14
		},
		'T01_Mag' => {
			"mux" => 40,
			"subcom" => 18,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 15
		},
		'T02_ChargeCont' => {
			"mux" => 40,
			"subcom" => 20,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 16
		},
		'T03_Battery' => {
			"mux" => 40,
			"subcom" => 22,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 17
		},
		'T04_PowerConv' => {
			"mux" => 40,
			"subcom" => 24,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 18
		},
		'T05_DPU' => {
			"mux" => 40,
			"subcom" => 26,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 19
		},
		'T06_Modem' => {
			"mux" => 40,
			"subcom" => 28,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 20
		},
		'T07_Structure' => {
			"mux" => 40,
			"subcom" => 30,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 21
		},
		'T08_Solar1' => {
			"mux" => 40,
			"subcom" => 17,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 22
		},
		'T09' => {
			"mux" => 40,
			"subcom" => 19,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 23
		},
		'T10_Solar3' => {
			"mux" => 40,
			"subcom" => 21,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 24
		},
		'T11' => {
			"mux" => 40,
			"subcom" => 23,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 25
		},
		'T12_TermTemp' => {
			"mux" => 40,
			"subcom" => 25,
			"fullScale" => 0.007629,
			"offset" => -273.15,
			"listOrder" => 26
		},
		'T13_TermBatt' => {
			"mux" => 40,
			"subcom" => 27,
			"fullScale" => 0.0003052,
			"listOrder" => 27
		},
		'T14_TermCap' => {
			"mux" => 40,
			"subcom" => 29,
			"fullScale" => 0.0003052,
			"listOrder" => 28
		},
		'T15_CCStat' => {
			"mux" => 40,
			"subcom" => 31,
			"fullScale" => 0.0001526,
			"listOrder" => 29
		},
		'V00_VoltAtLoad' => {
			"mux" => 40,
			"subcom" => 0,
			"fullScale" => 0.0003052,
			"listOrder" => 30
		},
		'V01_Battery' => {
			"mux" => 40,
			"subcom" => 2,
			"fullScale" => 0.0003052,
			"listOrder" => 31
		},
		'V02_Solar1' => {
			"mux" => 40,
			"subcom" => 4,
			"fullScale" => 0.0006104,
			"listOrder" => 32
		},
		'V03_+DPU' => {
			"mux" => 40,
			"subcom" => 6,
			"fullScale" => 0.0001526,
			"listOrder" => 33
		},
		'V04_+XRayDet' => {
			"mux" => 40,
			"subcom" => 8,
			"fullScale" => 0.0001526,
			"listOrder" => 34
		},
		'V05_Modem' => {
			"mux" => 40,
			"subcom" => 10,
			"fullScale" => 0.0003052,
			"listOrder" => 35
		},
		'V06_-XRayDet' => {
			"mux" => 40,
			"subcom" => 12,
			"fullScale" => -0.0001526,
			"listOrder" => 36
		},
		'V07_-DPU' => {
			"mux" => 40,
			"subcom" => 14,
			"fullScale" => -0.0001526,
			"listOrder" => 37
		},
		'V08_Mag' => {
			"mux" => 40,
			"subcom" => 32,
			"fullScale" => 0.0001526,
			"listOrder" => 38
		},
		'V09_Solar2' => {
			"mux" => 40,
			"subcom" => 33,
			"fullScale" => 0.0006104,
			"listOrder" => 39
		},
		'V10_Solar3' => {
			"mux" => 40,
			"subcom" => 34,
			"fullScale" => 0.0006104,
			"listOrder" => 40
		},
		'V11_Solar4' => {
			"mux" => 40,
			"subcom" => 35,
			"fullScale" => 0.0006104,
			"listOrder" => 40
		},
		'I00_TotalLoad' => {
			"mux" => 40,
			"subcom" => 1,
			"fullScale" => 0.050863406,,
			"listOrder" => 41
		},
		'I01_TotalSolar' => {
			"mux" => 40,
			"subcom" => 3,
			"fullScale" => 0.061036087,
			"listOrder" => 42
		},
		'I02_Solar1' => {
			"mux" => 40,
			"subcom" => 5,
			"fullScale" => 0.061036087,
			"listOrder" => 43
		},
		'I03_+DPU' => {
			"mux" => 40,
			"subcom" => 7,
			"fullScale" => 0.010172681,
			"listOrder" => 44
		},
		'I04_+XRayDet' => {
			"mux" => 40,
			"subcom" => 9,
			"fullScale" => 0.0010172681,
			"listOrder" => 45
		},
		'I05_Modem' => {
			"mux" => 40,
			"subcom" => 11,
			"fullScale" => 0.050863406,
			"listOrder" => 46
		},
		'I06_-XRayDet' => {
			"mux" => 40,
			"subcom" => 13,
			"fullScale" => -0.000126107,
			"listOrder" => 47
		},
		'I07_-DPU' => {
			"mux" => 40,
			"subcom" => 15,
			"fullScale" => -0.0010172681,
			"listOrder" => 48
		}
	},
	'status' => {
		'version' => {
			"mux" => 1,
			"subcom" => 0,
			"listOrder" => -1
		},
		'numOfSats' => {
			"mux" => 40,
			"subcom" =>36,
			"listOrder" => -1
		},
		'timeOffset' => {
			"mux" => 40,
			"subcom" =>36,
			"listOrder" => -1
		},
		'termStatus' => {
			"mux" => 40,
			"subcom" =>38,
			"listOrder" => -1
		},
		'cmdCounter' => {
			"mux" => 40,
			"subcom" =>38,
			"listOrder" => -1
		},
		'modemCounter' => {
			"mux" => 40,
			"subcom" =>39,
			"listOrder" => -1
		},
		'dcdCounter' => {
			"mux" => 40,
			"subcom" =>39,
			"listOrder" => -1
		},
		'weeks' => {
			"mux" => 40,
			"subcom" =>37,
			"listOrder" => -1
		}
	}
);

our %payloadLabels = (  #list of payload names with numerical indices
	"1Z" => 1,
	"2A" => 2,
	"2B" => 3,
	"2C" => 4,
	"2D" => 5,
	"2E" => 6,
	"2F" => 7,
	"2G" => 8,
	"2H" => 9,
	"2I" => 10,
	"2J" => 11,
	"2K" => 12,
	"2L" => 13,
	"2M" => 14,
	"2N" => 15,
	"2O" => 16,
	"2P" => 17,
	"2Q" => 18,
	"2R" => 19,
	"2S" => 20,
	"1E" => 21,
	"1F" => 22,
	"1P" => 23,
	"1X" => 24,
	"1Y" => 25,
	"2U" => 26,
	"2V" => 27,
	"2W" => 28,
	"2X" => 29,
	"2Y" => 30,
  	"2Z" => 31
);

our %configVals = (
	#General Config
	revNum         => 'rev-13.01.25',
	adminPass	=> 'BaRR3L2013',
	socMode             => 1, #1 for private SOC, 2 for public SOC
	tmp            => "/var/tmp",
	socNas				=> "/mnt/soc-nas",
	mocNas			=> "/mnt/moc-nas/barrel",
	webDir              => "/var/www",
	numOfPayloads       => scalar(keys(%payloadLabels)),
	
	#coordGen.pl Config
	#coordSleepTime      => 300, #number of seconds to wait between loops
	#coordFrameSkip      => 400, #number of frames to skip before looking for a complete set of coordinates
	
   #statsBan.pl Config
   popups              => "true", #turns red alert popups on and off
   
	#updater.pl Config
	updaterSleepTime  => 4, # number of seconds to wait after running out of new data
	archive				=> "on",
	timefill				=> "on",
	frameLength			=> (107-1), #number of words/frame minus the sync word.
	spectraCal        => 1, #kev/channel
   alertPeriod       => 2700, #number of seconds to retain alerts
   limCheckPeriod    => 100, #how many frames to read before rechecking limits file
   timeout           => 900, #number of seconds to wait before flagging a timeout on a payload
   maxSinkRate       => -10, #How fast the payload can drop (in m/s) before setting red alert (negative speeds indicate sink)
   redFlagWait       => 300,
   
	#updater.pl Full Scale Values
   fullscaleTemp0      => 0.007629,
	fullscaleTemp1      => 0.007629,
	fullscaleTemp2      => 0.007629,
	fullscaleTemp3      => 0.007629,
	fullscaleTemp4      => 0.007629,
	fullscaleTemp5      => 0.007629,
	fullscaleTemp6      => 0.007629,
	fullscaleTemp7      => 0.007629,
	fullscaleTemp8      => 0.007629,
	fullscaleTemp9      => 0.007629,
	fullscaleTemp10     => 0.007629,
	fullscaleTemp11     => 0.007629,
	fullscaleTemp12     => 0.007629,
	fullscaleTemp13     => 0.0003052,
	fullscaleTemp14     => 0.0003052,
	fullscaleTemp15     => 0.0001526,
	fullscaleVolt0      => 0.0003052,
	fullscaleVolt1      => 0.0003052,
	fullscaleVolt2      => 0.0006104,
	fullscaleVolt3      => 0.0001526,
	fullscaleVolt4      => 0.0001526,
	fullscaleVolt5      => 0.0003052,
	fullscaleVolt6      =>-0.0001526,
	fullscaleVolt7      =>-0.0001526,
	fullscaleVolt8      => 0.0001526,
	fullscaleVolt9      => 0.0006104,
	fullscaleVolt10     => 0.0006104,
	fullscaleVolt11     => 0.0006104,
	fullscaleCur0       => 0.050863406,
	fullscaleCur1       => 0.061036087,
	fullscaleCur2       => 0.061036087,
	fullscaleCur3       => 0.010172681, 
	fullscaleCur4       => 0.0010172681,
	fullscaleCur5       => 0.050863406,
	fullscaleCur6       =>-0.000126107,
	fullscaleCur7       =>-0.0010172681
);

our @statusVars = qw(version numOfSats timeOffset termStatus cmdCounter modemCounter dcdCounter weeks);
our @sciVars = qw(Frames Time GPS_Lat GPS_Lon GPS_Alt LowLevel PeakDet HighLevel Interrupt MAG_X MAG_Y MAG_Z LC1 LC2 LC3 LC4 GPS_PPS);
our @tempVars = qw(T0_Scint T1_Mag T2_ChargeCont T3_Battery T4_PowerConv T5_DPU T6_Modem T7_Structure T8_Solar1 T9_Solar2 T10_Solar3 T11_Solar4 T12_TermTemp T13_TermBatt T14_TermCap T15_CCStat);
our @voltVars = ('V0_VoltAtLoad','V1_Battery','V2_Solar1','V3_+DPU','V4_+XRayDet','V5_Modem','V6_-XRayDet','V7_-DPU','V8_Mag','V9_Solar2','V10_Solar3','V11_Solar4');
our @currentVars = ('I0_TotalLoad','I1_TotalSolar','I2_Solar1','I3_+DPU','I4_+XRayDet','I5_Modem','I6_-XRayDet','I7_-DPU');
our @houseVars = ("Frames","Time",@tempVars,@voltVars,@currentVars);

our %subcomValues = (
	'Frames'	=>	0,
	'Time'		=>	1,
	'GPS_Lat'	=>	2,
	'GPS_Lon'	=>	3,
	'GPS_Alt'	=>	0,
	'LowLevel'  	=>	1,
	'PeakDet'	=>	2,
	'HighLevel'	=>	3,
	'Interrupt'	=>	0,
	'MAG_X'		=>	0,
	'MAG_Y'		=>	0,
	'MAG_Z'		=>	0,
	'LC1'		=>	0,
	'LC2'		=>	0,
	'LC3'		=>	0,
	'LC4'		=>	0,
	'ADC_TEMP' 	=>	0,
	'MAG_OFFSET'	=>	1,
	'GPS_PPS'	=>	0,
	'T0_Scint'	=>	16,
	'T1_Mag'	=>	18,
	'T2_ChargeCont'	=>	20,
	'T3_Battery'	=>	22,
	'T4_PowerConv'	=>	24,
	'T5_DPU'	=>	26,
	'T6_Modem'	=>	28,
	'T7_Structure'	=>	30,
	'T8_Solar1'	=>	17,
	'T9_Solar2'	=>	19,
	'T10_Solar3'	=>	21,
	'T11_Solar4'	=>	23,
	'T12_TermTemp'	=>	25,
	'T13_TermBatt'	=>	27,
	'T14_TermCap'	=>	29,
	'T15_CCStat'	=>	31,
	'V0_VoltAtLoad'	=>	0,
	'V1_Battery'	=>	2,
	'V2_Solar1'	=>	4,
	'V3_+DPU'	=>	6,
	'V4_+XRayDet'	=>	8,
	'V5_Modem'	=>	10,
	'V6_-XRayDet'	=>	12,
	'V7_-DPU'	=>	14,
	'V8_Mag'	=>	32,
	'V9_Solar2'	=>	33,
	'V10_Solar3'	=>	34,
	'V11_Solar4'	=>	35,
	'I0_TotalLoad'	=>	1,
	'I1_TotalSolar'	=>	3,
	'I2_Solar1'	=>	5,
	'I3_+DPU'	=>	7,
	'I4_+XRayDet'	=>	9,
	'I5_Modem'	=>	11,
	'I6_-XRayDet'	=>	13,
	'I7_-DPU'	=>	15,
);

our %modValues = (
	'Frames'	=>	1,
	'Time'		=>	1,
	'GPS_Lat'	=>	4,
	'GPS_Lon'	=>	4,
	'GPS_Alt'	=>	4,
	'LowLevel'	=>	4,
	'PeakDet'	=>	4,
	'HighLevel'	=>	4,
	'Interrupt'	=>	4,
	'MAG_X'		=>	1,
	'MAG_Y'		=>	1,
	'MAG_Z'		=>	1,
	'LC1'		=>	1,
	'LC2'		=>	1,
	'LC3'		=>	1,
	'LC4'		=>	1,
	'ADC_TEMP'	=>	2,
	'MAG_OFFSET'	=>	2,
	'GPS_PPS'	=>	1,
	'T0_Scint'	=>	40,
	'T1_Mag'	=>	40,
	'T2_ChargeCont'	=>	40,
	'T3_Battery'	=>	40,
	'T4_PowerConv'	=>	40,
	'T5_DPU'	=>	40,
	'T6_Modem'	=>	40,
	'T7_Structure'	=>	40,
	'T8_Solar1'	=>	40,
	'T9_Solar2'	=>	40,
	'T10_Solar3'	=>	40,
	'T11_Solar4'	=>	40,
	'T12_TermTemp'	=>	40,
	'T13_TermBatt'	=>	40,
	'T14_TermCap'	=>	40,
	'T15_CCStat'	=>	40,
	'V0_VoltAtLoad'	=>	40,
	'V1_Battery'	=>	40,
	'V2_Solar1'	=>	40,
	'V3_+DPU'	=>	40,
	'V4_+XRayDet'	=>	40,
	'V5_Modem'	=>	40,
	'V6_-XRayDet'	=>	40,
	'V7_-DPU'	=>	40,
	'V8_Mag'	=>	40,
	'V9_Solar2'	=>	40,
	'V10_Solar3'	=>	40,
	'V11_Solar4'	=>	40,
	'I0_TotalLoad'	=>	40,
	'I1_TotalSolar'	=>	40,
	'I2_Solar1'	=>	40,
	'I3_+DPU'	=>	40,
	'I4_+XRayDet'	=>	40,
	'I5_Modem'	=>	40,
	'I6_-XRayDet'	=>	40,
	'I7_-DPU'	=>	40,
);

#set channels/bin for slow spectrum
our @slowSpectraWidths = ();
for(my $ssw_i = 0; $ssw_i < 64; $ssw_i++){$slowSpectraWidths[$ssw_i] = 1;}
for(my $ssw_i = 64; $ssw_i < 96; $ssw_i++){$slowSpectraWidths[$ssw_i] = 2;}
for(my $ssw_i = 96; $ssw_i < 128; $ssw_i++){$slowSpectraWidths[$ssw_i] = 4;}
for(my $ssw_i = 128; $ssw_i < 160; $ssw_i++){$slowSpectraWidths[$ssw_i] = 8;}
for(my $ssw_i = 160; $ssw_i < 192; $ssw_i++){$slowSpectraWidths[$ssw_i] = 16;}
for(my $ssw_i = 192; $ssw_i < 224; $ssw_i++){$slowSpectraWidths[$ssw_i] = 32;}
for(my $ssw_i = 224; $ssw_i < 256; $ssw_i++){$slowSpectraWidths[$ssw_i] = 64;}
	

#set channels/bin for medium spectrum
our @medSpectraWidths = (4, 4, 3, 4, 3, 4, 6, 8, 6, 8, 8, 6, 8, 6, 8, 12, 16, 12, 16, 16, 12,
			16, 12, 16, 24, 32, 24, 32, 32, 24, 32, 24, 32, 48, 64, 48, 64,
			64, 48, 64, 48, 64, 96, 128, 96, 128, 128, 96);

