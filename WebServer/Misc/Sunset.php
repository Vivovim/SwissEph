<?php
set_include_path( '__HIDDEN__' );
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


?>
<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
        <title>Neo Ctopher | New York, Prescott, Los Angeles Sunset Times!</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="css/bootstrap.css" rel="stylesheet" type="text/css" />

    
        
        <link href="css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
      
        
        <script src="js/jquery-3.5.1.min.js"></script>
        <script src="js/bootstrap.min.js"></script> 
       
        <link href="css/lightbox.css" rel="stylesheet" type="text/css">
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        
		
		<script src="js/jquery.form.min.js"></script>
		


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

        
        
        
        
        
        
        
        
        
        
        
                
                
<!-- Content Below -->
<main>

        
<div class="container">
			
			<h1 class="About_H1">Sun Set Page</h1>
			<div>New York, Prescott AZ, Los Angeles Current!</div>
						
			
		<?php
		
		$NOW	= time();
		$Sunset_Date = date("Y/m/d");

		
$Prescott = date_sun_info($NOW, 34.5400, -112.4685);
$NewYork = date_sun_info($NOW, 40.7128, -74.0060);
$LosAngeles = date_sun_info($NOW, 34.0549, -118.2426);


echo '<div class="About_H1">New York Sunset</div>';

echo '<p class="About_Body">' . date("H:i:s", $NewYork['sunset']) . " - Sun Set</p>";
echo '<p class="About_Body">' . date("H:i:s", $NewYork['astronomical_twilight_end']) . " - Astronomical Twilight End</p>";

echo '<div><p>&nbsp;</p></div>';






echo '<div class="About_H1">Prescott AZ Sunset</div>';
echo '<p class="About_Body">' . date("H:i:s", $Prescott['sunrise']) . " - Sunrise</p>";
echo '<p class="About_Body">' . date("H:i:s", $Prescott['sunset']) . " - Sun Set</p>";
echo '<p class="About_Body">' . date("H:i:s", $Prescott['astronomical_twilight_end']) . " - Astronomical Twilight End</p>";

echo '<div><p>&nbsp;</p></div>';

echo '<div class="About_H1">Los Angeles Sunset</div>';
echo '<p class="About_Body">' . date("H:i:s", $LosAngeles['sunset']) . " - Sun Set</p>";
echo '<p class="About_Body">' . date("H:i:s", $LosAngeles['astronomical_twilight_end']) . " - Astronomical Twilight End</p>";

echo '<div><p>&nbsp;</p></div>';




//foreach ($sun_info as $key => $val) {
//    echo '<p class="About_Body">' . $key . ': '  . date("H:i:s", $val) . "</p>";
//}
?>
	
	
		
		<div class="col-lg-8">
						
						
						
		
		<div class="NAV_Font">All times are <?php echo $TimeZone1; ?> and approximate</div>
		<div class="About_Body">Change your TimeZone here: <a href="https://neo.ctopher.me/Overview.php">TimeZone Settings</a></div>
		
					
		</div>
						
<div class="NAV_Font">Want to see weather for Prescott AZ? <a href="https://ctopher.me/weather.php" target="_blank">Click here</a></div>
		
						
						
	    <div class="clearfix"></div>
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
	
	
		

	
	
	
    
<!-- End Content -->
    
    <div class="clearfix"></div>
    
     

<!-- End Content -->

<div class="clearfix"></div>    
    <div class="clearfix"></div>
    
</main> 

<footer>   
    
<div class="container-fluid">    
  <div class="clearSolid">
	<p>&nbsp;</p></div>      
<!-- Footer IS Magic -->
<?php require('Neo-Magic-Footer.php'); ?>
</div>        
        
</footer>

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
