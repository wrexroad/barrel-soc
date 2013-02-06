#!/usr/bin/perl

use SOC_config qw(%configVals %dataTypes @payloads);
use SOC_funcs qw(getVarInfo getCgiInput);

print "Content-Type: text/html \n\n";

my %input = ();
my ($group, $pays, $vars, $configData, $activePays) = "";

#get user input
%input = %{getCgiInput()};

if(!%input){
   $input{"group"} = "gps";
   $input{"subgroup"} = "---";
   $input{"write"} = "0";
}

#get the group ID out of %input
if($group = $input{'group'}){
   delete $input{'group'};
}

#check for a subgroup
if($subgroup = $input{'subgroup'}){
   delete $input{'subgroup'};
}

#get the list of variables for this group
$vars = '"' . join('","' , sort (keys %{$dataTypes{$group}}) ) . '"';

#create payload list string
$pays = '"' . join('","' , sort @payloads) . '"';

#find out if we are writing or just reading
if($write = $input{'write'}){
   delete $input{'write'};
}

if($write == 1){
   #rewrite config file with JSON formatted data
   open(
      OUTPUT, ">" . $configVals{'socNas'} . "/datafiles/" . $group . "Config"
   ) or print 
      "Can't open " . $configVals{'socNas'} . "/datafiles/" . 
      $group . "Config" . " file for editing..." and die;
      print OUTPUT '{' . "\n";
      foreach my $payload (sort keys %input){
         print OUTPUT "\t" . '"' . $payload . '"' . ' : { ' . "\n";

         foreach my $var (sort keys %{%input->{$payload}}){
            if (%input->{$payload}{$var} eq "undefined"){
               %input->{$payload}{$var} = "---";
            }
            print OUTPUT 
               "\t\t" . '"' . $var . '"' . ' : ' . '"' . 
               %input->{$payload}{$var} . '"' . ", \n";
         }
         print OUTPUT "\t\t\"\" : \"\"\n\t},\n"; 
      }
      print OUTPUT "\t\"\" : \"\"}\n";
   close OUTPUT;
}

#open or create the config file
unless(
   open(CONFIG,  
      $configVals{'socNas'} . "/datafiles/" . $group . "Config"
   )
){
   open(CONFIG, 
      "+>" . $configVals{'socNas'} . "/datafiles/" . $group . "Config"
   );
}
   while(my $line = <CONFIG>){
      chomp($line);
      $configData .= $line;
   }
close CONFIG;

#Get a list of active payloads
if(open(ACTIVES, $configVals{'socNas'} . "/datafiles/enablelist")){
   
   $activePays = '{';
   
   while(my $line = <ACTIVES>){
      chomp($line);
      my @fields = split ';', $line;
      
      if($fields[0] ne "" and $fields[1] ne "na" ){
         $activePays .= '"' . $fields[0] . '" : true, ';
      }
   }
   $activePays .= '"" : "" }';
   close ACTIVES;
}

print << "HTML";
<!DOCTYPE html>

<html>

<head>
   <title>Configurator</title>
   
   <style type="text/css">
      #selector{
         text-align: center;
      }
      #ctrls{
         float: right;
      }
      .payloadDiv{
         border: inset;
         float: left;
      }
      .inputDiv{
         float: right;
      }
      .clearDiv{
         float: clear;
      }
      .hide{
         display: none;
      }
      .show{
         
      }
   </style>
   
</head>

