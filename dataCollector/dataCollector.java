/*
dataCollector.java

Description:
   Downloads files from each server listed in ini file.
   Saves all files to a directory tree as ./DATAROOT/payloadX/DATE

v0.1
   -Downloads all data files.

*/


import java.util.*;
import java.net.*;
import java.io.*;
import java.nio.channels.*;

public class dataCollector{
   private static ArrayList<String> urls = new ArrayList();
   private static ArrayList<String> servers = new ArrayList();
   private static String outRoot = ".";
   private static String outDir = ".";
   private static String outFile = "default";
   
   //accessors
   public static void addServer(String url){
      servers.add(url);
   }
   public static void setOutputRoot(String path){
      outRoot = path;
   }
   public static String getPath(){
      return outDir;
   }
   
   //Opens a stream from specified url and saves it to a local file. 
   //Local file is named with the with the last section of the url after the 
   // last "/".
   //Specified url should not have a trailing "/" 
   private static void downloadFile(String url){
      try {
         System.out.println("Getting: " + url);
         
         URL dlFile = new URL(url);
         ReadableByteChannel rbc = Channels.newChannel(dlFile.openStream());
         
         FileOutputStream fos = new FileOutputStream(outDir + "/" + outFile);
         fos.getChannel().transferFrom(rbc, 0, 1 << 24);
      }catch (MalformedURLException ex){
         System.out.println(ex.getMessage()); 
      }catch(IOException ex){
         System.out.println(ex.getMessage());
      }
   }
   
   //If the output directory exists, get a listing and delete each file
   private static void testOutputDir(){
      File tempDir = new File(outDir);
      if(tempDir.exists()){
         String[] list = tempDir.list();
         for(String list_i : list){
            File tempFile = new File(outDir + "/" + list_i);
            tempFile.delete();
         }
      }else{
         tempDir.mkdirs();
      }
   }
   
   //Downloads the repository index, opens it and parses each file name.
   //File names and repo location are used to build url file list
   //Does this for each repository in the repo ArrayList
   public static void getFileList(){
      //make sure the output directory exists and is empty
      outDir = outRoot + "/" + level_generator.getPayload() + "/" + level_generator.getDate();
      testOutputDir();
      
      for(String server_i : servers){
         //repository entries are saved in the current directory 
         // and named "dailyManifest"
         outFile = "dailyManifest";
         downloadFile(server_i + "/cgi-bin/fileLister.pl?date=" + level_generator.getDate() + "&payload=payload" + level_generator.getPayload());
         
         //read the file manifest and add each file to the URL list
         try{
            FileReader fr = new FileReader(outDir + "/dailyManifest");
            BufferedReader manifest = new BufferedReader(fr);   
         
            String fileName;
            while( (fileName = manifest.readLine()) != null){
               urls.add(server_i + "/moc-nas/barrel/payload" + level_generator.getPayload() + "/" + level_generator.getDate() + "/dat/" + fileName);
            }
            manifest.close();
         }catch(IOException ex){
            System.out.println(ex.getMessage());
         }
      }
   }
   
   //Loop through the url list and download each file to 
   // the current date directory
   public static void getFiles(){
      for(String url_i : urls){
         //each data file is named based on the url
         String[] temp = url_i.split("/");
         outFile = temp[temp.length - 1];
         
         downloadFile(url_i);
      }
   }
}
