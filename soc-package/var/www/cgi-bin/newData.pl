#!/usr/bin/perl

use SOC_config qw(%dataTypes %payloadLabels %configVals @payloads);

print "Content-Type: text/html \n\n";

our ($payload, $null);

#Get payload label
($null,$payload) = split /=/,$ENV{'QUERY_STRING'};

#get data limits
my %lims = ();
$lims{'mag'} = getlimits("mag");
$lims{'lc'} = getlimits("lc");
$lims{'gps'} = getlimits("gps");
$lims{'rc'} = getlimits("rc");
$lims{'hk'} = getlimits("hk");

sub getlimits{
	my $type=$_[0];
	my $limits;
	
	open LIMITS, $configVals{socNas}."/datafiles/".$type."Config" 
	   or print "Can't open config file!<br />";
      while(my $line = <LIMITS>){
         chomp($line);
         $limits .= $line;
      }
	close LIMITS;
	
	if ($limits eq ""){$limits = "{}";}
	
	return $limits;
}

print << "HTML";
<html>
<head>
<title>Live Data</title>

<style type="text/css">
   .greenLim{
      background-color:#33FF33;
   }
   .yellowLim{
      background-color:#FFFF00;
   }
   .redLim{
      background-color:#FF0000;
   }
</style>

<script language="JavaScript" type="text/javascript" src="/getFile.js" >
</script>
<script language="JavaScript" type="text/javascript" src="/js/solarnoon.js" >
</script>
</head>

<body bgcolor=#9FA29F >
FC: 
   <input class="dataField" type="text" size="6" id="frameNumber" />
Payload:
   <input class="dataField" type="text" size="5" id="payload" value="$payload" />
Version:
   <input class="dataField" type="text" size="6" id="version" />
Last File Processed:
   <input class="dataField" type="text" id="fileName" size="25" /> 
Delay:
   <select id=delay>
	   <option value="0.1">100ms</option>
	   <option value="0.25">250ms</option>
	   <option value="0.5">500ms</option>
	   <option value="1">1s</option>
	   <option value="4" selected="yes">4s</option>
	   <option value="16">16s</option>
	   <option value="32">32s</option>
	   <option value="60">1m</option>
	   <option value="180">3m</option>
	   <option value="300">5m</option>
	</select>
<img id="statusIcon" src="/images/icons/ok.png" title="Page Loaded" />

<br />
<font size="1">* Indicates a value found in a previous frame</font>

