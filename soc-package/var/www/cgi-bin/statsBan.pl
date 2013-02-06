#!/usr/bin/perl

use SOC_config qw(@payloads %payloadLabels %configVals);

print "Content-Type: text/html \n\n";

#generate the payload code
my @allPayloads=sort(keys(%payloadLabels));
my $payloadCode="";
for(my $pay_i=0; $pay_i<scalar(@allPayloads); $pay_i++){
	$payloadCode = 
      $payloadCode."\n\t\t".'payloads['.$pay_i.']=new Array();'."\n";
	$payloadCode = 
      $payloadCode."\n\t\t".'payloads['.$pay_i.'].name="'.$allPayloads[$pay_i].'";'."\n";
	$payloadCode = 
      $payloadCode."\n\t\t".'payloads['.$pay_i.'].enable="0";'."\n";
}
		
#get system uptime
my @tmp = split /,/, `uptime`;
my $tmp = $tmp[1];
@tmp = split /up/, $tmp[0];
my $uptime = "Uptime: " . $tmp[1] . ", ";
@tmp = split /:/, $tmp;
$uptime .= $tmp[0] . " hours, and " . $tmp[1] . " minutes.";


#Start HTML page 
print << "HTML";
<html>
<head>
<style type="text/css">
	.holder{
		text-align:center;
		vertical-align:middle;
		margin-left:auto;
		margin-right:auto;
		padding:auto;
	}
	.marker{
		float:left;
		font-size:250%;
		text-align:center;
		height:auto;
		width:auto;
		padding:0;
		margin:0;
		overflow:hidden;
	}
	.hidden_marker{
		float:clear;
		position: absolute;
		left: 0;
		top: 0;
		height:0;
		width:0;
		padding:0;
		margin:0;
		overflow:hidden;
	}
	.markerColor{
		position:relative;
		left:0;
		top:0;
		height:0;
		width:0;
		padding:0;
		margin:0;
	}
	.markerContent{
		position:relative;
		height:auto;
		width:auto;
		z-index:1;
		margin:0;
		padding:5px;
	}
	#clock{
		float:right;
		padding:0;
		margin:0;
	}
	#revNum{
		float:right;
		font-size:75%;
		padding:0;
		margin:0;
	}
	.floatClear { clear:both; }
