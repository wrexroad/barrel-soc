#!/usr/bin/perl

main:{
   use strict;
   use SOC_config qw(%configVals %payloadLabels);
   use SOC_funcs qw(getCgiInput getDirListing);
   
   print "Content-Type: text/html \n\n";
   printPage(getCoords());
}

sub getCoords{
   #check for input
   my $arrayCode="";
   my @coordData=();
   my @elements=();
      
   my $inputRef=getCgiInput();
   
   if($inputRef){
      #convert each string referenced in the input into a list
      if($$inputRef{inputPayloads} =~ m/All/){
		  $$inputRef{inputPayloads}="All";
         @{$inputRef{payloads}}=();
			foreach(sort(keys(%payloadLabels))){
            push @{$inputRef{payloads}},$_;
         }
      }
		else{
		  @{$inputRef{payloads}}=sort(split /,/,$$inputRef{inputPayloads});
		  
      }
   }else{return;}
	
	
	#make sure we have good start and end dates and times
	if($$inputRef{inputStartDate}=="YYMMDD"){
      $$inputRef{inputStartDate}=999999;
		$$inputRef{inputEndDate}=000000;
		foreach(@{$inputRef{payloads}}){
         @listing=getDirListing($configVals{mocNas}."/payload".$_."/","dir");
			
			#make sure the dates exist
			if($listing[0]<$$inputRef{inputStartDate}){$$inputRef{inputStartDate}=$listing[0];}
			if($listing[-1]>$$inputRef{inputEndDate}){$$inputRef{inputEndDate}=$listing[-1];}
		}
	}
   
	#make sure the end date is after the start date
   if($$inputRef{inputStartDate}>$$inputRef{inputEndDate}){$$inputRef{inputStartDate}=$$inputRef{inputEndDate}};
	
	#make sure end time is after start time if they are on the same day
	if($$inputRef{inputStartDate}==$$inputRef{inputEndDate} and $$inputRef{inputStartHour}>$$inputRef{inputEndHour}){
		  $$inputRef{inputStartHour}=$$inputRef{inputEndHour};
	}
	
	if($$inputRef{inputStartHour}=="HH"){$$inputRef{inputStartHour}=00;}
	if($$inputRef{inputEndHour}=="HH"){$$inputRef{inputEndHour}=24;}
     
   #cycle through each payload send in the input
   for(my $payload_i=0;$payload_i<@{$inputRef{payloads}};$payload_i++){
      my $filename=$configVals{socNas}."/payload".${$inputRef{payloads}}[$payload_i]."/.flightpath";

      if(!-e $filename){next;}
      
      open DATA, $filename or print "$!\n";
      
      #get data for each requested date
		while(my $line=<DATA>){
         @elements=split /,/,$line;
			if($elements[0]>=$$inputRef{inputStartDate} and $elements[0]<=$$inputRef{inputEndDate}){
            push @{$coordData[$payload_i]{date}},$elements[0];
			   push @{$coordData[$payload_i]{frame}},$elements[1];
            push @{$coordData[$payload_i]{time}},$elements[2];
            push @{$coordData[$payload_i]{lat}},$elements[3];
			   push @{$coordData[$payload_i]{lon}},$elements[4];
			   push @{$coordData[$payload_i]{alt}},$elements[5];
         }
		}
		close DATA;
		
		#limit by start and end times if needed
		my $data_i=(scalar(@{$coordData[$payload_i]{date}}) - 1); #find the last index of the data array
		while($data_i >= 0){
		  if(
			  ${$coordData[$payload_i]{date}}[$data_i] == $$inputRef{inputStartDate} and
			  (${$coordData[$payload_i]{time}}[$data_i] % 86400000)/3600000 <= $$inputRef{inputStartHour}
			){
					 splice @{$coordData[$payload_i]{date}},$data_i,1;
					 splice @{$coordData[$payload_i]{frame}},$data_i,1;
					 splice @{$coordData[$payload_i]{time}},$data_i,1;
					 splice @{$coordData[$payload_i]{lat}},$data_i,1;
					 splice @{$coordData[$payload_i]{lon}},$data_i,1;
					 splice @{$coordData[$payload_i]{alt}},$data_i,1;
		  }
		  elsif(
				${$coordData[$payload_i]{date}}[$data_i] == $$inputRef{inputEndDate} and
				(${$coordData[$payload_i]{time}}[$data_i] % 86400000)/3600000 >= $$inputRef{inputEndHour}
			){
					 splice @{$coordData[$payload_i]{date}},$data_i,1;
					 splice @{$coordData[$payload_i]{frame}},$data_i,1;
					 splice @{$coordData[$payload_i]{time}},$data_i,1;
					 splice @{$coordData[$payload_i]{lat}},$data_i,1;
					 splice @{$coordData[$payload_i]{lon}},$data_i,1;
					 splice @{$coordData[$payload_i]{alt}},$data_i,1;
		  }
		  $data_i--;
		}
	}
	return \@coordData,\$inputRef;	  
}