<body>
   <div id="selector">
      <button onclick='config.switchPage("gps", "---");'>
         GPS
      </button>
      <button onclick='config.switchPage("rc", "---");'>
         Rate Counters
      </button>
      <button onclick='config.switchPage("mag", "---");');">
         Magnetometers
      </button>
      <button onclick='config.switchPage("lc", "---");'>
         Light Curves
      </button>
      <button onclick='config.switchPage("hk","T");'>
         Temp
      </button>
      <button onclick='config.switchPage("hk","I");'>
         Current
      </button>
      <button onclick='config.switchPage("hk","V");'>
         Voltage
      </button>
   </div>
   <hr />
   <div id="ctrls"></div>
   <form method="post" action="/cgi-bin/setLimits.pl">
      <input type="hidden" id="group" name="group" value="" />
      <input type="hidden" id="subgroup" name="subgroup" value="" />
      <input type="hidden" id="write" name="write" value="1" />
      <input type="submit" value="Save" />
      <div id="contents"></div>
   </form>
   
   <script language="JavaScript">
      //module for reading configuration pages
      var config = function(){
         var vars = [$vars];
         var pays = [$pays];
         
         //try to parse JSON data
         var configData = new Object();
         try{
            configData = eval('(' + '$configData' + ')');
         }catch(err){
            for(var pay_i = 0; pay_i < pays.length; pay_i++){
               configData[pays[pay_i]] = new Object();
               for(var var_i = 0; var_i < vars.length; var_i++){
                  configData[pays[pay_i]][vars[var_i] + "_Min"] = "---";
                  configData[pays[pay_i]][vars[var_i] + "_Max"] = "---";
               }
            }
         }
         
         //add controls
         (function (){
            var ctrls = document.getElementById("ctrls");
            
            
            //add toggle inactive button
            var tempButton = document.createElement("button");
            tempButton.id = "togglePayloads";
            tempButton.innerHTML = "Hide Inactive Payloads";
            ctrls.appendChild(tempButton);
            tempButton.onclick = function(){
               config.toggleInactive();
            }
            
            var tempText = document.createTextNode(" | Copy from ");
            ctrls.appendChild(tempText);
            
            //create a dropdown menu
            var tempSel = document.createElement("select"); 
            tempSel.id = "cpyFromPay";
            ctrls.appendChild(tempSel);
            
            //add options to the list
            var option;
            for(pay_i in pays){
               option = document.createElement("option");
               option.text = pays[pay_i];
               option.value = pays[pay_i];
               tempSel.options.add(option);
            }
            
            tempText = document.createTextNode(" to ");
            ctrls.appendChild(tempText);
            
            //create another dropdown menu
            tempSel = document.createElement("select"); 
            tempSel.id = "cpyToPay";
            ctrls.appendChild(tempSel);
            
            //add option for all payloads
            option = document.createElement("option");
            option.text = "All";
            option.value = "All";
            tempSel.options.add(option);
            
            //add option for active payloads
            option = document.createElement("option");
            option.text = "Active";
            option.value = "Active";
            tempSel.options.add(option);
            
            
            for(pay_i in pays){
               var option = document.createElement("option");
               option.text = pays[pay_i];
               option.value = pays[pay_i];
               tempSel.options.add(option);
            }
            
            //add copy button
            tempButton = document.createElement("button");
            tempButton.innerHTML = "Copy";
            ctrls.appendChild(tempButton);
            tempButton.onclick = function(){
               //get the payload name we are copying to and from
               var srcPay = document.getElementById("cpyFromPay").value;
               var tempDest = document.getElementById("cpyToPay").value;
               var destPays = new Array();
               
               //turn destPay into an array containing approptiate payloads
               switch(tempDest){
                  case "All":
                     destPays = pays;
                     break;
                  case "Active":
                     for(var pay_i in pays){
                        if(config.activePays[pays[pay_i]]){
                           destPays.push(pays[pay_i]);
                        }
                     }
                     break;
                  default: 
                     destPays = [ tempDest ];
                     break;
               }
               
               //get all of the source and destination input elements
               var srcPayClass = srcPay + "Field";
               var srcFields = document.getElementsByClassName( srcPayClass );
               var destFields = new Array();
               for(var pay_i in destPays ) {
                  var tempClass = destPays[pay_i] + "Field";
                  var tempFields = document.getElementsByClassName( tempClass );
                  destFields[ destPays[ pay_i ] ] = tempFields;
               }
               
               //copy each input field, one by one, to each destination payload
               for( var field_i = 0; field_i < srcFields.length; field_i++ ){
                  var tempValue = srcFields[field_i].value;
                  
                  for( pay_i in destPays ){
                     destFields[ destPays[ pay_i ] ][ field_i ].value = 
                        tempValue;
                  }   
               }
            }
         })();
        
         return {
            //members
            "group": "$group",
            "subgroup": "$subgroup",
            "contentDiv": document.getElementById("contents"),
            "showInactive": true,
            "activePays": $activePays,
            
            "switchPage": function(group, subgroup){
               //check if we just need to change which subgroup is showing, 
               //or if we need to fetch new data
               if(config.group == group){
               
                  //remove contents of the page
                  while(config.contentDiv.childNodes.length > 0 ){
                     config.contentDiv.removeChild(
                        config.contentDiv.firstChild 
                     );
                  }
                  
                  //set the current group and subgroup
                  config.subgroup = subgroup;
                  document.getElementById('group').value=config.group;
                  document.getElementById('subgroup').value=config.subgroup;
                  
                  //generate the table of config values. 
                  //Use setTimeout so the display will refresh 
                  //as the data processes
                  setTimeout("config.displayData()", 0);  
               }else{
                  var url = "/cgi-bin/setLimits.pl?"
                           + "group=" + group  
                           + "&subgroup=" + subgroup 
                           + "&write=0";
                  window.location = url;
               }
            },
            
            "toggleInactive": function(button){
               
               if(config.showInactive){
                  //loop through all of the payload tables 
                  //and hide the inactive ones
                  for(var pay_i in pays){
                     if(!config.activePays[pays[pay_i]]){
                        document.getElementById("payload"+pays[pay_i]).className
                           = "payloadDiv hide";
                     }
                  }
                  
                  //toggle the flag and button contents
                  config.showInactive = false;
                  document.getElementById("togglePayloads").innerHTML = 
                     "Show All Payloads";   
               
               }else{
                  for(var pay_i in pays){
                     document.getElementById("payload" + pays[pay_i]).className 
                        = "payloadDiv";
                  }
                  
                  config.showInactive = true;
                  document.getElementById("togglePayloads").innerHTML = 
                     "Hide Inactive Payloads";
               }
            },
            
            "displayData": function(){
               
               //create an fuction that returns an text input element
               function textField(minMax){
                  var input = document.createElement('input');
                  input.id = pays[pay_i] + '*' + vars[var_i] + '_' + minMax;
                  input.name = pays[pay_i] + '*' + vars[var_i] + '_' + minMax;
                  input.className = display + " " + pays[pay_i] + "Field";
                  input.type = 'text';
                  input.size = '8';
                  try{
                     input.value = 
                        configData[
                           pays[pay_i]][vars[var_i] + '_' + minMax
                        ];
                  }catch(err){input.value = "---";}
                  return input;
               }
               
               for(var pay_i = 0; pay_i < pays.length; pay_i++){
                  var tempParent = document.createElement('div');
                  tempParent.id = "payload" + pays[pay_i];
                  tempParent.className = "payloadDiv";
                  tempParent.innerHTML = 
                     '<br /> Payload ' + pays[pay_i] + ':<br />';
                  
                  for(var var_i = 0; var_i < vars.length; var_i++){
                     var display = "show";
                     
                     if(config.subgroup != '---' 
                        && vars[var_i].indexOf(config.subgroup) != 0){
                        display = "hide";
                     }
                        var tempDiv = document.createElement('div');
                        tempDiv.className = 'inputDiv ' + display;
                           var indent = document.createTextNode(
                              "  " + vars[var_i] + ' Min : '
                           );
                        tempDiv.appendChild(indent);
                       
                        //use function to add a new text field
                        tempDiv.appendChild( new textField("Min"));
                        
                        tempParent.appendChild(tempDiv);
                        
                        tempDiv = document.createElement('div');
                        tempDiv.className = 'clearDiv';
                        tempParent.appendChild(tempDiv);
                        
                        tempDiv = document.createElement('div');
                        tempDiv.className =  'inputDiv ' + display;
                        
                        var indent = 
                           document.createTextNode(vars[var_i] + ' Max : ');
                        tempDiv.appendChild(indent);
                        
                        tempDiv.appendChild( new textField("Max"));
                        
                        tempParent.appendChild(tempDiv);
                        
                        tempDiv = document.createElement('div');
                        tempDiv.className = 'clearDiv';
                        tempParent.appendChild(tempDiv);
                  }
                  config.contentDiv.appendChild(tempParent);
                  tempParent = null;
               }
            }
         }

      }();
      
      //process and display data as long as a group as been set
      if("$group"){config.switchPage("$group","$subgroup");}
   </script>
</body>
</html>
HTML
