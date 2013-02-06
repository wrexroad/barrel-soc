function imageZoom(){

   var self=this;
   var container;
   var pivMems = {
      containerEl:undefined,
      imageURL:undefined,
      imageEl:undefined
   };
   
   //accessors
   self.setContainer = function(container){
      privMems.containerEl=document.getElementById(container);
   }
   self.setImage = function(url){
      privMems.imageURL=url;
   }

   //public functions
   self.setCenterPoint = function(x,y){

   }
   self.zoomStep = function(direction){
   
   }
   self.draw = function(){
      if(verifyInput()==1){
         genImgCode();
      }
   }
   
   //private functions
   function verifyInput(){
      if(!privMems.containerEl){
         alert("imageZoom.js: No container element supplied");
      }
      if(!privMems.imageURL){
         alert("imageZoom.js: No Image Supplied");
      }
      return 0;
   }
   function genImgCode(){
      //create an image element
      privMems.imageEl=document.createElement('img');
      privMems.imageEl.setAttribute('src',privMems.imageURL);
      privMems.imageEl.setAttribute('height',privMems.containerEl.style.height)
      
      //attach element to the container element
      privMems.containerEl.appendChild(privMems.imageEl);
   }
}