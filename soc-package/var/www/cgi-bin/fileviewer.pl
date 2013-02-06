#!/usr/bin/perl

print "Content-Type: text/html \n\n";

our @fileErrors = ();
our %input=();

#check for input 
my $input = $ENV{'QUERY_STRING'};
if ($input) {
	my ($key,$val)="";
	@input = split '&',$input;
	foreach (@input){
		($key,$val) = split '=';
		$input{$key}=$val;
	}
}

print << "HTML";
<html>
<head>
<title>File Viewer</title>

<script language="JavaScript" src="/getFile.js" ></script>
<script language="JavaScript" src="/grapher.js" ></script>

<script language='javascript'>
	var lines = new Array();
	var dataArray = new Array();
	var plotVarList = new Array();
	
	//create Ajax request
	var reqObj = new getFile();
	
	
	function genControls() {
		var data,varDropdownCode,timeDropdownCode,labelsString = "";
		var i,j = 0;
		var labels = new Array();
		var filename = "/soc-nas/payload"+document.getElementById("payload").value+"/.data"+document.getElementById("file").value+document.getElementById("year").value+document.getElementById("month").value+document.getElementById("day").value;
		
		reqObj.seturl(filename);
		
		document.getElementById('fileStatus').innerHTML = 'Loading "'+filename+'"...';
		
		//decide what to do with the returned data
		reqObj.processPage = function(){
         data = xmlhttp.responseText;
         lines = data.split('\\n');
         
         //the first line is for titles
         labelsString = lines.shift();
         labels = labelsString.split(",");
         
         i = 0;
         for (i in labels){
            dataArray[labels[i]] = new Array(); //build a 2d array based on the incomming variable names
            
            varDropdownCode=varDropdownCode+"<option value='"+labels[i]+"'>"+labels[i]+"</options>";
         }
         
         i = 0;
         for (i in lines){
            var tempData = new Array();
            tempData = lines[i].split(",");
            
            j = 0;
            for (j in labels){
               dataArray[labels[j]].push(tempData[j]);
            }
         }

         //change the dropdown variable lists
         document.getElementById('varSelect1').innerHTML= "<option value=''>Plot Variable</option>"+varDropdownCode;
         document.getElementById('varSelect2').innerHTML= "<option value=''>Plot Variable</option>"+varDropdownCode;
         document.getElementById('varSelect3').innerHTML= "<option value=''>Plot Variable</option>"+varDropdownCode;
         document.getElementById('varSelect4').innerHTML= "<option value=''>Plot Variable</option>"+varDropdownCode;
         document.getElementById('track1Select').innerHTML= "<option value=''>Variable Tracker 1</option>"+varDropdownCode;
         document.getElementById('track2Select').innerHTML= "<option value=''>Variable Tracker 2</option>"+varDropdownCode;
         
         //change file status display
         if(xmlhttp.status  == 200){
            document.getElementById('fileStatus').innerHTML = 
               '"' + filename + '" loaded.';
         }
         else{
            document.getElementById('fileStatus').innerHTML = 
               'Error loading '+filename;
         } 
      }
      
      //Send the request
      dataReq.sendReq();
   }
	
	function callPlotBuilder(){	
		
		//build an array containing the new plot variables
		var plotVarList=new Array();
		if(document.getElementById('varSelect1').value!=''){plotVarList.push(document.getElementById('varSelect1').value);}
		if(document.getElementById('varSelect2').value!=''){plotVarList.push(document.getElementById('varSelect2').value);}
		if(document.getElementById('varSelect3').value!=''){plotVarList.push(document.getElementById('varSelect3').value);}
		if(document.getElementById('varSelect4').value!=''){plotVarList.push(document.getElementById('varSelect4').value);}
		
		//clear the plot box
		document.getElementById('plotBox').innerHTML='';
		
		//add the canvas element
		document.getElementById('plotBox').innerHTML=
			'<br /><canvas id="canvas" width="'+eval(window.innerWidth-30)+'" height="'+eval(window.innerHeight*(3/5))+'"></canvas>';

		//draw on the canvas elements
		plotBuilder(plotVarList);		
	}
	
	function plotBuilder(plotVars){
		var plot = new Object();
		
		plot.type="points";
		
		plot.xVals = new Array();
		plot.xVals = dataArray['Time'];
		
		plot.yVars = new Array();
		plot.yVars = plotVars;
		
		plot.trackVars = new Array();
		plot.trackVars = [document.getElementById('track1Select').value,document.getElementById('track2Select').value];
				
		plot.yVals = new Array();
		for(var i=0; i<plotVars.length; i++){
			plot.yVals.push(dataArray[plotVars[i]].slice(0));
		}
				
		plot.track1 = new Array();
		plot.track1 = dataArray[document.getElementById('track1Select').value];
		
		plot.track2 = new Array();
		plot.track2 = dataArray[document.getElementById('track2Select').value];
		
		plot.canvasName="canvas";
		plot.errorBoxName="errorBox";
		plot.xCoordBoxName="xCoordBox";
		plot.yCoordBoxName="yCoordBox";
		plot.plotBoxName="plotBox";
		
		plot.origX=60;
		plot.origY=20;
		plot.canvasHeight=window.innerHeight*(3/5);
		plot.canvasWidth=window.innerWidth-30;
		
		//plot.chartHeight=window.innerHeight*(3/5)-100;
		//plot.chartWidth=window.innerWidth-130;
		plot.chartMargin=130;
		
		plot.legend='yes';		

		plot.yMin=document.getElementById('ymin').value;
		plot.yMax=document.getElementById('ymax').value;

		plot.ticLength=5;
		plot.borderColor="Black";
		
		plot.backgroundColor="White";
		
		plot.pointColor= new Array("Blue","Red","Black","Green");
		plot.pointSize=3;
		plot.activePointColor="#66FF00";
		
		plot.lineColor= new Array("Blue","Red","Black","Green");
		plot.lineWidth=1;
		
		plot.textColor="Black";
		plot.cssFont="14px sans-serif";
		plot.title=plotVars+" on "+document.getElementById("month").value+"/"+document.getElementById("day").value+"/"+document.getElementById("year").value;
		
		plot.xAxisLabel="Time";
		plot.xSkippedTics=parseInt(20*plot.xVals.length/(plot.canvasWidth-plot.chartMargin));
		if(plot.xSkippedTics<1){plot.xSkippedTics=1;}

		drawPlot(plot);
	}
	
	function setDivSize(){
		document.getElementById('plotDiv').style.right=0+"px";
		document.getElementById('plotDiv').style.height=window.innerHeight*(2/3)+"px";
		
		document.getElementById('controlHolder').style.height=(window.innerHeight*(1/3)-25)+"px";
		
		document.getElementById('fileDiv').style.width=(window.innerWidth-10)*2/5+"px";
				
		document.getElementById('optionsDiv').style.left=(window.innerWidth-10)*2/5+"px";
		document.getElementById('optionsDiv').style.width=(window.innerWidth-10)*2/5+"px";
		
		document.getElementById('pointDetailDiv').style.left=((window.innerWidth-10)*2/5)*2+"px";
	}
	
	function moveControls(){
		var stepSize=5;
				
		var plotDivObject=document.getElementById('plotDiv');
		var controlHolerObject=document.getElementById('controlHolder');
		var currentHeight=parseInt(controlHolerObject.style.height);
		
		if (currentHeight<(window.innerHeight*(1/3)-25)){
			var multiplier=1;
			var endHeight=(window.innerHeight*(1/3)-25);
			document.getElementById('moveControlButton').value="Hide";
			move();
		}
		
		else if (currentHeight>=(window.innerHeight*(1/3)-25)){
			var multiplier=-1;
			var endHeight=30;
			document.getElementById('moveControlButton').value="Show";
			move();
		}
		
		function move(){
			currentHeight=(currentHeight+(multiplier*stepSize));
			controlHolerObject.style.height=currentHeight+"px";
			plotDivObject.style.height=(window.innerHeight-currentHeight-25)+"px";
			var diff=Math.abs(currentHeight-endHeight);
			if (diff>=stepSize){setTimeout(move,30);}
		}
	}
