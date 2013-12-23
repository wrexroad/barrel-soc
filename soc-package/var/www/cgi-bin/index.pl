#!/usr/bin/perl

print "Content-Type: text/html \n\n";

use SOC_config qw(%configVals %payloadLabels @sciVars @tempVars @voltVars @currentVars);
use SOC_funcs qw(getEnabledPayloads);

#start the html page
print "<html><head>\n<title>SOC</title>\n";

JAVASCRIPT:{
print "	<script language='javascript'>\n";

@allPayloads=sort(keys(%payloadLabels));
print "var payloads = new Array(";
foreach(@allPayloads){print "\'$_\',";}
print "\'\');\n";
print "payloads.pop();";


print << "INITVARS";
var newDataAuto='On';
var frameControlCode='';
INITVARS

print << "SWAPFRAME";
	function swapFrame(source,frameContents){   
        graphFrameElement=document.getElementById('graphsFrame');
        switchFrameElement=document.getElementById('switchFrame');
        
        if(frameContents=="graphs"){
			whichFrameElement='graphFrameElement';
				
			switchFrameElement.style.display="none";
			graphFrameElement.style.display="block";
		}
        else{
			whichFrameElement='switchFrameElement';
			
			graphFrameElement.style.display="none";
			switchFrameElement.style.display="block";

			switchFrameElement.src=source;
		}
	
		genFrameControls(frameContents,whichFrameElement);
	}
SWAPFRAME

print << "GENFRAMECONTROLS";
	function genFrameControls(frameContents,whichFrameElement){
		frameControlCode='';
		if(whichFrameElement=='graphFrameElement'){
				frameControlCode="";
		}
		else if (frameContents=='newData'){
				frameControlCode=frameControlCode+"<center>"
				+"<img id='popoutButton' title='Popout Frame' onclick=window.open(" + whichFrameElement + ".src); src='/images/icons/popout.jpg' /> ";
		}
		else{
				frameControlCode=frameControlCode+"<center>"
				+"<img id='popoutButton' title='Popout Frame' onclick=window.open(" + whichFrameElement + ".src); src='/images/icons/popout.jpg' /> "
				+"<img id='reloadButton' title='Reload Frame' onclick=" + whichFrameElement + ".src=" + whichFrameElement + ".src; src='/images/icons/reload.jpg' />  ";	
		}
		if (frameContents=='newData'){			
			frameControlCode=frameControlCode+"<img id='autoUpdates' title='Start Incoming Data' onClick='startData(newDataPayload);' src='/images/icons/play.JPG' /> "
				+" Payload: ";
			for (var i in payloads)
			{
				frameControlCode=frameControlCode+payloads[i]+"<input type=radio ";
				frameControlCode=frameControlCode+" name=payloadSelect value='" + payloads[i] + "' onClick=newDataPayload='" + payloads[i] + "';switchFrameElement.src='/cgi-bin/newData.pl?payload=" + payloads[i] + "' /> ";
			}
			frameControlCode=frameControlCode+"</center><hr />";
			document.getElementById('frameControlsDiv').innerHTML=frameControlCode;
			
			if (newDataAuto=='Off'){document.getElementById('autoUpdates').src='/images/icons/play.JPG';}
			else{document.getElementById('autoUpdates').src='/images/icons/pause.JPG';}
		}
		else if (frameContents=="config"){
			frameControlCode=frameControlCode+"<input type=button onClick=switchFrameElement.src='/cgi-bin/genconfig.pl'; value=General />"
				+"<input type=button onClick=switchFrameElement.src='/cgi-bin/voltconfig.pl'; value=Voltages />"
				+"<input type=button onClick=switchFrameElement.src='/cgi-bin/ampconfig.pl'; value=Currents />"
				+"<input type=button onClick=switchFrameElement.src='/cgi-bin/tempconfig.pl'; value=Tempratures />";
			frameControlCode=frameControlCode+"</center><hr />";
			document.getElementById('frameControlsDiv').innerHTML=frameControlCode;
		}
      else{document.getElementById('frameControlsDiv').innerHTML=frameControlCode;}
	}
GENFRAMECONTROLS

print << "GENPLOTS";
	function genPlots(){
		<!-- Build a new set of frame controls -->
		genFrameControls("graphs","graphFrameElement");
		
		<!-- show graph output frame -->
		document.getElementById("switchFrame").style.display="none";
		document.getElementById("graphsFrame").style.display="block";
	}
GENPLOTS

print << "STARTDATA";
	function startData(newDataPayload){

		autoImage=document.getElementById('autoUpdates');
		
		if(newDataAuto=='Off'){
			newDataAuto='On';
			autoImage.src='/images/icons/pause.JPG';
			autoImage.title='Stop Incoming Data';
			parent.switchFrame.updates=1;
			parent.switchFrame.getData();
		}
		else if(newDataAuto=='On'){
			newDataAuto='Off';
			autoImage.src='/images/icons/play.JPG';
			autoImage.title='Start Incoming Data';
			parent.switchFrame.updates=0;
		}
	}
STARTDATA

print "</script>\n";
};
	
print << "CSSSTYLES";
	<style type="text/css">		
		div#statsBanDiv{
			border-style:inset; margin:0; padding:0; position:absolute; top:2px; left:2px; right:2px; height:115px
			}
		
		div#buttonsDiv{
			position:absolute; top:125px; left:2px; right:2px
			}

		div#switchDiv{
			border-style:inset; position:absolute; padding-bottom:10px; top:155px; left:2px; right:2px; bottom:2px; overflow:hidden
			}
	</style>
CSSSTYLES
	
print "</head>\n";

print "<body onLoad=\"swapFrame('/cgi-bin/newData.pl','newData');\">\n";

print << "STATSBANDIV";
	<div id="statsBanDiv">
		<iframe id="statsBanFrame" name ="statsBan" width="100%" height="100%" frameborder=0 scrolling=hidden src="/cgi-bin/statsBan.pl" ></iframe>
	</div>
STATSBANDIV

print << "BUTTONSDIV";
	<div id="buttonsDiv">
	
		<center>
		<input type="button" value="Live Data" onclick="newDataPayload=payloads[0];swapFrame('/cgi-bin/newData.pl','newData');" />	
		<!-- <input type="button" value="Spectra Viewer" onclick="swapFrame('/spectra.html','newData');" />	-->
		<input type="button" value="Maps" onclick="swapFrame('/cgi-bin/maps.pl','maps');" />
		<input type="button" value="Data Browser*" onclick="window.open('/archiveViewer.html');" />
		<input type="button" value="Quicklook Spectra*" onclick="window.open('/quickSpectra.html');" />
		<input type="button" value="Admin Panel*" onclick="window.open('/cgi-bin/adminPanel.pl');" />
		<input type="button" value="Wiki*" onclick="window.open('https://barrel.pbworks.com/session/login?return_to_page=Barrel+Mission+Monitor+Wiki');" />
     <input type="button" value="Download Data*" onclick="window.open('http://barreldata.ucsc.edu/data_products/');" />
		<font size=1>*Opens in a new window.</font>
		</center>
	</div>
BUTTONSDIV

print << "SWITCHDIV";
	<div id="switchDiv">
		<div id="frameControlsDiv"></div>
		<iframe id="graphsFrame" name="graphsFrame" width="100%" height="95%" frameborder=0 scrolling=auto src="/cgi-bin/quicklook.pl"></iframe>
		<iframe id="switchFrame" name="switchFrame" width="100%" height="95%" frameborder=0 scrolling=auto src=""></iframe>
	</div>
SWITCHDIV

print "</body></html>";
