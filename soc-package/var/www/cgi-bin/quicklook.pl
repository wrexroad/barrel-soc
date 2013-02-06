#!/usr/bin/perl

#use strict;
use SOC_config qw(%configVals %dataTypes @payloads);
use SOC_funcs "getVarInfo";

#start HTML page
print "Content-Type: text/html \n\n";

print<<"HTML";
<html>
<head>

<!-- load graphics library -->
<script language="JavaScript" type="text/javascript" src="/grapher.js" ></script>

<script language="javascript">
//Declare some global variables
HTML

my %vars=();
getVarInfo(\%dataTypes, \%vars);

#export perl varibales to JavaScript variables
print "var varList = ''";
foreach my $var (@{$vars{'vars'}}){
   my $group = ${$vars{'groups'}}{$var};
   print " + '<option value=\"" . $group . "::" . $var . "\">$var</option>'\n";   
}

print "var payloadList = '<option>".join("</option><option>", @payloads)."</option>';\n";
print "var dataPath = '".$configVals{socNas}."';\n";

#print "var modValues = new Array();\n";
#foreach(sort keys %modValues){
#   print "  modValues[\'$_\']=\'$modValues{$_}\';\n"
#}
#print "var subcomValues = new Array();\n";
#foreach(sort keys %subcomValues){
#   print "  subcomValues[\'$_\']=\'$subcomValues{$_}\';\n"
#}
	
#generate HTML page
print<<"HTML";
var plotArray = new Array();

