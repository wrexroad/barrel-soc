#!/usr/bin/perl

use SOC_config qw(%dataTypes %payloadLabels %configVals @payloads);
use libs::SOC_funcs qw(getVarInfo);

print "Content-Type: text/html \n\n";

#Create a strings that can be dumped into javascript variables
#for payloads
my $jsPayloads = '["' . join('","', @payloads) . '"]';

#for variables
my %vars;
getVarInfo(\%dataTypes, \%vars);
my $jsVars = '{"' . join('": "", "', @{$vars{'vars'}}) . '": ""}';

print << "HTML";
<!DOCTYPE html>
<html>
<head>
<title>File Viewer</title>

<style type="text/css">
   .clearDiv{
      float: clear;
   }
   #plotDiv, #controlDiv, #messageDiv{
      border-style: inset; 
      padding: 0; 
      margin: 0; 
      overflow: auto;      
   }
   #plotDiv{
      height: auto;
      width: 100%;
   }
   #controlDiv{
      height: 100px;
      width:70%;
      float: left;
   }
   #messageDiv{
      height: 100px;
      width:25%;
      float: right;
   }
   .newIn{
      color: gray;
      font-style: italic;
   }
</style>

</head>
<body>

<div id="plotDiv">
   <canvas width="50" hieght="50">
   </canvas>
</div>

<div id="controlDiv">
   Date: 
      <input
         id="date" 
         class="newIn"
         type="text" 
         size="10" 
         value="yymmdd"
         onfocus="inCtrl.initField(this);"
         onblur="inCtrl.set(this);"
      ></input>
   
   Payload: 
      <select id="payload">
         <option value="test">Test1</option>
      </select>
   <br />
   
   Var1: 
      <select id="var1" class="newIn">
         <option>Variable</option>
      </select>
   Var2: 
      <select id="var2" class="newIn">
         <option>Variable</option>
      </select>
   Var3: 
      <select id="var3" class="newIn">
         <option>Variable</option>
      </select>
   Var4: 
      <select id="var4" class="newIn">
         <option>Variable</option>
      </select>
   <br />
      
   Plot Max 
      <input
         id="max" 
         type="text" 
         size="10" 
         value=""
      ></input>
      
   Plot Min 
      <input
         id="min" 
         type="text" 
         size="10" 
         value=""
      ></input>
   
</div>

<div id="messageDiv">
</div>

<div class="clearDiv">
</div>

<script language="JavaScript" src="/getFile.js" ></script>
<script language="JavaScript" src="/js/dave-js/dave.js" ></script>

<script language='JavaScript'>
   
   //set up dave.js
   Dave_js.setLibRoot("/js/dave-js");
   Dave_js.setStyleRoot("/js/dave-js");
   Dave_js.init();
   
   //create an object that will control the input fields
   var inCtrl = function(){
      var self = this;
      
      var payloads = $jsPayloads;
      var variables = $jsVars;
      var fileLookup = $jsFiles;
      
      return {
         initField : function(el){
            //save the old sample value in case the field is left unset
            el.oldValue = el.value;
            
            //clear out the sample value if this is a text field 
            el.value = "";
            //remove the "newIn" class
            el.className = el.className.replace("newIn", "");
         },
         set : function(el){
            //check to see if the input has been set, 
            //if not replace the old value
            if( el.value == "" ){
               el.value = el.oldValue;
               
               //if the field has never been set, restore the newIN class
               if(!el.set && el.type == "text"){
                  el.className = el.className + " newIn";
               }
            }else{
               //flag that we have set the value
               el.set = true;
               
               //remove the onfocus event and save the value
               el.onfocus = null;
               el.oldValue = el.value;
            }
         }
      }
   }();
</script>
</body>
HTML
