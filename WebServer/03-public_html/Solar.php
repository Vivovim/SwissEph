<?php
set_include_path( '/path/to/support/files/' );
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
        <title>Astro.Ctopher.Me | Solar Events!</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="css/bootstrap.css" rel="stylesheet" type="text/css">
        <link href="css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
        <script src="js/jquery-3.6.0.min.js"></script>
        <script src="js/bootstrap.min.js"></script> 
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Mercury Retrograge Page!">
	<meta name="keywords" content="Mercury Retrograde, Mercury Retrogrades, Mercury Retrogrades for my time zone, Current Mercury Retrograde, Is Mercury Retrograde" >
	<meta name="author" content="Neo Ctopher" >





    
    </head>
<body>


    
<!-- Nav bar Code Here -->  
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
 <div class="Logo"><p>&nbsp;</p></div>
   
</header>          

        
        
        
        
        
        
<main> 
                
                
<!-- Content Below -->
        
<div class="container">
			
			<h1 class="About_H1">Solar Calendar - Current!</h1>
						
			
		
		<div class="col-lg-8">
						
						
						
		<?php 

$connection = new mysqli($host, $username, $password, $db);
if ($connection->connect_error) die ($connection->connect_error);
			
			
$query		= "SELECT * FROM Solar_Event ORDER BY id";
$results	= $connection->query($query);

if (!$results) die ($connection->error);
 
$rows		= $results->num_rows;
$number		= 1;
$box		= 0;

 
 for ($i = 0; $i < $rows;) {
 
 $results->data_seek($i);
 
 $row		= $results->fetch_array(MYSQLI_ASSOC);
$event	= $row['event'];
$direct	= $row['unix_timestamp'];

$direct1		= date("Y/m/d H:i:s", $direct);


$directx	= new DateTime($direct1);


$directx->setTimezone( new DateTimeZone($TimeZone1));

// $RETROX		= $retrox->format('m/d/Y H:i:s');
// $DIRECTX	= $directx->format('m/d/Y H:i:s');

$DIRECTX	= $directx->format('r');




$now		= time();



//if ($now > $direct) {

//} else {

print '<div class="About_Body">';
print '<div>' . $number . '</div><div>';
print "<p>$event</p>";
print "<p>On $DIRECTX</p>";
print '</div>';
print '</div>';
// }
	 
	
 ++$number;
 ++$i;
}
			
			
?>
		<div class="NAV_Font">All times are <?php echo $TimeZone1; ?> and approximate</div>
		<div class="About_Body">Change your TimeZone here: <a href=" https://astro.ctopher.me/TimeZone.php">TimeZone Settings</a></div>
		
		<div class="About_Body">
    Astronomical calculations powered by
    <a href="https://www.astro.com/swisseph/" target="_blank" rel="noopener">
        Swiss Ephemeris
    </a>.
    <p></p>
    <p>Read our <a href="https://astro.ctopher.me/About.php">About Page</a> for more details. Source <a href="https://github.com/Vivovim/SwissEph">Code</a></p>
</div>			
		</div>
						
						
		
		
						
						
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
<?php require('Footer.php'); ?>
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
