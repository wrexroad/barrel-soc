/*
level_generator.java v0.3 12.07.xx

Description:
   Entry point for .jar file.
   Reads ini file.
   Creates all objects needed for operation. 

v0.3
   -Reads new ini file items
   -Uses the new constructor for level zero objects

v0.2
   -Changed name (previously dataProducts.java)
   -Updated header documentation
   -ini file now supports comments preceeded by a "#"
   -server and payloads listed in the ini file are now one item per line
   
v0.1
   -Downloads data from servers listed in ini file.
   -Produces level 0 data with no error checking.

Future Plans:
   -Determine Date automatically or read it from the command line
   -Impliment level 1 and 2 objects
*/

import java.util.*;
import java.io.*;

public class level_generator{
   
   //custom objects
   private static dataCollector dataPull = new dataCollector();
   private static levelZero L0;
   private static levelOne L1;
   private static levelTwo L2;
   
   //private members
   private static String currentDate;
   private static ArrayList<String> payloads = new ArrayList();
   private static String currentPayload;
   private static String outPath;
   private static String syncWord;
   private static String frameLength;
   
   public static void main(String[] args){
      
      //ensure there is an ini file set
      if(args.length == 0){
         System.out.println("Usage: java -jar level_generator.jar <ini file> <date>");
         System.exit(0);
      }
      
      setDate(args[1]);
      
      //check for and read the ini file
      File testDir = new File(args[0]);
      if(testDir.exists()){
         readIni(args[0]);
      }else{
         System.out.println("Now configuration file specified.");
         System.exit(0);
      }
      
      //for each payload, read the list of data files on each server, 
      //then download the files
      for(String payload_i : payloads){   
         
         //set working payload
         setPayload(payload_i);
         
         //read each repository and build a list of data file urls
         dataPull.getFileList();
         
         //download each file after the url list is made
         dataPull.getFiles();
         
         //Create level zero object and convert the data files to a level 0 file
         try{
            L0 = new levelZero();
            L0.setFilePath(dataPull.getPath());
            L0.processFiles();
            L0.done();
         }catch(IOException ex){
            System.out.println(ex.getMessage());
         }
      }
   }
   
   private static void readIni(String filePath){
      try{
         FileReader fr = new FileReader(filePath);
         BufferedReader iniFile = new BufferedReader(fr);
         
         String line;
         while( (line = iniFile.readLine()) != null){
            
            //split off any comments
            String[] setting = line.split("#");
            line = setting[0];
            
            //get the key and value pair. Make sure there is only one pair per line
            setting = line.split("=");
            if(setting.length == 2){
               //remove leading and trailing whitespace from key and value
               setting[0] = setting[0].trim();
               setting[1] = setting[1].trim();
               
               switch (setting[0]){
                  //Determine what payloads to read
                  case "outputRoot":
                     outPath = setting[1];
                     break;
                  
                  case "frameLength":
                     frameLength = setting[1];
                     break;
                  
                  case "syncWord":
                     syncWord = setting[1];
                     break;
                  
                  case "payload": 
                     payloads.add(setting[1]);
                     break;
                  
                  //Add data file servers to the list
                  case "server":
                     dataPull.addServer(setting[1]);
                     break;
                  default: break;
               }
            }
         }
         
         iniFile.close();
      }catch(IOException ex){
         System.out.println(ex.getMessage());
      }
   }
   
   public static void setPayload(String pay){
      currentPayload = pay;
   }
   public static void setDate(String date){
      currentDate = date;
   }
   public static String getPath(){
      return dataPull.getPath();
   }
   public static String getPayload(){
      return currentPayload;
   }
   public static String getDate(){
      return currentDate;
   }
   
   
}
