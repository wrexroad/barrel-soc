<?php

#expected input:payload,varName,length,dataType,dataLoc,limits

#Define Objects
class dataObj{
   #properties
   private $payload="-";
   private $workingDate=0;
   private $dateOffset="-";
   private $dataType="-";
   private $fileName="-";
   private $dataPath="-";
   private $reqLength=0;
   private $foundLength=0;
   private $varName="-";
   private $scale="lin";
   private $fcData=array();
   private $timeData=array();
   private $varData=array();
   private $fcData_i=0;
   private $timeData_i=1;
   private $varData_i=-1;
   
   #methods
   function __construct(){
      $this->payload = $_GET["payload"];
      $this->reqLength = $_GET["length"] * 3600;
      $this->varName = $_GET["varName"] ;
		$this->dataType = $_GET["dataType"];
		$this->dataPath = str_replace('\\','/',$_GET['dataLoc']);
      
		if(isset($_GET["singleDay"])){
			$this->singleDay = $_GET["singleDay"];
		}else{
			$this->singleDay = "false";
		}
		
      if(
			!isset($_GET["date"]) &&
			!isset($_GET["start_date"])	
		){
			$this->setWorkingDate();
		}
      else{$this->workingDate = $_GET["date"];}
      
      if($this->dataType == "gen"){$this->fileName='.datasci';}
      elseif($this->dataType == "mag"){
			$this->fileName='.mag';
			$this->varName = $this->varName . "_Ave";
		}
      elseif($this->dataType == "lc"){$this->fileName='.lc';}
      elseif($this->dataType == "rc"){$this->fileName='.rc';}
      elseif($this->dataType == "gps"){$this->fileName='.gps';}
      elseif($this->dataType == "T"){$this->fileName='.T';}
      elseif($this->dataType == "I"){$this->fileName='.C';}
      elseif($this->dataType == "V"){$this->fileName='.V';}
      elseif($this->dataType == "flight"){
			$this->fileName = '.flightpath';
			$this->startDate = $_GET["start_date"];
			$this->endDate = $_GET["end_date"];
			$this->startTime = $_GET["start_time"];
			$this->endTime = $_GET["end_time"];
		}
      else{$this->fileName='.datahouse';}
   }
   
   private function setWorkingDate(){
      if(($fh=fopen($this->dataPath."/payload".$this->payload."/.currentdate",'r'))!==FALSE){
         $this->workingDate=fread($fh,6);
         fclose($fh);
      }
      echo $this->workingDate."\n";
   }
   
	public function printFlightPath(){
		#open flightpath file
		$path = $this->dataPath."/payload".$this->payload."/.flightpath";
		if(($fh=fopen($path,'r')) !== FALSE){
			#print payload id
			echo $this->payload . "\n";
			
			while(($line = fgets($fh)) !== FALSE){
				$temp = explode(",", $line);
				
				if( #check for good gps coordinates
					($parts[3] !== 0) &&
					($parts[4] !== 0) &&
					($parts[5] !== 0)
				){
					if($this->startDate !== $this->endDate){ #check if we 
						
						if( #check if the line is from the start date
							($temp[0] == $this->startDate) && 
							($temp[2] % 86400 >= $this->startTime)
						){
							echo $line;
						}elseif( #check if it is within the date range
							($temp[0] > $this->startDate) &&
							($temp[0] < $this->endDate)){
							echo $line;
						}elseif( #check if the line is from the end date
							($temp[0] == $this->endDate) && 
							($temp[2] % 86400 <= $this->endTime)
						){
							echo $line;
						}
					}else{
						#the start and end date are the same,
						#check if the line is within the time range
						if(
							($temp[0] == $this->startDate) &&
							(($temp[2] % 86400) >= $this->startTime) &&
							(($temp[2] % 86400) <= $this->endTime)
						){
							echo $line;
						}
					}
				}
			}
			
			fclose($fh);
		}
		else{
			echo "Could not open flightpath file!";
			exit(); 
		}
	}
	