</style>
<script language="JavaScript" type="text/javascript" src="/getFile.js"></script>
<script language="javascript">
	function resizeAll(){
		els=document.getElementsByClassName("markerColor");
		for(var el_i=0; el_i<els.length; el_i++){
			els[el_i].style.top=(els[el_i].parentNode.offsetHeight*-1)+"px";
			els[el_i].style.width=els[el_i].parentNode.offsetWidth+"px";
			els[el_i].style.height=els[el_i].parentNode.offsetHeight+"px";
			els[el_i].parentNode.style.height=els[el_i].parentNode.offsetHeight/2;
		}
	}
	
	function bannerObj(){
		var payloads = new Array();
		$payloadCode
		
		//create the banner
		var bannerDiv = document.createElement('div');
		var bannerCode = "";
		bannerDiv.setAttribute("id","bannerHolder");
		bannerDiv.setAttribute("class","holder");
		
		//add payload markers to the banner
		for(var pay_i=0; pay_i<payloads.length; pay_i++){
			bannerCode=bannerCode+'<div class="marker">';
			bannerCode=bannerCode+'<div class="markerContent" id="'+payloads[pay_i].name+'div">'+payloads[pay_i].name+'</div>';
			bannerCode=bannerCode+'<img class="markerColor"  id="'+payloads[pay_i].name+'" src="/images/greyAlert.jpg" />';
			bannerCode=bannerCode+'</div>';
		}
		
		//add a clock holder to the banner
		bannerCode=bannerCode+'<div id=clock>Last Update: N/A</div>';
		
		//add the float clear div
		bannerCode=bannerCode+'<div class="floatClear"></div>';
		
		//add a clock holder to the banner
		bannerCode=bannerCode+"<div id=revNum>$configVals{revNum}</div>";
		
		//add the float clear div
		bannerCode=bannerCode+'<div class="floatClear"></div>';
		
		//attach the code to the page
		bannerDiv.innerHTML=bannerCode;
		document.getElementById('bannerBody').appendChild(bannerDiv);
	
		
		//create the enables request object
		var enableReq = new getFile();
		enableReq.parent=this;
		enableReq.processPage =  function(){
		   var lines = enableReq.response.split("\\n");
			
         //clear all current payload enable flags
         for(var pay_i = 0; pay_i < payloads.length; pay_i++){
            payloads[pay_i].enable = 0;
         }
        
         //set the correct flags 
         for(var line_i = 0; line_i < lines.length; line_i++){
            //get a payload name from the line
            var fields = lines[line_i].split(";");
           
            for(var pay_i = 0; pay_i < payloads.length; pay_i++ ){
               if(payloads[pay_i].name == fields[0]){
                  //get list of alerts for the enabled payload
					   alertReq.seturl(
					      "/soc-nas/payload" + payloads[pay_i].name
						   + "/.errorlist?"+Math.random()
					   );
					   alertReq.sendReq();
					  
					   //set enabled flag
					   payloads[pay_i].enable = 1;
               }
            }
			}
			
			//hide all of the non-enabled payloads
			for(var pay_i = 0; pay_i < payloads.length; pay_i++ ){
				if(payloads[pay_i].enable == 0){
					//hide the markers of not enabled payloads
					var el = document.getElementById(payloads[pay_i].name);
					el.setAttribute("src","");
					
					el = document.getElementById(payloads[pay_i].name + "div");
					el.parentNode.className = "hidden_marker";
				}
			}
		}
		
		//create the alerts request object
		var alertReq = new getFile();
		alertReq.parent=this;
		alertReq.processPage = function(){
			//get the payload info
			var payload = 
			   alertReq.response.substring(0, alertReq.response.indexOf("\\n"));
			var alerts =
			   alertReq.response.substring(alertReq.response.indexOf("\\n") + 1);
			
			//get the icon elements
			var iconHolder = document.getElementById(payload + "div");
			var icon = document.getElementById(payload);
			
			//make sure we have a payload
			if(payload == ""){return;}
			
			if(iconHolder != null){
				//set the tooltip
				iconHolder.title = alerts;
				
				//unhide the marker
				iconHolder.parentNode.className = "marker";
				iconHolder.width = 5;
			}
			
			if(icon != null){
				if(alerts.indexOf("OK") != -1){//no alerts
					icon.setAttribute("src", "/images/greenAlert.jpg");
				}
				else if(alerts.indexOf("!") != -1){//red alert
					icon.setAttribute("src", "/images/redAlert.jpg");
					
					if($configVals{'popups'}){
						var site = "/cgi-bin/popup.pl?" + payload + "&" + Math.random();
						window.open(
						   site, payload,
							'toolbar=no,statusbar=no,location=no,scrollbars=yes,resizable=yes,width=320,height=250'
						)
					}
				}
				else{//yellow alert
					icon.setAttribute("src", "/images/yellowAlert.jpg");
				}
			}
		}
		
		function getTime(){
			var date = new Date();
			document.getElementById('clock').innerHTML=
			   "Last Update: " + date.toUTCString() + "<br />" + "$uptime";
		
		}
		
		function loadData(){
        getTime();
			enableReq.seturl("/soc-nas/datafiles/enablelist?"+Math.random());
			enableReq.sendReq();
			setTimeout(function(){loadData()},5000);
		}
		
		//accessor
		this.startData = function(){loadData();}
		
	}
</script>
</head>
<body id="bannerBody" onload="resizeAll();">
	<script language="javascript">
		bannerObj=new bannerObj();
		bannerObj.startData();
	</script>	
</body>
</html>
HTML

1;