<br />
<table>
	<tr valign="top">
		<!-- GPS table -->
		<td>
         <table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan="2">
				      <center><b>Payload Status</center></b>
				   </td>
				</tr>
            <tr>
               <td colspan="2">
                  GPS Time 
                  <input class="dataField" type="text" size="8" id="Time" />
               </td>
            </tr>
            <tr>
               <td colspan="2">
                  GPS Lat (&deg;)
                  <input class="dataField" type="text" size="5" id="GPS_Lat" />
               </td>
            </tr>
            <tr>
               <td colspan="2">
                  GPS Lon (&deg;)
                  <input class="dataField" type="text" size="5" id="GPS_Lon" />
               </td>
            </tr>
            <tr>
               <td colspan="2">
                  GPS Alt (km)
                  <input class="dataField" type="text" size="5" id="GPS_Alt" />
               </td>
            </tr>
            <tr>
               <td colspan="2">
                  Ascent Rate (m/s)
                  <input class="dataField" type="text" size="5" id="GPS_Ascent_Rate" />
               </td>
            </tr>
            <tr>
               <td>
                  Sats:
                  <input class="dataField" type="text" size="2" id="numOfSats" />
               </td>
               <td>
                  UTC_Offset:
                  <input class="dataField" type="text" size="4" id="timeOffset" />
               </td>
            </tr>
            <tr>
               <td colspan=2>
                  GPS Weeks:
                  <input class="dataField" type="text" size="5" id="weeks" />
               </td>
            </tr>
         </table>

        <br />

        <!-- Solar Noon Table -->
         <table bgcolor=#7A8B94 border>
            <tr>
               <td colspan="2">
                  <center><b>Solar Noon/Midnight (UTC)<b></center>
               </td>
            </tr>
            <tr>
               <td>
                  Noon 
                  <input class="dataField" type="text" size="8" id="SolNoon" />
               </td>
               <td>
                  Midnight	
                  <input class="dataField" type="text" size="8" id="SolMid" />
               </td>
            </tr>
         </table>
      </td>

		<!--Instrument tables -->
		<td>
			<table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan="4">
				      <center><b>X-Ray Data (cnts/sec)</b></center>
               </td>
				<tr>
				   <td colspan="2">
				      Rate Counters
               </td>
               <td colspan=2>
                  Fast Spectra
               </td>
            </tr>
				<tr>
				   <td>
				      Low Level
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="LowLevel" />
               </td>
               <td>
                  LC1
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="LC1" />
               </td>
            </tr>
				<tr>
				   <td>
				      High Level
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="HighLevel" />
				   </td>
				   <td>
				      LC2
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="LC2" />
				   </td>
            </tr>
				<tr>
				   <td>
				      Peak Detect
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="PeakDet" />
				   </td>
				   <td>
				      LC3
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="LC3" />
				   </td>
            </tr>
				<tr>
				   <td>
				      Interrupt
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="Interrupt" />
				   </td>
				   <td>
				      LC4
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="LC4" />
				   </td>
            </tr>
			</table>
			<br />
         <table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan=4>
				      <center><b>Mag Data</b></center>
				   </td>
            </tr>
				<tr>
				   <td>
				      Bx
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="MAG_X" />
				   </td>
				   <td>
				      Temp
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="ADC_Temp" />
				   </td>
            </tr>
				<tr>
				   <td>
				      By
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="MAG_Y" />
				   </td>
				   <td>
				      Offset
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="ADC_Offset" />
				   </td>
            </tr>
				<tr>
				   <td>
   				   Bz
				   </td>
				   <td>
	   			   <input class="dataField" type="text" size="5" id="MAG_Z" />
				   </td>
				   </td>
            </tr>
				<tr>
				   <td>
   				   |B|
				   </td>
				   <td>
	   			   <input class="dataField" type="text" size="5" id="magOfB" />
				   </td>
            </tr>
			</table>
      </td>
			
		<!--Temp Table -->
		<td>
			<table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan=2>
				      <center><b>Temp Data (&deg;C)</b></center>
				   </td>
				</tr>
				<tr>
				   <td>
				      T0_Scint
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T00_Scint">
				      </input>
				   </td>
				</tr>
				<tr>
				   <td>
				      T1_Mag
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T01_Mag" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T2_ChargeCont
				   </td>
			      <td>
			         <input class="dataField" type="text" size="5" id="T02_ChargeCont" />
			      </td>
				</tr>
				<tr>
				   <td>
				      T3_Battery
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T03_Battery" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T4_PowerConv
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T04_PowerConv" />
				   </td>
				</tr>	
				<tr>
				   <td>
				      T5_DPU
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T05_DPU" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T6_Modem
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T06_Modem" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T7_Structure
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T07_Structure" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T8_Solar1
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T08_Solar1" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T9_Solar2
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T09_Solar2" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T10_Solar3
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T10_Solar3" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T11_Solar4
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T11_Solar4" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T12_TermTemp
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T12_TermTemp" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T13_TermBatt
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T13_TermBatt" />
				   </td>
				</tr>
				<tr>
				   <td>   
				      T14_TermCap
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T14_TermCap" />
				   </td>
				</tr>
				<tr>
				   <td>
				      T15_CCStat
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="T15_CCStat" />
				   </td>
				</tr>
			</table>
		</td>
		
		<!--Volt Table -->
		<td>
			<table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan=2>
				      <center><b>Voltage Data (V)</b></center>
				   </td>
				</tr>
				<tr>
				   <td>
				      V0_VoltAtLoad
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V00_VoltAtLoad" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V1_Battery
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V01_Battery" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V2_Solar1
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V02_Solar1" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V3_+DPU
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V03_+DPU" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V4_+XRayDet
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V04_+XRayDet" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V5_Modem
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V05_Modem" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V6_-XRayDet
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V06_-XRayDet" />
				   </td>
				</tr>
				<tr>
				   <td>
				      V7_-DPU
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V07_-DPU" />
               </td>
            </tr>
				<tr>
				   <td>
				      V8_Mag
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="V08_Mag" />
               </td>
            </tr>
				<tr>
				   <td>
				      V9_Solar2
               </td>
                  <td>
                     <input class="dataField" type="text" size="5" id="V09_Solar2" />
                  </td>
               </tr>
				<tr>
				   <td>
				      V10_Solar3
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="V10_Solar3" />
               </td>
            </tr>
				<tr>
				   <td>
				      V11_Solar4
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="V11_Solar4" />
               </td>
            </tr>
			</table>
		</td>
			
		<!-- Current Table -->
		<td>
			<table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan=2>
				      <center><b>Current Data (mA)</b></center>
				   </td>
				</tr>			
				<tr>
				   <td>
				      I0_TotalLoad
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="I00_TotalLoad" />
               </td>
				</tr>
				<tr>
				   <td>
				      I1_TotalSolar
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="I01_TotalSolar" />
               </td>
            </tr>
				<tr>
				   <td>
				      I2_Solar1
				   </td>
				   <td>
				      <input class="dataField" type="text" size="5" id="I02_Solar1" />
               </td>
            </tr>
				<tr>
				   <td>
				      I3_+DPU
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="I03_+DPU" />
               </td>
            </tr>
				<tr>
				   <td>
				      I4_+XRayDet
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="I04_+XRayDet" />
               </td>
            </tr>
				<tr>
				   <td>
				      I5_Modem
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="I05_Modem" />
               </td>
            </tr>
				<tr>
				   <td>
				      I6_-XRayDet
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="I06_-XRayDet" />
               </td>
            </tr>
				<tr>
				   <td>
				      I7_-DPU
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="I07_-DPU" />
               </td>
            </tr>	
			</table>
			<br />
			
		<!-- Command Counter Table -->
			<table bgcolor=#7A8B94 border>
				<tr>
				   <td colspan=4>
				      <center><b>Command Counters</b></center>
               </td>
            </tr>
				<tr>
				   <td>
				      Command Ctr
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="cmdCounter" />
               </td>
            </tr>
				<tr>
				   <td>
				      DCD Reset Ctr
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="dcdCounter" />
               </td>
            </tr>
				<tr>
				   <td>
				      Modem Reset Ctr
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="modemCounter" />
               </td>
            </tr>
				<tr>
				   <td>
				      Terminate Status
               </td>
               <td>
                  <input class="dataField" type="text" size="5" id="termStatus" />
               </td>
            </tr>
			</table>
		</td>
	</tr>
