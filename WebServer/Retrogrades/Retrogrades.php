<?php
set_include_path( '__HIDDEN__' );
date_default_timezone_set( "America/Phoenix" );

ini_set( 'session.use_only_cookies', true );
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}








   



?>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Neo Ctopher Me | Planet Retrogrades</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="https://neo.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css">
        <link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
        <script src="https://neo.ctopher.me/js/jquery-3.5.1.min.js"></script>
        <script src="https://neo.ctopher.me/js/bootstrap.min.js"></script>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
 

<script src="https://neo.ctopher.me/js/secondsXT.js"></script>


<style>
    
    .odometer {
  font-size: 42px;
  line-height: 100px;
}
        </style>
        
        
</head>
<body onload="secondsXT()">


    
<!-- Nav bar Code Here -->  
<?php require('Neo-Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
<div id="Logo">
    </div>
</header>        

<?php require "swish.php";?>

<?php 

$connection = new mysqli($host, $username, $password, $db);
if ($connection->connect_error) die ($connection->connect_error);
			
			
$query		= "SELECT * FROM CheckPlanets ORDER BY recid DESC LIMIT 1";
$results	= $connection->query($query);

if (!$results) die ($connection->error);
 
$rows		= $results->num_rows;
 
print "<br>";
 
 for ($i = 0; $i < $rows;) {
 
 $results->data_seek($i);
 
 $row		= $results->fetch_array(MYSQLI_ASSOC);
$date = $row['date'];
$mercury = $row['mercury'];
$venus = $row['venus'];
$mars = $row['mars'];
$jupiter = $row['jupiter'];
$saturn = $row['saturn'];
$uranus = $row['uranus'];
$neptune = $row['neptune'];
$pluto = $row['pluto'];


++$i;
}
$datex = date("r", $date);
?>

<?php


$sql = "
    SELECT Planet, Retrograde_Begin, Direct_Begin
    FROM Planets_Retrogrades
    WHERE Planet <> 'Mercury'
    ORDER BY Retrograde_Begin ASC, Direct_Begin ASC
";

$result = $connection->query($sql);
if ($result === false) {
    die($connection->error);
}

$planet = [];

while ($row = $result->fetch_assoc()) {
    // If a planet has multiple rows, retain its latest retrograde period.
    $planet[$row['Planet']] = [
        'Retrograde_Begin' => (int) $row['Retrograde_Begin'],
        'Direct_Begin'    => (int) $row['Direct_Begin'],
    ];
}

$result->free();
$connection->close();

$Venusx1 = $planet['Venus']['Retrograde_Begin'];
$Venusx2 = $planet['Venus']['Direct_Begin'];
$Venusx3 = date("r", $Venusx1);
$Venusx4 = date("r", $Venusx2);


$Marsx1 = $planet['Mars']['Retrograde_Begin'];
$Marsx2 = $planet['Mars']['Direct_Begin'];

$Marxx3 = date("r", $Marsx1);
$Marsx4 = date("r", $Marsx2);



$Jupiterx1 = $planet['Jupiter']['Retrograde_Begin'];
$Jupiterx2 = $planet['Jupiter']['Direct_Begin'];

$Jupiterx3 = date("r", $Jupiterx1);
$Jupiterx4 = date("r", $Jupiterx2);



$Saturnx1 = $planet['Saturn']['Retrograde_Begin'];
$Saturnx2 = $planet['Saturn']['Direct_Begin'];

$Saturnx3 = date("r", $Saturnx1);
$Saturnx4 = date("r", $Saturnx2);



$Uranusx1 = $planet['Uranus']['Retrograde_Begin'];
$Uranusx2 = $planet['Uranus']['Direct_Begin'];

$Uranusx3	= date("r", $Uranusx1);
$Uranusx4	= date("r", $Uranusx2);

$Neptunex1 = $planet['Neptune']['Retrograde_Begin'];
$Neptunex2 = $planet['Neptune']['Direct_Begin'];

$Neptunex3	= date("r", $Neptunex1);
$Neptunex4	= date("r", $Neptunex2);

$Plutox1 = $planet['Pluto']['Retrograde_Begin'];
$Plutox2 = $planet['Pluto']['Direct_Begin'];

$Plutox3 = date("r", $Plutox1);
$Plutox4 = date("r", $Plutox2);

?>
        
        
        
<?php

$RetrogradeREG	= "/Retrograde/";



?>
  
        
        
<main>                
                
<!-- Content Below -->
<div class="container">
    
    <h1 class="About_H1">Planet Retrogrades</h1>
    <div class="col-lg-12">
    
    <p class="Books-buy-text">
    In strictly scientific terms, a planet retrograde refers to the apparent reversal of the planet's motion across the sky, as observed from Earth. This phenomenon occurs because of the relative motion between Earth and the other planet in their orbits around the Sun. Retrograde motion is not an actual change in the planet’s direction of travel but rather an optical illusion that occurs due to differences in orbital speeds.
</p>


<h2 class="Books-buy-text">Why Retrograde Motion Happens:</h2>


<p class="Books-buy-text">
Orbital Differences: All planets in the solar system revolve around the Sun at different speeds due to their varying distances from the Sun. Inner planets (like Mercury and Venus) move faster, while outer planets (like Mars, Jupiter, and Saturn) move more slowly.
</p>
<p class="Books-buy-text">
Relative Position of Earth: When Earth, moving faster in its orbit, overtakes an outer planet (like Mars or Jupiter), the slower-moving planet appears to momentarily move backward in the sky relative to the background stars. Similarly, when Earth is overtaken by an inner planet, it can also appear to move in reverse from our perspective.
</p>
<p class="Books-buy-text">
Illusion of Backward Motion: As Earth passes the outer planet or is passed by an inner planet, the alignment causes the planet to first slow down, then appear to move backward (retrograde), and finally resume its forward (prograde) motion once the relative positions shift again.
</p>


<h2 class="Books-buy-text">Key Points:</h2>

<ul class="Books-buy-text">
<li>Retrograde motion is apparent, not actual.</li>
<li>It is caused by the relative motion between Earth and the planet in question.</li>
<li>The phenomenon is more noticeable for planets further from the Sun (e.g., Mars, Jupiter, Saturn), as they orbit more slowly compared to Earth.</li>
<li>This motion is studied extensively in astronomy and is well-understood in terms of planetary mechanics.</li>
</ul>


    
    <div><p>&nbsp;</p></div>
    
    
    
    
    
    
    <div class="DYKPlate">Updated: <?php echo $datex; ?></div>


<div class="col-md-2 float-left"><img src="artwork/mercury.jpg" width="100" height="100" alt="Mercury"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $mercury)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"> <?php echo $mercury;?></div>
<div class="clearfix"></div>
<div>
 <p class="DYKPlate">
    <a href="https://neo.ctopher.me/Mercury.php">Mercury Page</a>
    </p>
