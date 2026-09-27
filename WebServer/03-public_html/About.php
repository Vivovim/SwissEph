<?php
set_include_path( '/path/to/support/files/' );
date_default_timezone_set( "America/Phoenix" );

ini_set( 'session.use_only_cookies', true );
if ( session_status() == PHP_SESSION_NONE ) {
  session_start();
}


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
<meta charset="utf-8">
<title>About Astro.Ctopher.Me Site</title>
<link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
<link href="css/bootstrap.css" rel="stylesheet" type="text/css">
<link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
<script src="js/jquery-3.5.1.min.js"></script> 
<script src="js/bootstrap.min.js"></script> 

<meta name="viewport" content="width=device-width, initial-scale=1.0">



    
     <meta name="description" content="About This Site: Neo Ctopher!">

	<meta name="keywords" content="About Neo Ctopher, Personal Website, About what went into making this site. Credits." >
	<meta name="author" content="Neo Ctopher" >



</head>
<body>

<!-- Nav bar Code Here -->
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 

<!-- Logo Header -->
<header>
  <div class="Logo">
    <p>&nbsp;</p>
  </div>
</header>

<main>


<!-- Content Below -->
<div class="container"> 
	
	<div class="col-lg-8 About_H1"><h1>About Astro.Ctopher.Me</h1></div>
	
	<div class="About_Body">Visit my Personal Home page <a href="https://neo.ctopher.me">Neo Ctopher</a></div>
	<div class="About_Body">I'm putting my Astro work here now. Apart from my personal home page.</div>
	<div class="About_Body">Daily Outlook provided as is: Written by Neo Ctopher</div>
	
	
	
	<p>&nbsp;</p><p>&nbsp;</p>
	
	<div class="About_Body">
	
	This website uses Swiss Ephemeris for astronomical calculations. Swiss Ephemeris is used under the GNU Affero General Public License, version 3 (AGPLv3). This website and its associated software are independent works and are not affiliated with or endorsed by the Swiss Ephemeris authors or Astrodienst.

<p>
Source Code Here: <a href="https://github.com/Vivovim/SwissEph" target="_blank">published on GitHub for your review</a>
</p>



	</div>
	
	
	
	
	
	
	<div class="About_Body">A few of the photos of planets on loan, borrowed from the web. <a href="/Planets/credits-planets.php">Credits Known</a></div>
	
	<div><p>&nbsp;</p></div>
	
	<div class="clearfix"><p>&nbsp;</p></div>
	
	
	<div class="center">
	<button class="glass" id="PayMe">Donate Via PayPal</button>
	</div>
	
	
	
	<div><p>&nbsp;</p><p>&nbsp;</p></div>
	
	<div class="About_Body"><p>Thanks for visiting my site.</p></div>
	
	
	<div class="DYKPlate_H1">Have a great day!</div>
	
	<script src="https://astro.ctopher.me/js/payment.js"></script>
	
	</div>

<!-- End Content -->




<div class="clearfix"></div>

<!-- End Content -->

<div class="clearfix"></div>


</main>


<!-- Footer IS Magic -->
<footer>
<?php require('Footer.php'); ?>
</footer>
</body>
</html>
<?php

function sanity_Check_1( $var ) {
  $var = strip_tags( $var );
  $var = htmlentities( $var, $flags = ENT_QUOTES );
  return $var;
}


?>