   public function readDataFile(){
      #open the data file and look for the column containing the requested data
      if(
			($fh=
				fopen(
					$this->dataPath . "/payload" . $this->payload . "/" .
					$this->fileName . $this->workingDate, 'r'
				)
			) !== FALSE
		){
         $labels = array();
         $labels = fgetcsv($fh, 1000, ",");
         for($label_i = 0; $label_i < count($labels); $label_i++){
            if($labels[$label_i] == $this->varName){
               $this->varData_i = $label_i;
            }
         }
         
			#make sure we found the requested column before continuing
         if($this->varData_i != -1){
            $line_i = 0;
            while(($line = fgetcsv($fh, 1000, ",")) !== FALSE){
               #read through the data file and save the needed collumns
               $this->fcData[$line_i] = $line[0];
               $this->timeData[$line_i] = $line[1];
               $this->varData[$line_i] = $line[$this->varData_i];
               
               $line_i++;
            }
            fclose($fh);
				
				#print out the data we have so far
				$this->printData();
				
				#figure out if we need more data
				$this->reqLength -= $this->foundLength;
				
				if($this->reqLength > 0 && $this->singleDay !== "true"){
					
					#convert current day to unix time
					$year = "20" . substr($this->workingDate, 0, 2);
					$month = substr($this->workingDate, 2, 2);
					$day = substr($this->workingDate, 4, 2);
					$date = strtotime($year . "-" . $month . "-" . $day);
					
					#calculate unix time of previous day
					$date -= 86400;
					
					#save the string of the new date
					$this->workingDate = date('ymd', $date);
					
					#get the previous day's data
					if(
						($fh =
						   fopen(
								$this->dataPath . "/payload" . $this->payload . "/" .
								$this->fileName . $this->workingDate, 'r'
							)
						) !== FALSE
					)
					{
						#reinitialize everything
						$this->fcData = array();
						$this->timeData = array();
						$this->varData = array();
						
						#ignore the title line
						fgets($fh);
						
						#get the rest of the data
						$line_i=0;
						while(($line=fgetcsv($fh, 1000, ","))!==FALSE){
							#read through the data file and save the needed collumns
							$this->fcData[$line_i] = $line[0];
							$this->timeData[$line_i] = $line[1];
							$this->varData[$line_i] = $line[$this->varData_i];
							
							$line_i++;
						}
						fclose($fh);
						
						#print the remaining data
						$this->printData();
					}
				}
	    #dump the extra lines
	    #$this->varData=array_slice($this->varData,($this->reqLength-1));
	    #$this->fcData=array_slice($this->fcData,($this->reqLength-1));
	    #$this->timeData=array_slice($this->timeData,($this->reqLength-1));
         }
         else{
            fclose($fh);
            echo $this->varName . " not found in " . $this->dataPath .
					"/payload" . $this->payload . "/" .
					$this->fileName . $this->workingDate . ".<br />\n";
            exit(); 
         }
      }
      else{
         echo "Could not open " .
				$this->fileName . $this->workingDate . ".<br />\n";
         exit();
      }
   }
   
   private function printData(){
      $lineCount = 0;
      while($lineCount < $this->reqLength && count($this->fcData) > 0){
         $fcVal = array_pop($this->fcData);
         $timeVal = array_pop($this->timeData);
         $varVal = array_pop($this->varData);
         
         #format the time field
         $timeVal = (int)($timeVal / 1000); //convert ms to s
         $timeVal = $timeVal % 86400; //get rid of any full days worth of seconds
         $hours = (int)($timeVal / 3600);
         $timeVal = $timeVal % 3600;
         $mins = (int)($timeVal / 60);
         $secs = $timeVal % 60;
         $date = 
            "20" . substr($this->workingDate, 0, 2) . "/" .  
            substr($this->workingDate, 2, 2) . "/" .  
            substr($this->workingDate, 4, 2);
            
         printf(
            "%d,%s %02d:%02d:%02d,%s\n", 
            $fcVal, $date, $hours, $mins, $secs, $varVal
         );
         
         $lineCount++;
      }
   }
}

class limitObj{
   #initialize members
   private $payload="-";
   private $filePath="-";
   private $dataType="-";
   private $varName="-";
   private $upperLimit="-";
   private $lowerLimit="-";
   
   function __construct(){
      $this->payload=$_GET["payload"];
      $this->varName=$_GET["varName"];
      
		if(
			$_GET["dataType"] === "I" ||
			$_GET["dataType"] === "T" ||
			$_GET["dataType"] === "V"
		){
			$this->dataType = "hk";
		}else{
			$this->dataType=$_GET["dataType"];
		}
		
      $this->filePath="/mnt/soc-nas/datafiles/".$this->dataType."Config";
   }
   
   public function readLimitFile(){   
      #check if we are getting limits for the mag variables
      if($this->dataType === "mag"){
         $this->varName = substr($this->varName, 0, 5);
      }
      
      #grab the limit file
      $json = file_get_contents($this->filePath);
      
      if($json){
	 #parse the file as json data
         $limits = json_decode($json, true);
	 
	 #save the limits to print later
	 $this->lowerLimit = $limits[$this->payload][$this->varName . "_Min"];
	 $this->upperLimit = $limits[$this->payload][$this->varName . "_Max"];
      }
      else{
         echo "Could not open configuration file " .
	 $this->filePath . " for " . $this->varName . ".<br />\n";
      }
   }
   
   public function printLimits(){
      echo $this->lowerLimit."\n";
      echo $this->upperLimit."\n";
   }
}

#create needed objects and retrieve requested information
$data = new dataObj;
if($_GET["dataType"] == "flight"){
	$data->printFlightPath();
}else{
	$data->readDataFile();
	
	if($_GET["limits"]=="On"){
		$limits = new limitObj;
		$limits->readLimitFile();
		$limits->printLimits();
	}
}

exit(0);
?>
