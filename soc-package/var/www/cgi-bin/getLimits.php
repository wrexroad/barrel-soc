<?php

#Define Objects
class limitObj{
   #initialize members
   private $payload="-";
   private $fileName="-";
   private $dataPath="-";
   private $varName="-";
   private $varName_i="-";
   private $upperLimit="-";
   private $lowerLimit="-";
   private $genVars=array("GPS_Lat_Min","GPS_Lat_Max","GPS_Lon_Min","GPS_Lon_Max","GPS_Alt_Min","GPS_Alt_Max","LowLevel_Min","LowLevel_Max","PeakDet_Min","PeakDet_Max","HighLevel_Min","HighLevel_Max","Interrupt_Min","Interrupt_Max","MAG_X_Min","MAG_X_Max","MAG_Y_Min","MAG_Y_Max","MAG_Z_Min","MAG_Z_Max","LC1_Min","LC1_Max","LC2_Min","LC2_Max","LC3_Min","LC3_Max","LC4_Min","LC4_Max","Pitch_Min","Pitch_Max","Roll_Min","Roll_Max","ADC_TEMP_Min","ADC_TEMP_Max");
   private $tempVars=array("T0_Scint_Min","T0_Scint_Max","T1_Mag_Min","T1_Mag_Max","T2_ChargeCont_Min","T2_ChargeCont_Max","T3_Battery_Min","T3_Battery_Max","T4_PowerConv_Min","T4_PowerConv_Max","T5_DPU_Min","T5_DPU_Max","T6_Modem_Min","T6_Modem_Max","T7_Structure_Min","T7_Structure_Max","T8_Solar1_Min","T8_Solar1_Max","T9_Solar2_Min","T9_Solar2_Max","T10_Solar3_Min","T10_Solar3_Max","T11_Solar4_Min","T11_Solar4_Max","T12_TermTemp_Min","T12_TermTemp_Max");
   private $voltVars=array("V0_VoltAtLoad_Min","V0_VoltAtLoad_Max","V1_Battery_Min","V1_Battery_Max","V2_Solar1_Min","V2_Solar1_Max","V3_DPU_Min","V3_DPU_Max","V4_XRayDet_Min","V4_XRayDet_Max","V5_Modem_Min","V5_Modem_Max","V6_XRayDet_Min","V6_XRayDet_Max","V7_DPU_Min","V7_DPU_Max","V8_Mag_Min","V8_Mag_Max","V9_Solar2_Min","V9_Solar2_Max","V10_Solar3_Min","V10_Solar3_Max","V11_Solar4_Min","V11_Solar4_Max","V12_TermBat_Min","V12_TermBat_Max","V13_TermCap_Min","V13_TermCap_Max","V14_ChargeCont_Min","V14_ChargeCont_Max");
   private $ampVars=array("I0_TotalLoad_Min","I0_TotalLoad_Max","I1_TotalSolar_Min","I1_TotalSolar_Max","I2_Solar1_Min","I2_Solar1_Max","I3_DPU_Min","I3_DPU_Max","I4_XRayDet_Min","I4_XRayDet_Max","I5_Modem_Min","I5_Modem_Max","I6_XRayDet_Min","I6_XRayDet_Max","I7_DPU_Min","I7_DPU_Max");
      
      function __construct(){
      $this->payload=$_GET["payload"];
      $this->varName=$_GET["varName"];
      for($varName_i=0; $varName_i<count($this->genVars) and $this->fileName=="-"; $varName_i++){
         if($this->genVars[$varName_i]==$this->varName."_Min"){
            $this->fileName="/mnt/soc-nas/datafiles/genConfig";
         }
      }
      for($varName_i=0; $varName_i<count($this->tempVars) and $this->fileName=="-"; $varName_i++){
         if($this->tempVars[$varName_i]==$this->varName."_Min"){
            $this->fileName="/mnt/soc-nas/datafiles/tempConfig";
         }
      }
      for($varName_i=0; $varName_i<count($this->voltVars) and $this->fileName=="-"; $varName_i++){
         if($this->voltVars[$varName_i]==$this->varName."_Min"){
            $this->fileName="/mnt/soc-nas/datafiles/voltConfig";
         }
      }
      for($varName_i=0; $varName_i<count($this->ampVars) and $this->fileName=="-"; $varName_i++){
         if($this->ampVars[$varName_i]==$this->varName."_Min"){
            $this->fileName="/mnt/soc-nas/datafiles/ampConfig";
         }
      }
   }
   
   public function readLimitFile(){   
      if(($fh=fopen($this->fileName,'r'))!==FALSE){
         $labels=array();
         $labels=fgetcsv($fh, 1000, ",");
         for($label_i=0; $label_i<count($labels); $label_i++){
            if($labels[$label_i]==$this->varName."_Min"){
               $this->varName_i=$label_i;
            }
         }
         while(($line=fgetcsv($fh, 1000, ","))!==FALSE){
            if($line[0]!=$this->varName){
               $this->lowerLimit=$line[$this->varName_i];
               $this->upperLimit=$line[$this->varName_i + 1];
               break;
            }
         }
         fclose($fh);
      }
      else{
         echo "Could not open configuration file ".$this->fileName." for ".$this->varName.".<br />\n";
      }
   }
   
   public function printLimits(){
      echo $this->lowerLimit.",".$this->upperLimit;
   }
}

$limits= new limitObj;
$limits->readLimitFile();
$limits->printLimits();

?>
