<?php
set_include_path( '/home/misfitx/neo/BoxINC/' );
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
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Neo Ctopher | Mercury Retrogrades!</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="css/bootstrap.css" rel="stylesheet" type="text/css">
        <link href="css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
        <script src="js/jquery-3.5.1.min.js"></script>
        <script src="js/bootstrap.min.js"></script> 
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Mercury Retrograge Page!">
	<meta name="keywords" content="Mercury Retrograde, Mercury Retrogrades, Mercury Retrogrades for my time zone, Current Mercury Retrograde, Is Mercury Retrograde" >
	<meta name="author" content="Neo Ctopher" >





<script src="js/secondsXT.js"></script>


    
    </head>
<body onload="secondsXT()">


    
<!-- Nav bar Code Here -->  
<?php require('Neo-Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
 <div class="Logo"><p>&nbsp;</p></div>
   
</header>          

        
        
        
        
        
        
<main>        
        
        
        
        
                
                
<!-- Content Below -->
        
<div class="container">
			
			<h1 class="About_H1">Mercury Retrograde Page - Current!</h1>
						
			
		<div><img src="artwork/Mercury-002.jpg" style="max-width: 100%;" alt="Mercury Retrograde">
	
	<p class="copyright-text">Image by <a href="https://pixabay.com/illustrations/mercury-planet-space-universe-5556108/">Bruno Albino from Pixabay</a></p>
	</div>
		
		<div class="col-lg-8">
						
						
						
		<?php 

$connection = new mysqli($host, $username, $password, $db);
if ($connection->connect_error) die ($connection->connect_error);
			
			
$query		= "SELECT * FROM mercury ORDER BY recid";
$results	= $connection->query($query);

if (!$results) die ($connection->error);
 
$rows		= $results->num_rows;
$number		= 1;
$box		= 0;
print "<br>";
 
 for ($i = 0; $i < $rows;) {
 
 $results->data_seek($i);
 
 $row		= $results->fetch_array(MYSQLI_ASSOC);
$retro	= $row['retro'];
$direct	= $row['direct'];

$retro1		= date("Y/m/d H:i:s", $retro);
$direct1	= date("Y/m/d H:i:s", $direct);

$retrox		= new DateTime($retro1);
$directx	= new DateTime($direct1);

$retrox->setTimezone( new DateTimeZone($TimeZone1));
$directx->setTimezone( new DateTimeZone($TimeZone1));

// $RETROX		= $retrox->format('m/d/Y H:i:s');
// $DIRECTX	= $directx->format('m/d/Y H:i:s');
$RETROX		= $retrox->format('r');
$DIRECTX	= $directx->format('r');




$now		= time();



if ($direct > $now) { 

if ($box <= 0) { 
if ($retro > $now) {
	print "<p class=\"retro_good_H1\">Mercury is Direct</p>";
	$box	= 1;
}
if ($box <= 0) { 
if ($retro < $now && $now < $direct) {
	print "<p class=\"retro_bad_H1\">Mercury is Retrograde!</p>";
	$box	= 1;
}
}



}

print '<div class="About_Body">';
print '<div>' . $number . '</div><div>';
print "<p>Retrograde on: $RETROX</p>";
print "<p>Direct on $DIRECTX</p>";
print '</div>';
print '</div>';
}
	 
	
 ++$number;
 ++$i;
}
			
			
?>
		<div class="NAV_Font">All times are <?php echo $TimeZone1; ?> and approximate</div>
		<div class="About_Body">Change your TimeZone here: <a href="https://neo.ctopher.me/Overview.php">TimeZone Settings</a></div>
		<div class="About_Body">Calculations Provided by: <a href="https://github.com/skrushinsky/astro-montenbruck">Astro Montenbruck</a></div>
		
					
		</div>
						
						
		<div class="About_Body"><a href="https://www.ismercuryinretrograde.com" target="_blank">Backup Link to Mercury Retrogrades.</a></div>
		
						
						
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