</script>
</head>

<body onload=createReqObj();setDivSize();>

<div id="plotDiv" style="border-style:inset; padding:0; margin:0; position:relative; left:0px; overflow:auto">
	<div id="errorBox">@fileErrors</div>
	
	<div id="plotBox">
		Select or upload a file below, click load, select plotting variables and away you go!
	</div>
</div>

<div id="controlHolder" style="border-style:none; padding:0; margin:0; position:relative; left:0px; right:0px; overflow:hidden">
	<div id=fileDiv style="border-style:inset; padding:0; margin:0; position:absolute; left:0px; top:0px; bottom:0px; overflow:auto">
		<table border=1>
			<tr>
				<td>
					<table><tr>
						<td>Date:</td>
						<td>
							<select id=month>
								<option>Month</option><option>01</option><option>02</option><option>03</option><option>04</option><option>05</option><option>06</option><option>07</option><option>08</option><option>09</option><option>10</option><option>11</option><option>12</option>
							</select>
						</td>
						<td>
							<select id=day>
								<option>Day</option><option>01</option><option>02</option><option>03</option><option>04</option><option>05</option><option>06</option><option>07</option><option>08</option><option>09</option><option>10</option><option>11</option><option>12</option><option>13</option><option>14</option><option>15</option><option>16</option><option>17</option><option>18</option><option>19</option><option>20</option><option>21</option><option>22</option><option>23</option><option>24</option><option>25</option><option>26</option><option>27</option><option>28</option><option>29</option><option>30</option><option>31</option>
							</select>
						</td>
						<td>
							<select id=year>
								<option>Year</option><option>10</option><option>11</option><option>12</option><option>13</option><option>14</option>
							</select>
						</td>
					</tr></table>
				</td>		
				<td>
					<table><tr>
						<td>Data File:</td>
						<td>
							<select id=file>
								<option>house</option>
								<option>sci</option>
							</select>
						</td>
					</tr></table>
				</td>			
			</tr>
			<tr>
				<td >
					<table><tr>
						<td>Payload:</td>
						<td>
							<select id=payload>
								<option>A</option><option>B</option><option>C</option><option>D</option><option>E</option><option>F</option><option>G</option><option>H</option><option>I</option><option>J</option><option>K</option><option>L</option><option>M</option><option>N</option><option>O</option><option>P</option><option>Q</option><option>R</option><option>S</option><option>T</option>
							</select>
						</td>
					</tr></table>
				</td>
				<td><input type=button value=Load  onClick="genControls()" /></td>
			</tr>
			<tr>
				<td colspan=2 id=fileStatus>No File Loaded</td>
			</tr>
		</table>
		
	</div>

	<div id=optionsDiv style="border-style:inset; padding:0; margin:0; position:absolute; top:0px; bottom:0px; overflow:auto">
		<div id=track1SelectDiv>
			Variable Tracker 1:
			<select id=track1Select>
			</select>
		</div>
		
		<div id=track2SelectDiv>
			Variable Tracker 2:
			<select id=track2Select>
			</select>
		</div>
		
		<hr />
		
		<div id=varSelectDiv>
			Plot Variable:
			<select id=varSelect1></select>
			<br />
		
			Plot Variable:
			<select id=varSelect2></select>
			<br />
			
			Plot Variable:
			<select id=varSelect3></select>
			<br />
			
			Plot Variable:
			<select id=varSelect4></select>
			<br />
		</div>
		
		<div>
			Plot Maximum:<input type=text id=ymax size=5 />
			<br />
			Plot Minimum: <input type=text id=ymin size=5 />
		</div>
		
		<input type=button value=Plot onclick="callPlotBuilder();" />
		<br />
	</div>

	<div id="pointDetailDiv" style="border-style:inset; padding:0; margin:0; position:absolute; top:0px; bottom:0px; right:0px; overflow:auto">
		<div id="track1Box">Variable 1:</div>
		<div id="track2Box">Variable 2:</div>
		<hr />
		<div id="xCoordBox">Time:</div>
		<div id="yCoordBox">Variable:</div>
	</div>
	<input id="moveControlButton" type="button" value="Hide" onclick="moveControls();" style="position:absolute; right:0px" />
</div>
</body>
HTML