//define the plot object
function plotObj(){
   
   //declare members
   this.plotNumber=plotArray.length;
   this.parentElement=document.getElementById("plotsHolder");
   this.plotBox="";
   this.xCoordBox="";
   this.yCoordBox="";
   this.canvasDiv="";
   this.linebreak="";
   this.canvasElement="";
   this.controlsDiv="";
   this.payloadOptions="";
   this.varNameOptions="";
   this.fcData=new Array();
   this.timeData=new Array();
   this.varData=new Array();
   this.lines=new Array();
   this.filename="";
   this.dataType="-";
   this.reqPath="-";
   this.xmlResp="-";
   this.upperLimit="";
   this.lowerLimit="";
   this.noBG="";
   this.noAxis="";
   this.subplot="";
   this.title="";
   
   this.buildPlot=function(){
      var self=this;
      
      //create the plot area
      self.plotBox=document.createElement("div");
      self.plotBox.setAttribute("id","plot"+self.plotNumber);
      self.parentElement.appendChild(self.plotBox);
      self.plotBox.innerHTML=''+
         '  <hr />'+
         '  <div id="canvasDiv'+ self.plotNumber+'" style="border:inset;margin:0;padding:0"></div>'+ //canvas holder
         '  <div id="xCoordBox' + self.plotNumber + '" style="border:inset;width:500px;float:left">X-Axis Value</div>'+ //x coordinate holder
         '  <div id="yCoordBox' + self.plotNumber + '" style="border:inset;width:500px;float:left">Y-Axis Value</div>'+ //y coordinate holder
         '  <br />'+
         '  <div style="clear:both"></div>'+
         '  <div id="controls' + self.plotNumber + '">'+
         '     <div style="clear:both"></div>'+
         '     <div id="controls' + self.plotNumber + '">'+
         '     <form name="controls' + self.plotNumber + '">' +
         '                 Payload <select name="payload">' +payloadList+'</select> | '+
         '                 Data Type <select name="varName">'+varList+'</select> | '+
         '        Limits <select name="limits">'+
         '           <option>Off</option>'+
         '           <option>On</option>'+
         '        </select>'+
         '        | '+
         '        Scale <select name="scale">'+
         '           <option>Linear</option>'+
         '           <option>Log</option>'+
         '        </select>'+
         '        | '+
         '        X-Axis Label <select name="xaxis">'+
         '           <option>Time</option>'+
         '           <option>Frames</option>'+
         '        </select>'+
         '        | '+
         '        Plot Length (Hours) <select name="length">'+
         '           <option>1</option>'+
         '           <option>6</option>'+
         '           <option>24</option>'+
         '        </select>'+
         '        | '+
         '        <input type="button" name="Draw" value="Draw" onClick="plotArray['+self.plotNumber+'].doIt();" />'+
         '        <input type="button" name="Remove" value="Remove" onClick="document.getElementById(\\'plotsHolder\\').removeChild(document.getElementById(\\'plot'+self.plotNumber+'\\'));"/>'+
         '     </form>'+
         '   </div>';
   }
   
   this.doIt=function(){
      var self=this;
      var formName=document.forms["controls"+self.plotNumber];
      
      self.noBG=0;
      self.noAxis=0;
      self.subplot=0;
      
      if (formName.varName.value=="LC-All"){
         self.title="LC-All";
         self.varList=["LC1","LC2","LC3","LC4"];
         self.colorList=["Red","Blue","Green","Yellow"];
         self.getData();
      }
      else{
         //split up the variable type and name
         var splitVar = formName.varName.value.split("::");
         self.varList = [splitVar[1]];
         self.dataType = splitVar[0];
         
         //check if this data is from the housekeeping group
         if(self.dataType == "hk"){
            self.dataType = splitVar[1].substring(0,1);
         }
         
         self.title=formName.varName.value;
         self.colorList=["Red","Blue","Green","Yellow"];
         self.getData();
      }
   }
   
   this.getData=function(subNumber){
      var self=this;
      var formName=document.forms["controls"+self.plotNumber];
      
      //Make sure all the fields are filled out
      if (formName.payload.value=="title"){var missingVals="Payload";}
      if (formName.varName.value=="title"){missingVals=missingVals+", Data Type";}
      if (formName.limits.value=="title"){missingVals=missingVals+", Y-Axis Limits";}
      if (formName.scale.value=="title"){missingVals=missingVals+", Y-Axis Scale";}
      if (formName.xaxis.value=="title"){missingVals=missingVals+", X-Axis Label";}
      if (formName.length.value=="title"){missingVals=missingVals+", Plot Length";}
      if (missingVals){
         window.alert("All fields are required. "+missingVals+" are missing.");
         missingVals=null;
         return;
      }
      //build query
      self.reqPath="getData.php?"+
                     "payload="+formName.payload.value+
                     "&varName="+self.varList[0].replace("+", "%2B")+
                     "&xAxis="+formName.xaxis.value+
                     "&length="+formName.length.value+
                     "&dataType="+self.dataType+
                     "&limits="+formName.limits.value+
                     "&dataLoc="+dataPath+
                     "&rand="+Math.random();
       
      //send query  
      var xmlhttp=false;
      /*\@cc_on \@*/
      /*\@if (\@_jscript_version >= 5)
      // JScript gives us Conditional compilation, we can cope with old IE versions.
      // and security blocked creation of the objects.
      try {
         xmlhttp=new ActiveXObject("Msxml2.XMLHTTP");
      }catch (e) {
         try {
            xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
         } catch (E) {
            xmlhttp=false;
         }
      }
      \@end \@*/
      if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
         try {
            xmlhttp = new XMLHttpRequest();
         } catch (e) {
            xmlhttp=false;
         }
      }
      if (!xmlhttp && window.createRequest) {
         try {
            xmlhttp=window.createRequest();
         } catch (e) {
            xmlhttp=false;
         }
      }
    
      if (xmlhttp){
         xmlhttp.open("GET", self.reqPath, true);
         xmlhttp.onreadystatechange=function(){
            if(xmlhttp.readyState==4){
               self.xmlResp=xmlhttp.responseText;
               self.splitData();
            }
         }  
      }else{
         window.alert("Your browser does not support XMLHTTPREQUEST objects. Can not display plot.");
         return false;
      }
      xmlhttp.send(null);
   }
   
   this.splitData=function(){ //separate each line on the response text into three arrays: time, frame#, and data
      var self=this;
      var lines=self.xmlResp.split("\\n");
      
      //requested page ends with a new line character so the last element of the array will be empty
      lines.pop();
      
      //get plot date information
      self.currentDate=lines.shift();
		
      //initialize upper and lower limits in case the changed from the last plot
      if(self.multiplot==0){
         self.upperLimit="";
         self.lowerLimit="";   
      }
      
      //if this is a limited plot, grab limits from the xml response text
      if(document.forms["controls"+self.plotNumber].limits.value=="On"){
         self.upperLimit=lines.pop();
         self.lowerLimit=lines.pop();
      }
      
      //split up the data
      var tempArray = new Array();
      for(var line_i=0 in lines){
       tempArray=lines[line_i].split(",");
         self.varData.unshift(tempArray.pop());
         self.timeData.unshift(tempArray.pop());
         self.fcData.unshift(tempArray.pop());
      }

      //limit the plots as needed
      if (document.forms["controls"+self.plotNumber].limits.value=="On"){
         for(var var_i=0 in self.varData){
            self.varData[var_i] = Math.min(self.varData[var_i], self.upperLimit);
            self.varData[var_i] = Math.max(self.varData[var_i], self.lowerLimit);
         }
      }

      //check if we need to scale the data for a log plot
      if (document.forms["controls"+self.plotNumber].scale.value=="Log"){
         var baseten = Math.log(10);
         
         for(var var_i=0 in self.varData){
            var datapoint = parseFloat(self.varData[var_i]);
            if(datapoint > 0){
               self.varData[var_i]=
                  Math.log(datapoint)/ baseten;
            }
            else{self.varData[var_i]=0;}
         }
      }

    //uncompress gaps
    //var fc=self.fcData[0];//get first frame counter value
	var var_i=0;
	while(var_i < self.varData.length){
		//figure out the gap size
		var gap = self.fcData[(var_i+1)] - self.fcData[var_i];

		for(var gap_i=1; gap_i<gap; gap_i++){
			self.fcData.splice(var_i,0,"GAP");
			self.timeData.splice(var_i,0,"GAP");
			self.varData.splice(var_i,0,"0");
		}

		var_i += Math.max(1, gap);
	}

      //Check length of data array
      var lengthDiff=self.varData.length-document.forms['controls'+self.plotNumber].length.value*3600;
      
      //Positive difference means gap decompression gave too many points
      if(lengthDiff>0){
         self.fcData.splice(0,lengthDiff);
         self.timeData.splice(0,lengthDiff);
         self.varData.splice(0,lengthDiff);
      }
      
      //Negative diff means there was not enough data to begin with
      while(lengthDiff<0){
         self.fcData.unshift('NODATA');
         self.timeData.unshift('NODATA');
         self.varData.unshift(0);
         lengthDiff++;
      }

      self.drawPlot();
      
      //dump old data
      self.fcData=new Array();
      self.timeData=new Array();
      self.varData=new Array();
   }
   
   this.convertTime=function(){
      var self=this;
      for(var timeData_i=0 in self.timeData){
			if(!isNaN(self.timeData[timeData_i]))
			{
				//convert from miliseconds to seconds
				self.timeData[timeData_i] /= 1000;
				
				//remove any seconds beyond one day
				self.timeData[timeData_i] %= 86400;
				
				var hours=parseInt(self.timeData[timeData_i]/3600);
				var minutes=parseInt(self.timeData[timeData_i]%3600/60);
					if(minutes<10){minutes="0"+minutes;}
				var seconds=parseInt(self.timeData[timeData_i]%3600%60);
				if(seconds<10){seconds="0"+seconds;}
				self.timeData[timeData_i]=hours+":"+minutes+":"+seconds;
			}
		}
   }
   
   this.drawPlot=function(){
      var self=this;
      var plot = new Object();
         plot.subplot=self.subplot;
         plot.noAxis=self.noAxis;
         plot.noBG=self.noBG;
         plot.type="points";
         plot.xCoordBoxName="xCoordBox"+self.plotNumber;
         plot.yCoordBoxName="yCoordBox"+self.plotNumber;
         plot.plotBoxName="canvasDiv"+self.plotNumber;
         
         plot.scale=document.forms["controls"+self.plotNumber].scale.value;
         
         plot.origX=60;
         plot.origY=20;
         plot.canvasHeight=400;
         plot.canvasWidth=parseInt(window.innerWidth);
         plot.chartMargin=200;
         
         plot.ticLength=5;
         plot.borderColor='Black';
         plot.backgroundColor='#CCCCCC';
         plot.lineColor=new Array(self.colorList[0]);
         plot.lineWidth=1;
         
         plot.pointColor = new Array(self.colorList[0]);
         if(document.forms["controls" + self.plotNumber].length.value == 24){
            plot.pointSize = 1;
         }else if(document.forms["controls" + self.plotNumber].length.value == 6){
            plot.pointSize = 2;
         }else{
            plot.pointSize = 3;
         }
         
         plot.activePointColor = '#66FF00';
         
         plot.textColor = 'Black';
         plot.cssFont = '14px sans-serif';
         plot.canvasName = "canvas"+self.plotNumber;
         plot.title = "Plot of "+
                     self.title+
                     " from "+
                     self.currentDate +
                     " (" +
                     document.forms["controls"+self.plotNumber].length.value +
                     " hour(s))";
         
         plot.yVars = new Array();
         plot.yVars[0]=self.varList[0];
         plot.yVals=new Array();
         plot.yVals[0]=new Array();
         plot.yVals[0]=self.varData;
         
         plot.yAxisLabel=self.title;
         plot.yMax=self.upperLimit;
         plot.yMin=self.lowerLimit;
         plot.ySkippedTics="";
         plot.xSkippedTics=parseInt((20*plot.yVals[0].length)/(plot.canvasWidth-plot.chartMargin));
         plot.xAxisLabel=document.forms["controls"+self.plotNumber].xaxis.value;
         
         plot.xVals = new Array();
         if(document.forms["controls"+self.plotNumber].xaxis.value=="Time"){
            self.convertTime();
            plot.xVals=self.timeData;
         }
         else{plot.xVals=self.fcData;}
    
      //filterByMod($modValues{"dataObj.varName"},$subcomValues{"dataObj.varName"});
      
      drawPlot(plot);
      
      if(self.varList.length>1){
         self.varList.shift();
         self.colorList.shift();
         self.subplot=1;
         self.getData();
      }
      else{
         self.subplot=0;
      }
   }
}

function addPlot(){
   plotArray.push(new plotObj);
   plotArray[plotArray.length-1].buildPlot();
}

</script>
</head>

<body onLoad="addPlot();">
<div id="plotsHolder">
   
</div>
<br />
<input type="button" id="addPlot" name="Add Plot" value="Add Plot" onClick="addPlot();" />
</body>
</html>
HTML
