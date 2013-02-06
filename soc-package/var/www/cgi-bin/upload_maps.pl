#!/usr/bin/perl

use CGI;
use strict;

my $PROGNAME = "file_upload.pl";

my $cgi = new CGI();
print "Content-type: text/html\n\n";

if (! $cgi->param("button") ) {
	DisplayForm();
	exit;
}

my $file = $cgi->param('file');

my $basename = GetBasename($file);
my $outfile = "/mnt/soc-nas/data_products/map_data/";

#figure out if it is a kml file or an image file
if ($basename =~ /kml/){
   $outfile .= "kml/" . $basename;
}else{
   $outfile .= "img/" . $basename;
}


my $fh = $cgi->upload('file'); 
if(!$fh){
	print "Can't get file handle to uploaded file.";
	exit(-1);
}


if(!open OUT, ">".$outfile){
	print "Can't output file $outfile - $!";
	exit(-1);
}

print "Saving file...<br>\n";

my $nBytes = 0;
my $totBytes = 0;
my $buffer = "";

binmode($fh);

while ( $nBytes = read($fh, $buffer, 1024) ) {
	print OUT $buffer;
	$totBytes += $nBytes;
}

close(OUT);

print "Done!\n";

DisplayForm();

##############################################
# Subroutines
##############################################

#
# GetBasename - delivers filename portion of a fullpath.
#
sub GetBasename {
	my $fullname = shift;

	my(@parts);
	# check which way our slashes go.
	if ( $fullname =~ /(\\)/ ) {
		@parts = split(/\\/, $fullname);
	} else {
		@parts = split(/\//, $fullname);
	}

	return(pop(@parts));
}

#
# DisplayForm - spits out HTML to display our upload form.
#
sub DisplayForm {
print <<"HTML";
<!DOCTYPE html>
<html>
   <body>
      <form action="/cgi-bin/upload_maps.pl"
         enctype="multipart/form-data" method="post"
      >
         <input type="file" name="file" size="40">
         <input type="submit" name ="button" value="Send">
      </form>
   </body>
</html>

HTML
}