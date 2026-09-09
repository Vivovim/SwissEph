<?php
set_include_path( '/__HIDDEN__/' );
date_default_timezone_set( "America/Phoenix" );


ini_set( 'session.use_only_cookies', true );
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

require('swish.php');



require('timezone.php');


        $YEAR2 = date( 'Y' );

        $YEAR_Future2 = $YEAR2 + "1";


        // Edit this if needed....
        // $year22 = mktime(00, 00, 00, 1, 1, $YEAR_Future2, 0);

        $year22 = mktime( 00, 00, 00, 1, 1, $YEAR_Future2 );

        $DATE_NOW = date( 'U' );

        $Seconds_New_Year = $year22 - $DATE_NOW;

        $Seconds_New_YearX = $Seconds_New_Year - "1";


        $dow = date( 'l' );
        $date = date( 'F\ j, Y' );
        $doy = date( 'z' );
        $time = date( 'G:i:s' );

        // Offset Leap year;

        $doy = $doy + "1";


        $seconds = date( 's' );
        $minutes = date( 'i' );
        $hour = date( 'G' );

        $set_hours = "23" - $hour;
        $set_minute = "59" - $minutes;
        $set_seconds = "59" - $seconds;

        if ( $set_hours > 0 ) {

                $first = ( $set_hours * "60" ) * "60";
        } else {

                $first = "0";
        }

        $min = ( $set_minute * "60" );

        $total = $first + $min + $set_seconds;

		$month = date("F");
?>
<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
        <title>Neo Ctopher | Current Moon Zodiac Phases for today!</title>
        
        
    
        <link href="css/bootstrap.css" rel="stylesheet" type="text/css" />
              
<link href="css/misfit-ctopher-css.css" rel="stylesheet" type="text/css" />

        
        <script src="js/jquery-3.5.1.min.js"></script>
        <script src="js/bootstrap.min.js"></script> 
        <link href="css/lightbox.css" rel="stylesheet" type="text/css">
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="shortcut icon" href="https://neo.ctopher.me/favicon.ico"/>
		
		<script src="js/jquery.form.min.js"></script>


    
     <meta name="description" content="Moon Phase Today!">

	<meta name="keywords" content="Moon, Moon Phase, Moon Phase today, Moon Phase Current, Moon Age In Days" >
	<meta name="author" content="Neo Ctopher" >

		
 

<script src="js/secondsXT.js"></script>


    
    </head>
