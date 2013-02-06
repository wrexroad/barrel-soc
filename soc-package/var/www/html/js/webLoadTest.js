var loadTest = ( function () {
   var self = this;
   var logBox = document.getElementById("log");
   var d = new Date();
   
   //test file info
   var payload = "1A";
   var date = "120921";
   
   //set up simulated user variables
   var numOfUsers = 0;
   var users = null;
   var requestList = null;
   var delay = 0;
   
   //request urls
   var reqStrs = {
      "newData" : "/soc-nas/payload" + payload + "/.newdata",
      "onePlot" : "/cgi-bin/getData.php?payload=" + payload +
                     "&varName=I07_-DPU" +
                     "&xAxis=Time" +
                     "&length=1" +
                     "&dataType=temp" +
                     "&limits=On" +
                     '&dataLoc=/mnt/soc-nas',
      "sixPlot" : "/cgi-bin/getData.php?payload=" + payload +
                     "&varName=I07_-DPU" +
                     "&xAxis=Time" +
                     "&length=6" +
                     "&dataType=temp" +
                     "&limits=On" +
                     '&dataLoc=/mnt/soc-nas'
   }
   
   function simUser(){
      var self = this;
      self.respTimes = new Array();
      
      self.enable = false;
      self.setEnable = function(){self.enable = true;}
      self.unsetEnable = function(){self.enable = false;}
      
      //add holders for the request objects
      for( var type_i = 0 in requestList ){
         self[requestList[type_i]] = new getFile();
      }
      
      self.id = null;
   }
   simUser.prototype.run = function(user){
      if(user.enable){
         for(var req_i = 0 in requestList){
            //create http request object
            user[requestList[req_i]].processPage = function(){
               logBox.value = user[requestList[req_i]].response;
               user[requestList[req_i]] = new getFile();
            }
            
            user[requestList[req_i]].seturl(reqStrs[requestList[req_i]]);
            user[requestList[req_i]].sendReq();
         }
         
         user.timeout = window.setTimeout(function(){user.run(user)}, delay);
      }
   }
   simUser.prototype.end = function(user){
      window.clearTimeout(user.timeout);
   }
   
   function controls(){
      function start(){
      	 //get simulated user settings
         numOfUsers = document.getElementById("numOfUsers").value;
         users = new Array();
         delay = document.getElementById("delay").value * 1000;
         
         //get test type
         requestList = new Array();
         var types = document.getElementsByClassName("testSel");
         
         for(var type_i = 0 in types){
            if(types[type_i].checked){
	       requestList.push(types[type_i].id);
	    }
         }
         
         for(var user_i = 0; user_i < numOfUsers; user_i++){
            users.push(new simUser());
            users[user_i].id = user_i;
            users[user_i].setEnable();
            users[user_i].run(users[user_i]);
            d = new Date();
            logBox.value += 
               "Started user " + user_i + " at " + d.getTime() + "\n";
         }
      }
      
      function stop(){
         for(var user_i = 0; user_i < numOfUsers; user_i++){
            users.push(new simUser());
            users[user_i].unsetEnable();
            users[user_i].end(users[user_i]);
            d = new Date();
            logBox.value += 
               "Stopped user " + user_i + " at " + d.getTime() + "\n";
         }
      }
      
      return {
         start : function(){start();},
         stop : function(){stop();}
      }
   }
   
   return {
      controls : controls()
   }
})();