</table>

<br />
<table border=0>
	<tr>
	   <td>
	      Hex Data:
      </td>
   </tr>
	<tr>
	   <td>
	      <textarea class="dataField" id="hex" rows="10" cols="40"> 
	      </textarea>
	   </td>
</table>

<script language='javascript'>
   
   // create an object that periodically polls .newdata, 
   // tests against limits, and updates the screen 
	var fieldUpdater = function(){
	   //get all of the fields that need filling
		var fields = new Array();
		fields = document.getElementsByClassName("dataField");
		
		//create a page request object
		var dataReq = new getFile();
		dataReq.seturl("/soc-nas/payload$payload/.newdata?+&rand="+Math.random());
		dataReq.processPage = function(){ 
		   var statusIconElement = document.getElementById("statusIcon");
         
         //set status image
         statusIconElement.src="/images/icons/ok.png";
         statusIconElement.title="Loaded.";
         
         //store the JSON data 
         if(dataReq.response == ""){
			 return;
		   }
         var parsedData = eval('(' + dataReq.response + ')');
         
         //make the time a bit more pretty 
         if(parsedData.Time){
            var min = "";
            var hr = "";
            var minZero = "";
            var secZero = "";

            //convert from ms 
            parsedData.Time = parseInt(parseFloat(parsedData.Time) / 1000); 
            parsedData.Time = parsedData.Time % 86400; 
            hr = parseInt(parsedData.Time / 3600);
            parsedData.Time = parsedData.Time % 3600; 
            min = parseInt(parsedData.Time / 60);
            sec = parseInt(parsedData.Time % 60);
            
            //add leading zeros if needed
            if (min<10) {minZero="0";} 
            if (sec < 10) {secZero="0";}
            parsedData.Time = hr + ":" + minZero + min + ":" + secZero + sec;
         }
         
         var limits = function (){
            //create an object literal for each group
            var tempLimits = {
               "gps" : $lims{'gps'},
               "rc" : $lims{'rc'},
               "mag" : $lims{'mag'},
               "lc" : $lims{'lc'},
               "hk" : $lims{'hk'}
               };
            
            //merge all the limits for the set payload together in one object
            var limits = new Object();
            for( var group_i in tempLimits){
               for(var var_i  in tempLimits[group_i]["$payload"]){
                  limits[var_i] = tempLimits[group_i]["$payload"][var_i];
               }
            }
            
            return limits; 
         }();
         
         //Fill fields with new values
			for(var field_i in fields){
				if(parsedData[fields[field_i].id]){ 
				   //If we have good data, write it to the correct field
					var el = document.getElementById(fields[field_i].id);
					el.value = parsedData[fields[field_i].id];
					
					//get the min and max limits for this field and ensure it is a number
					var min = limits[fields[field_i].id + "_Min"];
					var max = limits[fields[field_i].id + "_Max"];
					
					//create tool tip
               toolTip = "Min: " + min + " " + "Max: " + max;
               el.title = toolTip;
               
               //convert min/max to numbers
               min = parseFloat(min);
               max = parseFloat(max);
               
					//alter background color if value is outside limits
					if(!min.isNaN && parseFloat(el.value) < min){
					   if(el.id == "GPS_Alt"){ //check to see if this is a special case for red alert
                     el.className = "dataField redLim";
                  }else{
                     el.className = "dataField yellowLim";
                  }
					}else if(!max.isNaN && parseFloat(el.value) > max){
                  if(el.id == "GPS_Alt"){ //check to see if this is a special case for red alert
                     el.className = "dataField redLim";
                  }else{
                     el.className = "dataField yellowLim";
                  }
               }else{
                  el.className = "dataField greenLim";
               }
            }
			}
         
         //figure out magOfB
         fields.magOfB.value = Math.sqrt(
            Math.pow(parsedData.MAG_X, 2) + 
            Math.pow(parsedData.MAG_Y, 2) + 
            Math.pow(parsedData.MAG_Z, 2)
         );

         //figure out which T9 and T11 to display
         if(parsedData.version > 3){
            fields.ADC_Temp.value = parsedData.T09;
            fields.ADC_Offset.value = parsedData.T11;
         }else{
            fields.T09_Solar2.value = parsedData.T09;
            fields.T11_Solar4.value = parsedData.T11;
         }

         //calculate the solar noon and midight for this location
         solarnoon.calc();
		}
		
      return {
         //members
         running: true, //turn updating on/off
         delay: document.getElementById("delay"),
         
         //methods
         loadData: function(){
            dataReq.sendReq();
            if( fieldUpdater.running ){
				   setTimeout( 
				      function(){fieldUpdater.loadData();},
				      (fieldUpdater.delay.value * 1000) 
				   );
				}
         },
         toggleUpdates: function(){
			   if( fieldUpdater.running ){fieldUpdater.running = false;}
			   else{fieldUpdater.running = true;}
			}
      }
	}();
	
	//start getting data
	fieldUpdater.loadData();
</script>	

</body>
</html>
HTML