sub printPage{
   my ($coordDataRef,$inputRef)=@_;
   my $payloadList;
   
	foreach(sort(keys(%payloadLabels))){
      $payloadList=$payloadList."<option>$_</option>";
   }
   
print << "HTML";
<html>  
<head>  
   <title>Payload Mapper</title>
   <script language="JavaScript" type="text/javascript" src="/grapher.js" ></script>
   <script type="application/javascript">  
      var numOfPayloads=1;
      var input;
		
      function init(){
         cleanMap(); //add background picture 
         
         //initialize the argument arrays as globably accessable
         input=new Array();
         input.payloads=new Array();
HTML

   if ($inputRef){
      print "\n         //add previously sent input to the input array and rebuild payload controls.\n"
           .'         input.payloads=["'.join('","',@{$inputRef{payloads}}).'"];'."\n"
           .'         input.startDate="'.${$$inputRef}{inputStartDate}.'";'."\n"
           .'         input.endDate="'.${$$inputRef}{inputEndDate}.'";'."\n"
			  .'         input.startHour="'.${$$inputRef}{inputStartHour}.'";'."\n"
			  .'         input.endHour="'.${$$inputRef}{inputEndHour}.'";'."\n"
           ."         \n"
			  ."         //set date information\n"
			  .'         document.getElementById("startyear").value=input.startDate.charAt(0)+input.startDate.charAt(1);'."\n"
			  .'         document.getElementById("startmonth").value=input.startDate.charAt(2)+input.startDate.charAt(3);'."\n"
			  .'         document.getElementById("startday").value=input.startDate.charAt(4)+input.startDate.charAt(5);'."\n"
			  .'         document.getElementById("endyear").value=input.endDate.charAt(0)+input.endDate.charAt(1);'."\n"
			  .'         document.getElementById("endmonth").value=input.endDate.charAt(2)+input.endDate.charAt(3);'."\n"
			  .'         document.getElementById("endday").value=input.endDate.charAt(4)+input.endDate.charAt(5);'."\n"
			  .'         document.getElementById("starthr").value=input.startHour;'."\n"
			  .'         document.getElementById("endhr").value=input.endHour;'."\n"
			  ."         \n"
			  .'         if("'.${$$inputRef}{inputPayloads}.'"!="All"){'."\n"
           ."            for(var input_i=0; input_i<input.payloads.length; input_i++){\n"
           ."               addPayload('prev');\n"
           ."            }\n"
			  ."         }\n"
			  ."         else{\n"
			  ."               addPayload('empty');\n"
			  .'         }'."\n";
   }

print << "HTML";
         //add an empty set of controls if there was no input
         if(numOfPayloads==1){addPayload("empty");}
      }
      
      function cleanMap() {  
   
         var plot = new Object();
            plot.type="polar-map-south-points";
            plot.plotBoxName="plotBox";
            
            plot.origX=0;
            plot.origY=20;
            
            plot.startAngle=-1*Math.PI/2;
            
            plot.radiusMarks="no";
            plot.angleMarks="no";
            
            plot.radiusMax=-60;
            
				plot.canvasWidth=492;
				plot.canvasHeight=512;
				
            plot.chartHeight=492;
            plot.chartWidth=492;
            plot.ticLength=5;
            plot.borderColor='Black';
				
            plot.backgroundImageID=document.getElementById("background");
HTML
	
	#set some javaScript variables with cgi input data
	if($inputRef){
      print "            plot.pointColor=new Array();\n"
		     .'            plot.pointColor=['
		     .'                  "FF0000","333333","00FF00","CC99FF","000000","330066","330000","669933",'
		     .'                  "FF0066","0000FF","CC3300","FF6600","3300FF","99FF99","999966","999900"];'
		     ."            \n"
		     .'            plot.legend=["'.join('","',@{$inputRef{payloads}}).'"];'."\n"
		     .'            '."\n"
			  ."            \n"
           ."            plot.title=\"Paths for Payloads @{$$inputRef}{payloads} from ${$$inputRef}{inputStartDate} to ${$$inputRef}{inputEndDate}\";\n";
    }
	 
print << "HTML";
            plot.pointSize=5;
            
            plot.zeroAngle=-1*Math.PI/2;
            
            plot.textColor='Black';
            plot.cssFont='14px sans-serif';   
            plot.canvasName="canvas";
				
            plot.radiusVals=new Array();
            plot.angleVals=new Array();
            
            plot.radiusVals[0]=new Array();
            plot.angleVals[0]=new Array();
HTML

   for(my $varSet_i=0;$varSet_i<@$coordDataRef;$varSet_i++){
      print "            plot.radiusVals[$varSet_i]=new Array();\n";
      print "            plot.angleVals[$varSet_i]=new Array();\n";
      print "            plot.radiusVals[$varSet_i].push(\'".join("','",@{$$coordDataRef[$varSet_i]{lat}})."\');\n";
      print "            plot.angleVals[$varSet_i].push(\'".join("','",@{$$coordDataRef[$varSet_i]{lon}})."\');\n";
   }

print << "HTML";
         drawPlot(plot);
      }
   
   function plot(){
	   
		//reinitialize the input arrays
		input.payloads=new Array();
      input.startDate=\"\";
      input.endDate=\"\";
		
		//rebuild query info from controls section
      for(var i=1;i<numOfPayloads;i++){
		   //skip any controls that have not been set
         if(document.getElementById("payload"+i).value!="Payload"){
			   input.payloads.push(document.getElementById("payload"+i).value);
		  }
       input.startDate=document.getElementById('startyear').value+document.getElementById('startmonth').value+document.getElementById('startday').value;
       input.endDate=document.getElementById('endyear').value+document.getElementById('endmonth').value+document.getElementById('endday').value;
		 input.startHour=document.getElementById('starthr').value;
		 input.endHour=document.getElementById('endhr').value;
      }
		
		//reload page with new input data
      window.location.href =
		   "maps.pl?inputPayloads="+input.payloads.join(",")+
			"&inputStartDate="+input.startDate+
			"&inputEndDate="+input.endDate+
			"&inputStartHour="+input.startHour+
			"&inputEndHour="+input.endHour;
   }
   
   
   function addPayload(type){
      if(type=="empty"){
         input.payloads.push("Payload");
      }
		
		var payloadDropdown;
      var newControls = document.createElement("div");
		payloadDropdown = "Payload:<select id=payload"+numOfPayloads+">\\n";
		
		if("${$$inputRef}{inputPayloads}" == 'All'){
		   payloadDropdown = payloadDropdown +
			"      <option>All</option>\\n"+
			"      <option>----</option>\\n";
      }
		else if(input.payloads.length>0){
		   payloadDropdown = payloadDropdown +
			"      <option>"+input.payloads[numOfPayloads-1]+"</option>\\n"+
			"      <option>----</option>\\n";
      }
      
		payloadDropdown = payloadDropdown +
			"      <option>All</option>\\n"+
			"      $payloadList\\n"+
         "   </select>\\n"+
         "\\n";
			
      newControls.innerHTML = payloadDropdown + "   <br />\\n";
		
      document.getElementById("payloadControl").appendChild(newControls);
      newControls.id=numOfPayloads;
      numOfPayloads++;
   }
   
   function clearAll(){
      cleanMap();
		while(numOfPayloads>1){
		   numOfPayloads--;
         document.getElementById("payloadControl").removeChild(document.getElementById(numOfPayloads));
		}
      addPayload();
   }
	
	function saveImage(){
        document.getElementById("imageData").value=canvas.toDataURL();
		  document.getElementById("imageName").value="BARREL_Payload_Map-"+input.payloads.join("-")+"_"+input.startDate+"-"+input.endDate+".png";
   	  document.forms["save"].submit();
		  document.getElementById("imageData").value="";
   }
   </script>
	
</head>      
<body onload="init();">      
   <div id="plotBox" align=center style="border:inset;position:relative;top:0px;padding:1em">
      <canvas id="canvas" width="492" height="492"></canvas>  
   </div>
   <div id="payloadControl" style="border-style:inset">
      Start Time:
		  <select id="startyear">
            <option>YY</option>
            <option>10</option><option>11</option><option>12</option><option>13</option><option>14</option>
         </select>
         <select id="startmonth">
            <option>MM</option>
            <option>01</option><option>02</option><option>03</option><option>04</option><option>05</option>
            <option>06</option><option>07</option><option>08</option><option>09</option><option>10</option>
            <option>11</option><option>12</option>
         </select>
         <select id="startday">
            <option>DD</option>
            <option>01</option><option>02</option><option>03</option><option>04</option><option>05</option>
            <option>06</option><option>07</option><option>08</option><option>09</option><option>10</option>
            <option>11</option><option>12</option><option>13</option><option>14</option><option>15</option>
            <option>16</option><option>17</option><option>18</option><option>19</option><option>20</option>
            <option>21</option><option>22</option><option>23</option><option>24</option><option>25</option>
            <option>26</option><option>27</option><option>28</option><option>29</option><option>30</option>
            <option>31</option>
         </select>
         <select id="starthr">
            <option value="00">HH</option>
            <option>00</option><option>01</option><option>02</option><option>03</option><option>04</option>
            <option>05</option><option>06</option><option>07</option><option>08</option><option>09</option>
            <option>10</option><option>11</option><option>12</option><option>13</option><option>14</option>
            <option>15</option><option>16</option><option>17</option><option>18</option><option>19</option>
            <option>20</option><option>21</option><option>22</option><option>23</option><option>24</option>
         </select>

      
      End Time:
		   <select id="endyear">
            <option>YY</option>
            <option>10</option><option>11</option><option>12</option><option>13</option><option>14</option>
         </select>
         <select id="endmonth">
            <option>MM</option>
            <option>01</option><option>02</option><option>03</option><option>04</option><option>05</option>
            <option>06</option><option>07</option><option>08</option><option>09</option><option>10</option>
            <option>11</option><option>12</option>
         </select>
         <select id="endday">
            <option>DD</option>
            <option>01</option><option>02</option><option>03</option><option>04</option><option>05</option>
            <option>06</option><option>07</option><option>08</option><option>09</option><option>10</option>
            <option>11</option><option>12</option><option>13</option><option>14</option><option>15</option>
            <option>16</option><option>17</option><option>18</option><option>19</option><option>20</option>
            <option>21</option><option>22</option><option>23</option><option>24</option><option>25</option>
            <option>26</option><option>27</option><option>28</option><option>29</option><option>30</option>
            <option>31</option>
         </select>
         <select id="endhr">
            <option value="24">HH</option>
            <option>00</option><option>01</option><option>02</option><option>03</option><option>04</option>
            <option>05</option><option>06</option><option>07</option><option>08</option><option>09</option>
            <option>10</option><option>11</option><option>12</option><option>13</option><option>14</option>
            <option>15</option><option>16</option><option>17</option><option>18</option><option>19</option>
            <option>20</option><option>21</option><option>22</option><option>23</option><option>24</option>
         </select>

         <br />
   </div>
   <div id="pageControl" style="border:inset;position:relative;top:0px">
      <input type=button value="Add Payload" onClick="addPayload('empty');" />
      <input type=button value="Clear All" onClick="clearAll();" />
		<input type=button value="Draw Map" onClick="plot();" />
		<input type="button" value="Save Map" onclick="saveImage();" />
   </div>
	
	<div id="hiddenStuff" style="display:none">
      <form name="save" id="save" method=POST action=saveImage.php>
			<input type="textarea" id="imageName" name="imageName" value="" style="display:none" />
         <input type="textarea" id="imageData" name="imageData" value="" style="display:none" />
		</form>
		
      <img src="/images/gridMap.jpg" id="background" style="display:none" />
   </div>
</body>  
</html> 
HTML
}
