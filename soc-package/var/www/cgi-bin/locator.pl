#!/usr/bin/perl

print "Content-Type: text/html \n\n";

my ($inyear,$inmonth,$inday,$inhour,$inminute,$null,$time,$year,$month,$day,$hour,$minute,$searchname,$currentPayload,$filename,$line,$lat,$lon,$alt)="";
my (@null,@data)=();

my $webDir="/var/www";
my $socNas="/mnt/soc-nas";
my $mocNas="/mnt/moc-nas/barrel";
my $ampm="AM";

my @wordmonths = qw(null Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

#Start sorting out input
my $input = $ENV{'QUERY_STRING'};

#extract the input date and time
($inyear,$inmonth,$inday,$inhour) = split(/&/,$input);
($null,$inyear) = split(/=/,$inyear);
($null,$inmonth) = split(/=/,$inmonth);
($null,$inday) = split(/=/,$inday);
($null,$inhour) = split(/=/,$inhour);

if ($inyear<9 or $inyear>13 or $inmonth<1 or $inmonth>12 or $inday<1 or $inday>31 or $inhour<1 or $inhour>24) 
{
    #replace invalid input with current date and time
    ($null,$null,$inhour,$inday,$inmonth,$inyear,@null) = localtime(time);
    $inmonth +=1;
    $inyear += 1900;
    $inyear = $inyear%2000;
}

if ($input)
    {
        if ($inhour<10) {$inhour="0".$inhour;}
        if ($inday<10) {$inday="0".$inday;}    
    }
   
print << "STARTHEAD";
<html>
<head>
<title>Payload Locator</title>
<script src="http://www.google.com/jsapi?key=ABQIAAAAqFeoTX03y9FneunU80pk_RSAEP9J_KFd278oQJVFf7Y9HqEgExQcO6Fg_V5uEEelsP9ATMX43rfB8A"> </script>
<script type="text/javascript">
var ge;
google.load("earth", "1");
function init() {
google.earth.createInstance('map3d', initCB, failureCB);
}
function initCB(instance) {
ge = instance;
ge.getWindow().setVisibility(true);
// add a navigation control
ge.getNavigationControl().setVisibility(ge.VISIBILITY_AUTO);
// add some layers and info
ge.getLayerRoot().enableLayerById(ge.LAYER_TERRAIN, true);
ge.getOptions().setGridVisibility(true);
//move camera to Antarctica and zoom
var lookAt = ge.getView().copyAsLookAt(ge.ALTITUDE_RELATIVE_TO_GROUND);
lookAt.setLatitude(-89);
lookAt.setLongitude(1);
ge.getView().setAbstractView(lookAt);
lookAt.setRange(lookAt.getRange() * 0.25);
ge.getView().setAbstractView(lookAt);
if (!('counter' in window)) {
  window.counter = 1;
}
STARTHEAD

my @payloads = keys(%payloadLabels);
foreach (@payloads)
{
    ($currentPayload,$null)=split /=/,$_;
    
    $searchname=$socNas."/payload".$currentPayload."/.datasci".$inyear.$inmonth.$inday;

    open OUTFILE, "/mnt/soc-nas/datafiles/coords$currentPayload";

    LOOKFORDATA:
    {
        while($line=<OUTFILE>)#start scanning through the coord file to find until the first line containing the right date is found
        {
            chomp $line;
            ($filename,@null)=split /,/,$line;
            if ($filename eq $searchname)
            {
                push @data,$line;
                while($line=<OUTFILE>)#collect data until file ends or date changes
                {
                    ($filename,@null)=split /,/,$line;
                    unless($filename eq $searchname){last LOOKFORDATA;}
                    push @data,$line;
                }
            }
        }
    }
    
    ($filename,$line,$searchname)="";
    (@null)=();
    close OUTFILE;

    while(@data)
    {
        $line=shift @data;
        ($filename,$time,$lat,$lon,$alt)=split /,/,$line;
        ($hour,$minute)=split /:/,$time;

        if ($hour == $inhour)
        {
            push @{"lat$currentPayload"},$lat;
            push @{"lon$currentPayload"},$lon;
            push @{"alt$currentPayload"},$alt;
        }
    }
    $lat=join ",",@{"lat$currentPayload"};
    $lon=join ",",@{"lon$currentPayload"};
    $alt=join ",",@{"alt$currentPayload"};
    (@{"lat$currentPayload"},@{"lon$currentPayload"},@{"alt$currentPayload"})=();
    
    print << "PAYLOADPOINTS";
    // Define a custom icon.
    var icon = ge.createIcon('');
    icon.setHref('/images/payload-markers/$currentPayload.png');
    var style = ge.createStyle(''); //create a new style
    style.getIconStyle().setIcon(icon); //apply the icon to the style
    var lat$currentPayload = new Array($lat);
    var lon$currentPayload = new Array($lon);
    for(x in lat$currentPayload)
    {
        var placemark = ge.createPlacemark('');
        placemark.setStyleSelector(style); 
        var point = ge.createPoint('');
        point.setLatitude(lat$currentPayload\[x]);
        point.setLongitude(lon$currentPayload\[x]);
        placemark.setGeometry(point);
        ge.getFeatures().appendChild(placemark);
    }
PAYLOADPOINTS

}

print << "ENDHEAD";
// persist the placemark and counter for other interactive samples
window.counter++;
window.placemark = pointPlacemark;
      }
      function failureCB(errorCode) {
      }
      google.setOnLoadCallback(init);
      
   </script>
</head>
ENDHEAD

if ($inhour > 12)
{
    $ampm="PM";
    $inhour-=12;
}

print << "BODY"
<body>
    <center>
    <h1>Payload locations on $wordmonths[$inmonth] $inday 20$inyear at $inhour $ampm</h1>
    
   <div id="map3d" style="height: 70%; width: 70%;"></div>
    
    <form action="locator.pl" method=GET>
       
        <select name="year">
            <option value="">Select a year
            <option value="09">2009
            <option value="10">2010
            <option value="11">2011
            <option value="12">2012
            <option value="13">2013
        </select>
        
        <select name="Month">
            <option value="">Select a Month
            <option value="01">January
            <option value="02">February
            <option value="03">March
            <option value="04">April
            <option value="05">May
            <option value="06">June
            <option value="07">July
            <option value="08">August
            <option value="09">September
            <option value="10">October
            <option value="11">November
            <option value="12">December
        </select>
        
        <select name="Day">
            <option value="">Select a Day
            <script type="text/javascript">
                for (i = 1; i <= 31; i++)
                {
                    document.write("<option value=" + i + ">" + i);
                }
            </script>
        </select>
        
        <select name="Hour">
            <option value="">Select an Hour
            <script type="text/javascript">
                for (i = 1; i <= 24; i++)
                {
                    document.write("<option value=" + i + ">" + i);
                }
            </script>
        </select>
        <input type=submit value="GO!">
        </p>
        </center>
    </form>
</body>
</html>
BODY

__END__

=pod
CHANGES:
changed to local marker icon images
removed test for numerical payload ID
removed payload selection
=cut
