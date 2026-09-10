<?php
set_include_path( '__HIDDEN_' );
date_default_timezone_set( "America/Phoenix" );

ini_set( 'session.use_only_cookies', true );
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}




$setT   = date('U');



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
        <title>Neo Ctopher | June Solstice 2027</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="https://neo.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css" />
        
        
        
        <link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
                
        <script src="https://neo.ctopher.me/js/jquery-3.5.1.min.js"></script>
        <script src="https://neo.ctopher.me/js/bootstrap.min.js"></script>
        
        <script src="https://neo.ctopher.me/js/odometer.min.js"></script>
        
        <link href="https://neo.ctopher.me/css/odometer-theme-digital.css" rel="stylesheet" type="text/css" />
        
        
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
       
        
 

<script src="js/secondsXT.js"></script>




<style>
    
    .odometer {
  font-size: 42px;
  line-height: 100px;
}
        </style>
        
        
</head>
<body>


    
<!-- Nav bar Code Here -->  
<?php require('Neo-Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
<div class="Logo"><p>&nbsp;</p></div>
</header>        

<main>


<?php require "swish.php";?>

<?php 

$connection = new mysqli($host, $username, $password, $db);
if ($connection->connect_error) die ($connection->connect_error);
			
			
$query		= "SELECT * FROM summer ORDER BY recid DESC LIMIT 1";
$results	= $connection->query($query);

if (!$results) die ($connection->error);
 
$rows		= $results->num_rows;
 
print "<br/>";
 
 for ($i = 0; $i < $rows;) {
 
 $results->data_seek($i);
 
 $row		= $results->fetch_array(MYSQLI_ASSOC);
$years2 = $row['years'];
$months2 = $row['months'];
$weeks2 = $row['weeks'];
$days2 = $row['days'];
$hours2 = $row['hours'];
$minutes2 = $row['minutes'];
$seconds2 = $row['seconds'];
$date = $row['date'];
$piday = $row['piday'];
++$i;


}

$datex = date("r", $date);

date_default_timezone_set( "UTC" );
$dateXX = date("m.j.Y G:i:s", $piday);
?>


        
        
        
        
  
        
        
                
                
<!-- Content Below -->
<div class="container">
    
    
 
  
    
    
    
    
    
    
    
    
    
    
    
    
    <h1 class="About_H1">June Solstice 2027 - Updated Hourly</h1>
	<h1 class="About_H1"><?php echo $dateXX; ?></h1>

    <div class="col-lg-12">
     <div class="DYKPlate">Updated: <?php echo $datex; ?></div>
    
<div class="About_H1 float-left col-md-3">What:</div>
<div class="About_H1 float-left">How Long</div>

<div class="clearfix"></div>


<div class="About_H1 float-left col-md-3">Years: </div> 
<div class="BookTime odometer float-left"><?php echo $years2;?></div>
	
<div class="clearfix"></div>


<div class="About_H1 float-left col-md-3">Months: </div> 
<div class="BookTime odometer float-left"><?php echo $months2;?></div>
	
<div class="clearfix"></div>
		

<div class="About_H1 float-left col-md-3">Weeks: </div> 
<div class="BookTime odometer float-left"><?php echo $weeks2;?></div>
	
<div class="clearfix"></div>

<div class="About_H1 float-left col-md-3">Days: </div> 
<div class="BookTime odometer float-left"><?php echo $days2;?></div>
	
<div class="clearfix"></div>

<div class="About_H1 float-left col-md-3">Hours: </div> 
<div class="BookTime odometer float-left"><?php echo $hours2;?></div>
	
<div class="clearfix"></div>

<div class="About_H1 float-left col-md-3">Minutes: </div> 
<div class="BookTime odometer float-left"><?php echo $minutes2;?></div>
	
<div class="clearfix"></div>

<div class="About_H1 float-left col-md-3">Seconds: </div> 
<div class="BookTime odometer float-left"><?php echo $seconds2;?></div>
	
<div class="clearfix"></div>

		
	</div>
		
    <div class="flex-column">
    
    </div>
    </div>
    
    
    <div class="container">
    <p class="Books-buy-text">
    The summer solstice is the longest day of the year, marking the official start of summer. It occurs when the Earth's tilt toward the sun is at its maximum, resulting in the most daylight hours. This event typically falls around June 21 in the Northern Hemisphere and December 21 in the Southern Hemisphere. Many cultures celebrate the solstice with festivals, rituals, and gatherings to honor the sun's energy and the season's abundance. It's a time to embrace the warmth, growth, and vitality that summer brings.
    </p>
    </div>
    
  
      
    
  
<!-- End Content -->
    
    
 <div class="clearfix"></div>
    
     <div class="col-md-12">
    
   
    <p>&nbsp;</p>
    <p>&nbsp;</p>
    <p>&nbsp;</p>
    <p>&nbsp;</p>     
    </div>    

<!-- End Content -->

<div class="clearfix"></div>    
    
    
 </main>   
    
        
<!-- Footer IS Magic -->
<footer>
<?php require('Neo-Magic-Footer.php'); ?>
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
