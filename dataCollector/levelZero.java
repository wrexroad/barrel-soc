/*
levelZero.java v0.3 12.07.xx

Description:
   Copies each data file, byte by byte, to a day-long data file.
   Rejects short frames, long frames, and frames with bad checksums.

v0.3
   -Added constructor so frame properties can be set in the ini file
   
v0.2
   -Added buffered and write for binary files.
   -Output file is now sorted correctly.
   -No longer copies the dailyManifest file into the output.
   
v0.1
   -Just copies the files into a day-long file. 
   -Does not check for valid frames.

Future Plans: 
   -Error checking for short, long, and back checksum frames.
   -Name the output file correctly.
*/

import java.util.*;
import java.io.*;

public class levelZero{
   
   public lelevZero(int length String word String path){
      //set frame properties
      private static String syncWord = word;
      private static int frameLength = length;
      
      //set output path and get directory listing
      private String dirPath = path;
      private File dir = new File(path);
      private String[] fileList = dir.list();
      Arrays.sort(fileList);
   }
   
   private String workingFrame;
   private int byteCount = 0;
   private String outName = "level.0";
   
   private BufferedReader readFile;
   private BufferedWriter writeFile;
   
   public void processFiles() throws IOException{
      System.out.println("Generating day-long file...");
      
      writeFile = new BufferedWriter(new FileWriter(dirPath + "/" + outName));
      
      for(String file_i : fileList){
         if(!(file_i.equals("dailyManifest"))){
            try{
               readFile = new BufferedReader(new FileReader(dirPath + "/" + file_i));
               
               int c;
               while ((c = readFile.read()) != -1) {
                  byteCount++;
                  writeFile.write(c);
               }
            }finally {
               if (readFile != null) {
                  readFile.close();
               }
            }
         }
      }
      
      System.out.println("Tranfered " + byteCount + " bytes to " + outName);
   }
   
   public void getFrame(){
      
   }
   
   //close the output file when done
   public void done() throws IOException{
      if (writeFile != null) {
         writeFile.close();
      }
      System.out.println(
         "Completed Level 0 for payload " + level_generator.getPayload()
      );
   }
}
