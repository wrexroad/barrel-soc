function getFile() {
	var self=this;
	
	self.seturl = function(url){
		self.url=url;
	}
	
	self.sendReq = function(){
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
			xmlhttp.open("GET", self.url, true);
			xmlhttp.onreadystatechange=function(){
				if(xmlhttp.readyState==4){//save the response text to the request object when the page loads
					self.response=xmlhttp.responseText;
					self.processPage();
				}
			}  
		}else{
			window.alert("Your browser does not support XMLHTTPREQUEST objects. Can not display plot.");
			return false;
		}
		xmlhttp.send(null);
	}
	
	this.processPage = function(){
		return 1; // A do-nothing function that needs to be replaced when creating the object
	}
}
