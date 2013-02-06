function drawPlot(plot) {
   //get element to put errors in
   var errorBox=document.getElementById(plot.errorBoxName);
   
   //set special values based on browser
   var userAgent=navigator.userAgent;
   if (userAgent.indexOf("MSIE")!=-1){
      if (parseInt(navigator.appVersion)<9 && errorBox!=null){
         errorBox.innerHTML='<center>Internet Explorer does not support HTML5 canvas. Please use Google Chrome, Firefox, Opera, or Safari</center>';
         return;
         }
   }
   else if(userAgent.indexOf("Firefox")!=-1){
      if (parseInt(navigator.appVersion)<3 && errorBox!=null){
         errorBox.innerHTML="<center>Firefox 3.0 or later required for text display</center>";
         }
      var userAgent="Firefox";
      var rot=1;
   }   
   else {
      var rot=1;
   }   
      
   //if we made it past the browser check, add canvas stuff
   var canvasParent=document.getElementById(plot.plotBoxName);
   var canvas = document.getElementById(plot.canvasName);
	
	//clear the canvas for a new graph
   if(plot.subplot != 1){
      //if there is already a canvas, remove it
      if(canvas){
         canvasParent.removeChild(canvas);
         canvas = null;
      }
   
      //create a canvas
      canvas = document.createElement("canvas");
      canvas.setAttribute("id",plot.canvasName);
      canvas.setAttribute("width",plot.canvasWidth);
      canvas.setAttribute("height",plot.canvasHeight);
      canvasParent.appendChild(canvas);
   }
   
   //initialize context
   var ctx = null;
   ctx = canvas.getContext("2d"); 
   
   //set up the coordinate display box
   plot.chartHeight=plot.canvasHeight-plot.chartMargin;
   plot.chartWidth=plot.canvasWidth-plot.chartMargin;
   
   var xCoordBox=document.getElementById(plot.xCoordBoxName);
   var yCoordBox=document.getElementById(plot.yCoordBoxName);
   if(xCoordBox && yCoordBox){
      //make oldIndex variable presist after point highligher subroutine ends
      var oldIndex=0;
      //add mouse position listener to canvas
      canvas.addEventListener('mousemove', ev_mousemove, false);
   }   
   
      
   //move coord matrix to the upper left corner of plot area
   ctx.translate(plot.origX,plot.origY);
   
   //draw background
   if(plot.subplot != 1){
      if(plot.backgroundImageID){
         ctx.drawImage(plot.backgroundImageID,0,0);
      }
      else if(plot.backgroundColor){
         ctx.fillStyle = plot.backgroundColor;
         ctx.fillRect(0,0,plot.chartWidth,plot.chartHeight);
      }
   }
   
   //draw legend
   if(plot.legend=="yes" && plot.polar == 1){
      var xLegendCoord = 0;
      
      for (var legend_i=0; legend_i < plot.yVars.length; legend_i++){
         if (plot.yVars[legend_i-1]){xLegendCoord=xLegendCoord+((plot.yVars[legend_i-1].length)*10);}
         ctx.fillStyle = plot.pointColor[legend_i];
         ctx.fillText(plot.yVars[legend_i],xLegendCoord,-10);
      }
   }else{
      if(plot.legend && plot.polar == 1){
         var LegendCoord = 0;
       
         for (var legend_i=0; legend_i < plot.legend.length; legend_i++){
            ctx.fillStyle = plot.pointColor[legend_i];
            ctx.fillText(plot.legend[legend_i],0,LegendCoord);
            LegendCoord+=10;
      }
      }
   }
   
   //draw border
   ctx.strokeStyle = plot.borderColor; 
   ctx.strokeRect(0,0,plot.chartWidth,plot.chartHeight);
   
   //print title
   ctx.textAlign="center";
   ctx.fillStyle=plot.textColor;
   if (plot.title){ //check if title was provided and make it bold
      ctx.font="bold " + plot.cssFont;
      ctx.fillText(plot.title,plot.canvasWidth/2,-5);
   }
   
   //set xy or polar plot flags
   if(plot.type.indexOf("xy")!=-1){plot.xy=1;}
   else if(plot.type.indexOf("polar")!=-1){plot.polar=1;}
   
   //set points or lines flags
   if(plot.type.indexOf("line")!=-1){plot.lines=1;}
   else if(plot.type.indexOf("point")!=-1){plot.points=1;}
   
   //do stuff for rectangular plots
   if(plot.xy || plot.type=="line" || plot.type=="points" || plot.type=="linesANDpoints" || plot.hist){
      
      //Scale the plot if needed
      if(plot.scale){scaler();}      
		
      //print axis labels
      if(plot.subplot!=1){
         ctx.font=plot.cssFont;
         ctx.textAlign="start";
         if (plot.xAxisLabel){ctx.fillText(plot.xAxisLabel,-plot.origX,plot.chartHeight+60);}
         ctx.save();
         ctx.translate(-45,plot.chartHeight/2);
         ctx.rotate(rot*1.5* Math.PI);  
         ctx.textAlign="center";
         if (plot.yAxisLabel){ctx.fillText(plot.yAxisLabel,0,0);}
         ctx.restore();
      }
      
      //force all of the y values to be seen as numbers, not strings
      for(var i=0; i < plot.yVals.length; i++){
         for(var j=0; j<plot.yVals[i].length; j++){
            plot.yVals[i][j]=+plot.yVals[i][j];
         }
      }      
      
      //find min and max y values if they are not provided
      if(plot.yMin=="" || plot.yMax=="" || isNaN(+plot.yMin) || isNaN(+plot.yMax)){
         //find the first set of valid numbers
         var i=0;
         while(isNaN(parseInt(plot.yVals[0][i])) && i < plot.yVals[0].length){
            i++;
         }
         plot.yMax=plot.yVals[0][i];
         plot.yMin=plot.yVals[0][i];   
         //look for min and max values
         for(var j=0; j < plot.yVals.length; j++){
            for(var i=0; i < plot.yVals[j].length; i++){
               if(plot.yVals[j][i] < plot.yMin){plot.yMin=plot.yVals[j][i];}
               else if(plot.yVals[j][i] > plot.yMax){plot.yMax=plot.yVals[j][i];}
            }
         }
      }
      else{
         //force min and max values to be numbers if they were manually set
         plot.yMin=+plot.yMin;
         plot.yMax=+plot.yMax;
         
         //force provided values to be within specified range
         for(var j=0; j<plot.yVals.length; j++){
            for(var i=0; i<plot.yVals[j].length; i++){
               if (plot.yVals[j][i]>plot.yMax){plot.yVals[j][i]=plot.yMax;}
               else if (plot.yVals[j][i]<plot.yMin){plot.yVals[j][i]=plot.yMin;}
            }
         }
      }
		
      //make sure the min and max y values are not the same
      if(plot.yMin==plot.yMax){
         plot.yMin=plot.yMin-(plot.chartHeight/2);
         plot.yMax=plot.yMax+(plot.chartHeight/2);
      }
      
      //set number of skipped y tics if not done manually   
      if (plot.ySkippedTics==undefined || !isNaN(plot.ySkippedTics)){plot.ySkippedTics=parseInt(Math.abs(plot.yMax-plot.yMin)/(plot.chartHeight/20));}
      if (plot.ySkippedTics<1){plot.ySkippedTics=1;}
      
      //make sure x and y tic skip values are >=1
      if (plot.ySkippedTics<1 || plot.ySkippedTics==undefined){plot.ySkippedTics=1;}
      if (plot.xSkippedTics<1 || plot.xSkippedTics==undefined){plot.xSkippedTics=1;}
      
      //figure out tic mark spacing
      plot.xSpacing=plot.chartWidth/(plot.xVals.length-1);
      plot.ySpacing=plot.chartHeight/(plot.yMax-plot.yMin);
      
      //draw yAxis tic marks and labels
      if(plot.subplot!=1){
      ctx.textAlign="end";
         for (var i=plot.yMin; i<=plot.yMax; i=i+plot.ySkippedTics){
				var offset=(plot.yMax-i)*plot.ySpacing;
            var ticLabel=parseInt(i*10)/10;
            drawTic();
         }
      }
		
      //draw xAxis tic marks and labels
      if(plot.subplot!=1 && !plot.hist){//histograms use a special x axis to esure bars line up with tics
         ctx.save();
         ctx.translate(0,plot.chartHeight);
         ctx.rotate(rot*1.5* Math.PI);
         for (var i=0; i<plot.xVals.length; i=i+plot.xSkippedTics){
            var offset=i*plot.xSpacing;
            var ticLabel=plot.xVals[i];
            drawTic();
         }
         ctx.restore();
      }
      
      //draw line
      if (plot.lines){
         //make sure we have a color for the line
         if(plot.lineColor != undefined){plot.lineColor=="red";}
         
         ctx.lineWidth=plot.lineWidth;
         for(var i=0; i<plot.yVals.length; i++){
            ctx.strokeStyle = plot.lineColor[i]; 
            ctx.beginPath();  
            var y0 = (plot.yMax-plot.yVals[0][0])*plot.ySpacing;
            if (isNaN(y0)) {y0=0;}
            ctx.moveTo(0, y0);
            for (var j=1; j<plot.xVals.length; j++)
               {
                  //check if we should ignore this point
                  if(plot.yVals[i][j]==undefined || isNaN(plot.yVals[i][j])){continue;}
                  
                  //draw a line segment
                  ctx.lineTo(j*plot.xSpacing, (plot.yMax-plot.yVals[i][j])*plot.ySpacing);
               }  
            ctx.stroke();
         }
      }
      
      //draw points
      if(plot.points){
         
         //make sure we have a defined color array
         if(!plot.pointColor){plot.pointColor=new Array();}
          
         for(var yVal_i=0; yVal_i<plot.yVals.length; yVal_i++){ //loop once for each array stored in plot.yVals
            
            //make sure we have a defined color to draw with
            if(!plot.pointColor[yVal_i]){plot.pointColor[yVal_i]="Black"}
            
            for (var xVal_i=1; xVal_i<plot.xVals.length; xVal_i++){ //loop through each sub array
               //check how to draw the point
               if(plot.xVals[xVal_i]=="GAP"){continue;}//ctx.fillStyle="gray";}
               else{ctx.fillStyle = plot.pointColor[yVal_i]; }
               
               if(plot.yVals[yVal_i][xVal_i]!=undefined && !isNaN(plot.yVals[yVal_i][xVal_i])){
                  ctx.fillRect(xVal_i*plot.xSpacing-(plot.pointSize/2), (plot.yMax-plot.yVals[yVal_i][xVal_i])*plot.ySpacing-(plot.pointSize/2),plot.pointSize,plot.pointSize);
               }
            }
         }
      }
		
		//draw histogram
		if(plot.hist){
			//figure out total possible bar size
			plot.histBarTotal=parseInt(plot.chartWidth/plot.xVals.length);
			
			if(plot.histBarTotal==0){plot.histBarTotal=1;}
				
			//make sure we have a useable bar width and margin
			plot.histBarWidth+=0;
			plot.histBarMargin+=0;
			if((plot.histBarWidth+plot.histBarMargin)>plot.histBarTotal || plot.histBarWidth==0 || isNaN(plot.histBarWidth)){
				plot.histBarWidth=parseInt(plot.histBarTotal*.9);
				if(plot.histBarWidth == 0){
					plot.histBarWidth=1;
					plot.histBarMargin=0;
				}else{
					plot.histBarMargin=plot.histBarTotal-plot.histBarWidth;
				}
			}
			
			//draw x axis tics and labels
			ctx.save();
         ctx.translate(0,plot.chartHeight);
         ctx.rotate(rot*1.5* Math.PI);
         for (var i=0; i<plot.xVals.length; i=i+plot.xSkippedTics){
            var offset=i*plot.histBarTotal+5;
            var ticLabel=plot.xVals[i];
            drawTic();
         }
         ctx.restore();
			
			//set bar width
			ctx.lineWidth=plot.histBarWidth;
			
			//make sure we have a defined color array
			if(!plot.barColor){plot.barColor=new Array();}
			 
			//if ymax>0>ymin, we need to find the location of the 0 line to plot fron
			if(plot.yMin<0 && plot.yMax>0){
				plot.baseLineOffset=plot.yMin;
			}else{plot.baseLineOffset=0;}
			
			for(var plotSet_i=0; plotSet_i<plot.yVals.length; plotSet_i++){ //loop once for each array stored in plot.yVals	
				//set stroke color
				if(!plot.barColor[plotSet_i]){plot.barColor[plotSet_i]="Black"}//make sure we have a defined color to draw with
				ctx.strokeStyle = plot.barColor[plotSet_i];
				
				for (var plotVal_i=0; plotVal_i<plot.yVals[plotSet_i].length; plotVal_i++){ //loop through each sub array
					if(plot.yVals[plotSet_i][plotVal_i]!=undefined && !isNaN(plot.yVals[plotSet_i][plotVal_i])){
						ctx.beginPath();
						ctx.moveTo(plotVal_i*(plot.histBarWidth+plot.histBarMargin)+(plot.histBarTotal/2),(plot.chartHeight+(plot.baseLineOffset*plot.ySpacing)));
						ctx.lineTo(plotVal_i*(plot.histBarWidth+plot.histBarMargin)+(plot.histBarTotal/2),(plot.yMax-plot.yVals[plotSet_i][plotVal_i])*plot.ySpacing);
						ctx.stroke();
					}
				}
			}
		}
		
      plot.totalOffsetX=plot.origX;
      plot.totalOffsetY=plot.origY;
            
      //Rotate and Translate back to the original coordinate system
      ctx.translate(-plot.totalOffsetX,-plot.totalOffsetY);
   }
   
   //draw circular plots
   else if(plot.polar){
      ctx.strokeStyle = plot.borderColor;  
      
      //do stuff for maps
      if(plot.type.indexOf("map")!=-1){
         //set map flag
         var map=1;
         
         //set north/south flag and invert values if needed
         if(plot.type.indexOf("south")!=-1){
            plot.direction=1;
         }
         else{
            plot.direction=-1;
         }
      }
      
      //if no plot direction, set to 1
      if(!plot.direction){plot.direction=1;}
         
      //figure how large our plot will be
      if(plot.canvasWidth>=plot.canvasHeight){plot.plotRadius=plot.canvasHeight/2;}
      else if(plot.canvasWidth<plot.canvasHeight){plot.plotRadius=plot.canvasWidth/2;}
      
      //move to center of plot 
      ctx.translate((plot.canvasWidth-plot.origX)/2,(plot.canvasHeight-plot.origY)/2);
      
      //find max radius if not set
      if(plot.radiusMax=="" || isNaN(+plot.radiusMax)){
         //look for radius max values
         plot.radiusMax==0;
         for(var i=0; i<plot.radiusVals.length; i++){
            for(var j=0; j<plot.radiusVals[i].length; j++){
               if(plot.radiusVals[i][j]>plot.radiusMax){plot.radiusMax=plot.radiusVals[i][j];}
            }
         }
      }   
      
      //convert radius values and max radius if this is a map
      if(map){
         for(var i=0; i<plot.radiusVals.length; i++){
            for(var j=0; j<plot.radiusVals[i].length; j++){
               plot.radiusVals[i][j]=90+plot.direction*plot.radiusVals[i][j];
            }
         }
         plot.radiusMax=90+plot.direction*plot.radiusMax;
      }
      
      //find the ratio of radius to pixels
      plot.radiiSpacing=plot.plotRadius/plot.radiusMax;
      
      //set standard radius circles if not defined and draw if we have a maximum radius
      if(plot.radiusMarks=="yes" && plot.radiusMax){
         if(!plot.gridRadii){
            plot.gridRadii=[(0.25*plot.radiusMax).toFixed(2),(0.5*plot.radiusMax).toFixed(2),(0.75*plot.radiusMax).toFixed(2),(plot.radiusMax).toFixed(2)];
         }
   
         ctx.textAlign="center";
         for(var i=0;i<plot.gridRadii.length;i++){
            ctx.beginPath();
            ctx.arc(0,0,plot.radiiSpacing*plot.gridRadii[i],0,2*Math.PI,true); 
            ctx.closePath();
            ctx.stroke();
            if(map){//alter labels if this is a map plot
               ctx.fillText(-90+plot.direction*plot.gridRadii[i],0,plot.radiiSpacing*plot.gridRadii[i]-5);
            }
            else{
               ctx.fillText(plot.direction*plot.gridRadii[i],0,plot.radiiSpacing*plot.gridRadii[i]-5);
            }
         }
      }
      
      //rotate the plot so zero lines up with where the use wants
      ctx.rotate(rot*plot.zeroAngle);
      
      if(plot.angleMarks=="yes"){
         //set standard angle lines if not specified
         if(!plot.gridAngles){
            if(map){
               plot.gridAngles=[0,Math.PI/4,Math.PI/2,3*Math.PI/4,Math.PI,-1*Math.PI/4,-1*Math.PI/2,-3*Math.PI/4,];
            }
            else{
               plot.gridAngles=[0,Math.PI/4,Math.PI/2,3*Math.PI/4,Math.PI,5*Math.PI/4,3*Math.PI/2,7*Math.PI/4];
            }
         }
         
         //Draw grid angle lines
         ctx.textAlign="start";
         for(var i=0;i<plot.gridAngles.length;i++){
            ctx.beginPath();  
            ctx.moveTo(0,0);
            ctx.save();
            
            ctx.rotate(plot.direction*rot*plot.gridAngles[i]); //rotate the coordinate system and draw a straight line
            ctx.lineTo(plot.plotRadius,0);
            ctx.stroke();
            
            ctx.translate(plot.plotRadius/2,0); //move coord system to text location, rotate by 90 degrees, and draw text
            ctx.rotate(rot*Math.PI/2);
            ctx.fillText((180*plot.gridAngles[i]/Math.PI)+"\u00B0",0,0);
            
            ctx.restore();
         }
      }
      //draw points
      if(plot.points && plot.radiusVals && plot.angleVals){
         //make sure we have a defined color array
         if(!plot.pointColor){plot.pointColor=new Array();}
         
         for(var i=0;i<plot.radiusVals.length;i++){
            //make sure we have a defined color to draw with.
            if(!plot.pointColor[i]){plot.pointColor[i]="Black"}
            
            ctx.fillStyle=plot.pointColor[i];
            ctx.strokeStyle=plot.pointColor[i];
            for(var j=0;j<(plot.radiusVals[i].length-1);j++){
					//make sure we have a valid point for angle and radius
					if(plot.radiusVals[i][j]==undefined || plot.angleVals[i][j]==undefined ||
						isNaN(plot.radiusVals[i][j]) || isNaN(plot.angleVals[i][j])){continue;}
               //rotate coord system, plot point, rotate back
               ctx.rotate(plot.direction*rot*plot.angleVals[i][j]*Math.PI / 180);
               ctx.fillRect(plot.radiiSpacing*plot.radiusVals[i][j],0,plot.pointSize,plot.pointSize);
               ctx.rotate(-1*plot.direction*rot*plot.angleVals[i][j]*Math.PI / 180);
            }
            //add perimiter label
            if(
					plot.legend &&
					plot.radiusVals[i][j] != 0 &&
					plot.angleVals[i][j] != 0
				){
					ctx.beginPath();
               ctx.rotate(plot.direction*rot*plot.angleVals[i][j]*Math.PI / 180);
               ctx.moveTo(plot.radiiSpacing*plot.radiusVals[i][j],0);
               ctx.lineTo(parseInt(plot.canvasWidth/2)-10,0);
               ctx.fillText(plot.legend[i], parseInt(plot.canvasWidth/2)-5,0);
               ctx.rotate(-1*plot.direction*rot*plot.angleVals[i][j]*Math.PI / 180);
               ctx.stroke();
               ctx.closePath();
            }
         }
      }
      
      plot.totalOffsetX=plot.chartWidth/2+plot.origX;
      plot.totalOffsetY=plot.chartHeight/2+plot.origY
      
      //Rotate and Translate back to the original coordinate system
      ctx.rotate(-1*rot*plot.zeroAngle);
      ctx.translate(-plot.totalOffsetX,-plot.totalOffsetY);
   }
   

   function scaler(){
      var scaleParam = plot.scale.split("-");
		scaleParam[1]=parseInt(scaleParam[1]);
      if(scaleParam[0]=="log"){//log plot
         for(var i=0;i<plot.yVals.length;i++){
            for(var j=0;j<plot.yVals[i].length;j++){
               if(plot.yVals[i][j]!=0){plot.yVals[i][j]=parseFloat((Math.log(plot.yVals[i][j])/Math.log(scaleParam[1])).toFixed(3));}
            }
         }
			//change y-axis label
			plot.yAxisLabel="log_"+scaleParam[1]+"("+plot.yAxisLabel+")";
      }
      else if(scaleParam[0]=="lin"){//linear plot
         for(var i=0;i<plot.yVals;i++){
            for(var j=0;j<plot.yVals[i];j++){
               plot.yVals[i][j]=plot.yVals[i][j]*scaleParam[1];
            }
         }
      }
   }
   
   function drawTic(){   
      if(ticLabel == "--") {ticLabel="No Label"}
      ctx.fillText(ticLabel,-5,offset+5);
      ctx.beginPath();
      ctx.moveTo(0,offset);  
      ctx.lineTo(plot.ticLength,offset);  
      ctx.stroke();
   }
   
   function ev_mousemove (ev) {
      // Get the mouse position relative to the canvas element.
      if (ev.layerX || ev.layerX == 0) { // Firefox
         var x = ev.layerX;
      } 
      else if (ev.offsetX || ev.offsetX == 0) { // Opera
         var x = ev.offsetX;
      }
      highlightPoint(parseInt((x-plot.origX)*(plot.xVals.length-1)/plot.chartWidth));
   }
   
   function highlightPoint(index) {
      var yCoordBoxCode='';
      
      //hightlight a point on mouseover if its not an empty point
      ctx.fillStyle=plot.activePointColor;
      for(var i=0; i<plot.yVals.length; i++){
         if(
				plot.yVals[i][index] == 0 ||
				plot.yVals[i][index] == "--"
			){continue;}
         if(plot.yVals[i][index] != undefined && !isNaN(plot.yVals[i][index])){
            ctx.fillRect(index*plot.xSpacing-(plot.pointSize/2)+plot.totalOffsetX, (plot.yMax-plot.yVals[i][index])*plot.ySpacing-(plot.pointSize/2)+plot.totalOffsetY,plot.pointSize,plot.pointSize);
         }
      }
      
      //restore previous color on mouseoff
      if(index != oldIndex){
         for(var i=0; i<plot.yVals.length; i++){
         if(
				plot.yVals[i][oldIndex] == 0 ||
				plot.yVals[i][oldIndex] == "--"
			){continue;}
				//ctx.fillStyle="gray";}
            else{ctx.fillStyle=plot.pointColor[i];}
            if(plot.yVals[i][oldIndex]!=undefined && !isNaN(plot.yVals[i][oldIndex])){
               ctx.fillRect(oldIndex*plot.xSpacing-(plot.pointSize/2)+plot.totalOffsetX, (plot.yMax-plot.yVals[i][oldIndex])*plot.ySpacing-(plot.pointSize/2)+plot.totalOffsetY,plot.pointSize,plot.pointSize);
            }
         }
      }
      
      //print corrds for plotted points
      if (plot.xVals[index]!=undefined){xCoordBox.innerHTML=plot.xAxisLabel+": "+plot.xVals[index];}
      var changedCoord=0;
      for(var i=0; i<plot.yVals.length; i++){
         if (plot.yVals[i][index]!=undefined && !isNaN(plot.yVals[i][index])){
            yCoordBoxCode=yCoordBoxCode+plot.yVars[i]+": "+plot.yVals[i][index]+"<br />";
            changedCoord++;
         }
      }
      if(changedCoord>0){yCoordBox.innerHTML=yCoordBoxCode;}
      
      //print extra coord info
      if (plot.track1!=undefined && !isNaN(plot.track1[index])){document.getElementById('track1Box').innerHTML=plot.trackVars[0]+": "+plot.track1[index];}
      if (plot.track2!=undefined && !isNaN(plot.track2[index])){document.getElementById('track2Box').innerHTML=plot.trackVars[1]+": "+plot.track2[index];}
      
      oldIndex=index;      
   }
}

