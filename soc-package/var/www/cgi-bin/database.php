<?php

$username = trim($_GET{'u'});
$password = trim($_GET{'p'});
$hostname = "localhost";

$dbh = mysql_connect($hostname, $username, $password) 
   or die("Unable to connect to MySQL.<br />");

function update($dbh){
   $id=trim($_GET{'id'});
   $date=trim($_GET{'date'});
   $device=trim($_GET{'device'});
   $sn=trim($_GET{'sn'});
   $user=trim($_GET{'user'});
   $resolved=trim($_GET{'resolved'});
   $cond=trim($_GET{'cond'});
   $prob=trim($_GET{'prob'});
   $fix=trim($_GET{'fix'});
   
   $selected = mysql_select_db("trouble",$dbh) 
      or die("Could not select database.<br />");
   
   $query = "UPDATE devices SET date='".$date."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update date for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET device_type='".$device."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update device type for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET sn='".$sn."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update SN for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET user_name='".$user."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update user for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET resolved='".$resolved."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update resolution status for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET conditions='".$cond."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update condition for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET problem='".$prob."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update device problems for record ".$id.". Check username and password.</p>");
   
   $query = "UPDATE devices SET resolution='".$fix."' WHERE id='".$id."'";
   $queryResult = mysql_query($query)
      or die("<p>Could not update resolution for record ".$id.". Check username and password.</p>");
   
   print "<p>Record ".$id." updated.</p>";
}

function delete($dbh){
   $id=trim($_GET{'id'});
   
   $query = "DELETE FROM devices WHERE id='".$id."'";
   
   $selected = mysql_select_db("trouble",$dbh) 
      or die("Could not select database.<br />");
   
   $queryResult = mysql_query($query)
      or die("<p>Could not delete record. Check username and password.</p>");
   
   print "<p>Record ".$id." deleted.</p>";
}

function search($dbh){
   
   $terms=trim($_GET{'value'});
   $field=trim($_GET{'key'});
   
   if($field=="all"){#display all records
      $query="SELECT * FROM devices ORDER BY id DESC";
   }
   else{
      $query = "SELECT * FROM devices WHERE ".$field." LIKE \"%$terms%\" ORDER BY ".$field;
   }

   $selected = mysql_select_db("trouble",$dbh) 
      or die("Could not select database.<br />");
   
   $queryResult = mysql_query($query)
      or die("Could not get result.<br />");
   
   print '<b>Search Results:</b>'.
   '<table border=1>'.
      '  <tr>'.
      '     <td><b>Record ID</b></td>'.
      '     <td><b>Submission Date</b></td>'.
      '     <td><b>Device Type</b></td>'.
      '     <td><b>SN</b></td>'.
      '     <td><b>Submitted By</b></td>'.
      '     <td><b>Resolved?</b></td>'.
      '     <td>&nbsp</td>'.
      '     <td>&nbsp</td>'.
      '  </tr>';
   
   while ($row = mysql_fetch_array($queryResult,MYSQL_ASSOC)) {
      print '  <tr>'.
      '    <td id="id'.$row{'id'}.'" >'.$row{'id'}.'</td>'.
      '    <td id="date'.$row{'id'}.'" >'.$row{'date'}.'</td>'.
      '    <td id="device'.$row{'id'}.'" >'.$row{'device_type'}.'</td>'.
      '    <td id="sn'.$row{'id'}.'" >'.$row{'sn'}.'</td>'.
      '    <td id="user'.$row{'id'}.'" >'.$row{'user_name'}.'</td>'.
      '    <td id="resolved'.$row{'id'}.'" >'.$row{'resolved'}.'</td>'.
      '    <td id="cond'.$row{'id'}.'" style="display:none">'.$row{'conditions'}.'</td>'.
      '    <td id="prob'.$row{'id'}.'" style="display:none">'.$row{'problem'}.'</td>'.
      '    <td id="fix'.$row{'id'}.'" style="display:none">'.$row{'resolution'}.'</td>'.
      '    <td>'.
      '       <input type="button" value="View Record" onclick="showRecord(\''.$row{'id'}.'\');" />'.
      '    </td>'.
      '    <td>'.
      '       <input type="button" value="Delete Record*" onclick="deleteRecord(\''.$row{'id'}.'\');" />'.
      '    </td>'.
      '  </tr>';
   }
   
   print '<tr><td colspan=8>*Requres admin privileges</td></tr>';
   print '</table>';
}

function newRecord($dbh){
   $user_name=trim($_GET{'name'});
   $date=trim($_GET{'date'});
   $device_type=trim($_GET{'device_type'});
   $sn=trim($_GET{'sn'});
   $resolved=trim($_GET{'action'});
   $cond=trim($_GET{'cond'});
   $prob=trim($_GET{'prob'});
   $fix=trim($_GET{'fix'});
   
   #select MySQL table
   $selected = mysql_select_db("trouble",$dbh) 
      or die("Could not select database.<br />");
   
   #get last id number so we can incriment it
   $query="SELECT id FROM devices ORDER BY id DESC LIMIT 1";
   $queryResult = mysql_query($query)
      or die("Could not get result.<br />");
   $lastID = mysql_fetch_array($queryResult,MYSQL_ASSOC);
   $newID = $lastID{'id'}+1;

   #Add record to table
   $query="INSERT INTO devices VALUES('".$newID."','".$date."','".$device_type."','".$sn."','".$user_name."','".$cond."','".$prob."','".$resolved."','".$fix."');";
   $queryResult = mysql_query($query)
      or die("Could not get result.<br />");
   
   print "Added record for ".$device_type." ".$sn.".";
}

if ($_GET{'form'}=='Search Box'){search($dbh);}
elseif($_GET{'form'}=='New Submission'){newRecord($dbh);}
elseif($_GET{'form'}=='delete'){delete($dbh);}
elseif($_GET{'form'}=='update'){update($dbh);}
mysql_close($dbh);
?>
