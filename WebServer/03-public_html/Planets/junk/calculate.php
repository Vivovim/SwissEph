<?php

set_include_path( '/home/misfitx/neo/BoxINC/' );
date_default_timezone_set( "America/Phoenix" );


if (session_status() == PHP_SESSION_NONE) {
    session_start();
}






$year = sanity_Check_1($_POST["year"]);
$month = sanity_Check_1($_POST["month"]);
$day	= sanity_Check_1($_POST["day"]);

$csrf_token = sanity_Check_1( $_POST[ 'csrf_token' ]);
		
		

if ($csrf_token !== $_SESSION['csrf_token']) {
    die("Bad Token");
}




$now	= date("M/d/Y H:i:s e ");



$dataC	= $year .  ":" .  $month .  ":" . $day;

if (empty($year)|| empty($month) || empty($day)) {

header('Location: https://neo.ctopher.me/Planets/calculate-planets.php'); 

}

if (ctype_digit($year)&& ctype_digit($month) && ctype_digit($day)) {

$command	= "/home/misfitx/neo/public_html/cgi-bin/calculate-planets.pl $dataC";

$commandX	= escapeshellcmd( $command );    
		$test = exec( $commandX );

} else {

header('Location: https://neo.ctopher.me/Planets/calculate-planets.php'); 

}


if (empty($test)) {

header('Location: https://neo.ctopher.me/Planets/calculate-planets.php'); 
}

		$values = array();

		$values = explode( ':', $test );

		
$moon = array_shift($values);
$mercury = array_shift($values);
$venus 	= array_shift($values);
$earth	= array_shift($values);
$mars	= array_shift($values);
$jupiter	= array_shift($values);
$saturn		= array_shift($values);
$uranus		= array_shift($values);
$neptune	= array_shift($values);
$pluto		= array_shift($values);

	
$moon1		= (int) $moon;
$mercury1	= (int) $mercury;
$venus1		= (int) $venus;
$earth1		= (int) $earth;
$mars1		= (int) $mars;
$jupiter1	= (int) $jupiter;
$saturn1	= (int) $saturn;
$uranus1	= (int) $uranus;
$neptune1	= (int) $neptune;
$pluto1		= (int) $pluto;

$moonX	= round($moon, 2);
$mercuryX = round($mercury, 2);
$venusX = round($venus, 2);
$earthX	= round($earth, 2);
$marsX	= round($mars, 2);
$jupiterX = round($jupiter, 2);
$saturnX = round($saturn, 2);
$uranusX = round($uranus, 2);
$neptuneX = round($neptune, 2);
$plutoX = round($pluto, 2);

set_include_path( '/home/misfitx/neo/BoxINC/' );
date_default_timezone_set( "America/Phoenix" );

ini_set( 'session.use_only_cookies', true );
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}







		?>


<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
       
        
        <link href="https://neo.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css" />
        
        
        
        <link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
                
        <script src="https://neo.ctopher.me/js/jquery-3.5.1.min.js"></script>
        <script src="https://neo.ctopher.me/js/bootstrap.min.js"></script>
        
        <script src="https://neo.ctopher.me/js/odometer.min.js"></script>
        
        <link href="https://neo.ctopher.me/css/odometer-theme-digital.css" rel="stylesheet" type="text/css" />
        
        
        
        


<script src="https://neo.ctopher.me/js/secondsXT.js"></script>

        
        
        
        </head>
        
        <body>
        
        <!-- Nav bar Code Here -->  
<?php require('Neo-Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
		
<div class="Logo"><p>&nbsp;</p><p>&nbsp;</p></div>


		<div>
            



<main>
     
        
                
                
<!-- Content Below -->
<div class="container">
    
    <h1 class="About_H1">Planet Revolutions</h1>
    <div class="textblocks_A">Calculated on <?php echo $now; ?></div>
    <div class="col-lg-12">

<div class="col-md-2 float-left"><img src="artwork/day-15.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Moon: </div> 
<div class="BookTime odometer float-left"><?php echo $moonX;?></div>
	
<div class="clearfix"></div>

<div class="col-md-2 float-left"><img src="artwork/mercury.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Mercury: </div> 
<div class="BookTime odometer float-left"><?php echo $mercuryX;?></div>
	
<div class="clearfix"></div>
		
<div class="col-md-2 float-left"><img src="artwork/venus.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Venus: </div> 
<div class="BookTime odometer float-left"><?php echo $venusX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/earth.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Earth: </div> 
<div class="BookTime odometer float-left"><?php echo $earthX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/mars-02.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Mars: </div> 
<div class="BookTime odometer float-left"><?php echo $marsX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/jupiter.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Jupiter: </div> 
<div class="BookTime odometer float-left"><?php echo $jupiterX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/saturn.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Saturn: </div> 
<div class="BookTime odometer float-left"><?php echo $saturnX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/uranus-02.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Uranus: </div> 
<div class="BookTime odometer float-left"><?php echo $uranusX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/neptune.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Neptune: </div> 
<div class="BookTime odometer float-left"><?php echo $neptuneX;?></div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/pluto.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Pluto: </div> 
<div class="BookTime odometer float-left"><?php echo $plutoX;?></div>
	
<div class="clearfix"></div> 
		
	</div>
            
			
        </div>
</div>

</main>
        
<!-- Footer IS Magic -->
<footer>
<?php require('Neo-Magic-xCookie.php'); ?>
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