</div>
<p>&nbsp;</p>
<p>&nbsp;</p>	
<div class="clearfix"></div>
		
<div class="col-md-2 float-left"><img src="artwork/venus.jpg" width="100" height="100" alt="Venus"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $venus)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $venus;?></div>
<div>
<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Venus</div>

<p>Retrograde Starts: <?php echo $Venusx3; ?></p>
<p>Retrograde Ends: <?php echo $Venusx4; ?></p>
</div>	
<p>&nbsp;</p>
<p>&nbsp;</p>	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/mars-02.png" width="100" height="100" alt="Mars"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $mars)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $mars;?></div>
<div>
<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Mars</div>
<p>Retrograde Starts: <?php echo $Marsx3; ?></p>
<p>Retrograde Ends: <?php echo $Marsx4; ?></p>
</div>


<p>&nbsp;</p>
<p>&nbsp;</p>
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/jupiter.jpg" width="100" height="100" alt="Jupiter"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $jupiter)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $jupiter;?></div>
<div>
<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Jupiter</div>

<p>Retrograde Starts: <?php echo $Jupiterx3; ?></p>
<p>Retrograde Ends: <?php echo $Jupiterx4; ?></p>
</div>	
	
<p>&nbsp;</p>
<p>&nbsp;</p>	

<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/saturn.png" width="100" height="100" alt="Saturn"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $saturn)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $saturn;?></div>
<div>

<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Saturn</div>

<p>Retrograde Starts: <?php echo $Saturnx3; ?></p>
<p>Retrograde Ends: <?php echo $Saturnx4; ?></p>

</div>

<p>&nbsp;</p>
<p>&nbsp;</p>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/uranus-02.jpg" width="100" height="100" alt="Uranus"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $uranus)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $uranus;?></div>
<div>
<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Uranus</div>
<p>Retrograde Starts: <?php echo $Uranusx3; ?></p>
<p>Retrograde Ends: <?php echo $Uranusx4; ?></p>
</div>


<p>&nbsp;</p>
<p>&nbsp;</p>	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/neptune.jpg" width="100" height="100" alt="Neptune"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $neptune)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $neptune;?></div>
<div>
<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Neptune</div>

<p>Retrograde Starts: <?php echo $Neptunex3; ?></p>
<p>Retrograde Ends: <?php echo $Neptunex4; ?></p>


</div>


<p>&nbsp;</p>
<p>&nbsp;</p>
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/pluto.jpg" width="100" height="100" alt="Pluto"></div>
<div class="float-left <?php if (preg_match($RetrogradeREG, $pluto)) { print "retro_bad_H1";} else { print "BookTime"; } ?>"><?php echo $pluto;?></div>	
<div>
<div class="clearfix"></div>
<hr>
<div class="DYKPlate">Pluto</div>

<p>Retrograde Starts: <?php echo $Plutox3; ?></p>
<p>Retrograde Ends: <?php echo $Plutox4; ?></p>
</div>

<div class="clearfix"></div> 
		
		<div class="About_Body">
    Astronomical calculations powered by
    <a href="https://www.astro.com/swisseph/" target="_blank" rel="noopener">
        Swiss Ephemeris
    </a>.
    
    <p>Read our <a href="https://neo.ctopher.me/About.php">About Page</a> for more details</p>
</div>
		
	</div>
		
		
    <div class="flex-column">
    
    </div>
    
    
    
    <div>
   
    </div>
    














   
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