<body onload="secondsXT()">


    
<!-- Nav bar Code Here -->  
<?php require('Neo-Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
 <div class"Logo"><p>&nbsp;</p></div>
</header>          

        
        
        
        
        
<main>        
        
        
        
        
        
                
                
<!-- Content Below -->
        
<div class="container">
	
	
	
	<div class="float-left col-lg-12">
	
	
		<div class="About_Body">
		
			
					<div class="container">
			
			<h1 class="About_H1">Current Moon Phases For Today!</h1>
		
		
						
						
						
						
		<?php 
$connection2 = new mysqli($host, $username, $password, $db);
if ($connection2->connect_error) die ($connection2->connect_error);

$query2		= "SELECT * FROM moonsign ORDER BY recid DESC LIMIT 1";
$results2	= $connection2->query($query2);

if (!$results2) die ($connection2->error);
 
$rows2		= $results2->num_rows;
 
 
 for ($ix = 0; $ix < $rows2;) {
 
 $results2->data_seek($ix);
 
 $row2		= $results2->fetch_array(MYSQLI_ASSOC);
$sign = $row2['sign'];
$deg = $row2['deg'];
$lon	= $row2['lon'];

++$ix;
	 
}	 

$connection = new mysqli($host, $username, $password, $db);
if ($connection->connect_error) die ($connection->connect_error);
			
			
$query		= "SELECT * FROM moonphase ORDER BY recid DESC LIMIT 1";
$results	= $connection->query($query);

if (!$results) die ($connection->error);
 
$rows		= $results->num_rows;
 
print "<br/>";
 
 for ($i = 0; $i < $rows;) {
 
 $results->data_seek($i);
 
 $row		= $results->fetch_array(MYSQLI_ASSOC);
$title = $row['date'];
$data = $row['phase'];
$new	= $row['nmoon'];
$fq		= $row['fq'];
$fmoon	= $row['fmoon'];
$lq		= $row['lq'];
$xnmoon	= $row['xnmoon'];
	 
	 $phase = (int)$data;
	 //$phase = int($data);
	 // $phase = $data;
	 // $phase = number_format(floor($data), 0);
	 // $phase	= round($data, 0);
	
	
	$Zonex	= new DateTimeZone( "UTC" );
	
	
	$title3 = "@" . $title;
	
	
	$title2 = new DateTime($title3, $Zonex);
$title2->setTimeZone(new DateTimeZone($TimeZone1));
$title2 = $title2->format('r');
	
	
	
	
	$new3 = "@" . $new;
	
	$new2 = new DateTime($new3, $Zonex);
$new2->setTimeZone(new DateTimeZone($TimeZone1));
$new2 = $new2->format('r');



$fq3	=  "@" . $fq;


$fq2 = new DateTime($fq3, $Zonex);
$fq2->setTimeZone(new DateTimeZone($TimeZone1));
$fq2 = $fq2->format('r');


$fmoon3 =  "@" . $fmoon;

$fmoon2 = new DateTime($fmoon3, $Zonex);
$fmoon2->setTimeZone(new DateTimeZone($TimeZone1));
$fmoon2 = $fmoon2->format('r');


	
$lq3 =  "@" . $lq;	

$lq2 = new DateTime($lq3, $Zonex);
$lq2->setTimeZone(new DateTimeZone($TimeZone1));
$lq2 = $lq2->format('r');

	
$xmoon3	=  "@" . $xnmoon;
	
$xmoon2 = new DateTime($xmoon3, $Zonex);
$xmoon2->setTimeZone(new DateTimeZone($TimeZone1));
$xmoon2 = $xmoon2->format('r');

	$MoonPhase = "";
	
	 
	 // code to make colls here.	
	 
	 
	 
	print '<div>';
	
	if ($phase == 0 ) { print '<img src="moon/day-00.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 1 ) { print '<img src="moon/day-01.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 2 ) { print '<img src="moon/day-02.png" style="max-width: 25%;" alt="moon phase">';} 
	if ($phase == 3 ) { print '<img src="moon/day-03.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 4 ) { print '<img src="moon/day-04.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 5 ) { print '<img src="moon/day-04.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 6 ) { print '<img src="moon/day-06.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 7 ) { print '<img src="moon/day-07.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 8 ) { print '<img src="moon/day-08.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 9 ) { print '<img src="moon/day-09.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 10 ) { print '<img src="moon/day-10.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 11 ) { print '<img src="moon/day-11.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 12 ) { print '<img src="moon/day-12.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 13 ) { print '<img src="moon/day-13.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 14 ) { print '<img src="moon/day-14.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 15 ) { print '<img src="moon/day-15.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 16 ) { print '<img src="moon/day-16.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 17 ) { print '<img src="moon/day-17.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 18 ) { print '<img src="moon/day-18.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 19 ) { print '<img src="moon/day-19.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 20 ) { print '<img src="moon/day-20.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 21 ) { print '<img src="moon/day-21.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 22 ) { print '<img src="moon/day-22.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 23 ) { print '<img src="moon/day-23.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 24 ) { print '<img src="moon/day-24.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 25 ) { print '<img src="moon/day-25.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 26 ) { print '<img src="moon/day-26.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 27 ) { print '<img src="moon/day-27.png" style="max-width: 25%;" alt="moon phase">';}
	if ($phase == 28 ) { print '<img src="moon/day-28.png" style="max-width: 25%;" alt="moon phase">';} 
	if ($phase == 29 ) { print '<img src="moon/day-29.png" style="max-width: 25%;" alt="moon phase">';}
	
	print '</div>';
	
	print '<div>';
	
	if ($phase == 0 ) { $MoonPhase = "New Moon";}
	if ($phase == 1 ) { $MoonPhase = "Waxing Crescent";}
	if ($phase == 2 ) { $MoonPhase = "Waxing Crescent";} 
	if ($phase == 3 ) { $MoonPhase = "Waxing Crescent";}
	if ($phase == 4 ) { $MoonPhase = "Waxing Crescent";}
	if ($phase == 5 ) { $MoonPhase = "Waxing Crescent";}
	if ($phase == 6 ) { $MoonPhase = "Waxing Crescent";}
	
	
	if ($phase == 7 ) { $MoonPhase = "First Quarter";}
	if ($phase == 8 ) { $MoonPhase = "Waxing Gibbous";}
	if ($phase == 9 ) { $MoonPhase = "Waxing Gibbous";}
	if ($phase == 10 ) { $MoonPhase = "Waxing Gibbous";}
	if ($phase == 11 ) { $MoonPhase = "Waxing Gibbous";}
	if ($phase == 12 ) { $MoonPhase = "Waxing Gibbous";}
	if ($phase == 13 ) { $MoonPhase = "Waxing Gibbous";}
	
	
	if ($phase == 14 ) { $MoonPhase = "Full Moon";}
	
	
	if ($phase == 15 ) { $MoonPhase = "Full Moon";}
	if ($phase == 16 ) { $MoonPhase = "Waning Gibbous";}
	if ($phase == 17 ) { $MoonPhase = "Waning Gibbous";}
	if ($phase == 18 ) { $MoonPhase = "Waning Gibbous";}
	if ($phase == 19 ) { $MoonPhase = "Waning Gibbous";}
	if ($phase == 20 ) { $MoonPhase = "Waning Gibbous";}
	if ($phase == 21 ) { $MoonPhase = "Waning Gibbous";}
	
	
	
	if ($phase == 22 ) { $MoonPhase = "Last Quarter";}
	if ($phase == 23 ) { $MoonPhase = "Waning Crescent";}
	if ($phase == 24 ) { $MoonPhase = "Waning Crescent";}
	if ($phase == 25 ) { $MoonPhase = "Waning Crescent";}
	if ($phase == 26 ) { $MoonPhase = "Waning Crescent";}
	
	if ($phase == 27 ) { $MoonPhase = "Dark Moon";}
	if ($phase == 28 ) { $MoonPhase = "Dark Moon";} 
	if ($phase == 29 ) { $MoonPhase = "Dark Moon";}
	
	
	print '<div class="col-lg-12"><span class="NAV_Font">Moon Phase:</span><span class="DYKPlate_H1"> '. $MoonPhase. '</span><span class="NAV_Font">Sign:</span><span class="DYKPlate_H1"> ' . $sign . '</span><span class="DYKPlate_H1">' . $deg . '&deg;</span></div>';
	
	
	print '</div>';
	
	
	
	// print '<div>'. $phase . '</div>';
	

	 
	 print '<div class="clearfix"></div>';
print '<div class="col-lg-12 float-left"><span class="NAV_Font">Age In Days: </span><span class="About_H1">' . $data . '</span></div>';











	 print '<div class="clearfix"></div>';
print '<div class="col-lg-12"><span class="NAV_Font">Updated:</span><span class="Working_H1B"> '. $title2 . '</span></div>';
	 print '<div class="clearfix"></div>';

print '<div class="clearfix"></div>';
print '<div class="col-md-4 float-left">';
print '<div class="textblocks">New Moon</div>';
print '<div><img src="moon/small/day-00.png" style="max-width: 25%" alt="moon phase"></div>';
print '<div class="Working_H1B col-md-11">' . $new2 . '</div>';
print '</div>';

print '<div class="col-md-4 float-left">';
print '<div class="textblocks">First Quarter</div>';
print '<div><img src="moon/small/day-09.png" style="max-width: 25%" alt="moon phase"></div>';
print '<div class="Working_H1B col-md-11">' . $fq2 . '</div>';
print '</div>';

print '<div class="col-md-4 float-left">';
print '<div class="textblocks">Full Moon</div>';
print '<div><img src="moon/small/day-15.png" style="max-width: 25%" alt="moon phase"></div>';
print '<div class="Working_H1B col-md-11">' . $fmoon2 . '</div>';
print '</div>';

print '<div class="clearfix"></div>';
print '<div><p>&nbsp;</p><p>&nbsp;</p></div>';

print '<div class="col-md-4 float-left">';
print '<div class="textblocks">Last Quarter</div>';
print '<div><img src="moon/small/day-22.png" style="max-width: 25%" alt="moon phase"></div>';
print '<div class="Working_H1B col-md-11">' . $lq2 . '</div>';
print '</div>';

print '<div class="col-md-4 float-left">';
print '<div class="textblocks">Future New Moon</div>';
print '<div><img src="moon/small/day-00.png" style="max-width: 25%" alt="moon phase"></div>';
print '<div class="Working_H1B col-md-11">' . $xmoon2 . '</div>';
print '</div>';

print '<div class="clearfix">&nbsp;</div>';
	
 ++$i;
}

	
// print '<div class="clearfix"></div>';
// print '<div class="col-lg-12 float-left"><span class="NAV_Font">Sign: </span><span class="About_H1">' . $sign . '</span></div>';
			
			
?>
		
		</div>
		
		
		<div><p>&nbsp;</p><p>&nbsp;</p></div>
		<div class="textblocks"><a href="https://neo.ctopher.me/Moon-Full-Year.php">Yearly Calendar Of Full Moons</a></div>
		
		
		<div class="NAV_Font">All times <?php echo $TimeZone1; ?> and are approximate</div>
		<div class="About_Body">Set your timezone here: <a href="https://neo.ctopher.me/Overview.php">TimeZone Settings</a></div>
			
			
			<div class="About_Body">See <a href="/About.php">About page</a> to see how our calculations are done</div>
			

		<div class="About_Body">BETA TESTING <a href="https://neo.ctopher.me/Moon-TESTING.php">Check it</a></div>
		
		</div>
		
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>

	
	
	</div>
	

		

		
		
		
		<div class="clearSolid">
	<p>&nbsp;</p></div>
	
	
	
	
	
	
	</div>

	
	
	
    
<!-- End Content -->
    
    <div class="clearfix"></div>
    
    

<!-- End Content -->

<div class="clearfix"></div>    
    <div class="clearfix"></div>
    
</main>    
    
<div class="container-fluid">    
  <div class="clearSolid">
	<p>&nbsp;</p></div>      
<!-- Footer IS Magic -->
<?php require('Neo-Magic-Footer.php'); ?>
</div>        
        

    </body>
</html>


<?php
function sanity_Check_1($var)
  {
    $var = strip_tags($var);
    $var = htmlentities($var, $flags = ENT_QUOTES);
    return $var;
  }    
    


?>
