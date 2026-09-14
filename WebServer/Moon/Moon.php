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

		$month = date("F");
?>
<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
        <title>Neo Ctopher | Current Moon Zodiac Phases for today!</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
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


    
        <style>
            .moon-events {
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 20px;
                margin: 28px 0;
                padding: 0;
                list-style: none;
            }

            .moon-events .moon-phase-card {
                box-sizing: border-box;
                display: flex;
                flex-direction: column;
                align-items: center;
                min-width: 0;
                margin: 0;
                padding: 24px 16px;
                border: 1px solid #334155;
                border-radius: 16px;
                background: linear-gradient(145deg, #182334, #0b1019);
                box-shadow: 0 6px 18px rgba(0, 0, 0, 0.16);
                color: #f1f5f9;
                text-align: center;
            }

            .moon-events .moon-phase-image {
                display: block;
                width: 153px; /* Approximately 30% of the 509px originals. */
                max-width: 100%;
                height: auto;
                margin: 0 0 18px;
            }

            .moon-events .moon-phase-name {
                margin: 0 0 10px;
                color: #f1f5f9;
                font-size: 1.1rem;
                font-weight: 600;
                line-height: 1.4;
            }

            .moon-events .moon-phase-date {
                display: block;
                margin-top: auto;
                color: #cbd5e1;
                font-size: 0.875rem;
                line-height: 1.6;
                overflow-wrap: anywhere;
            }

            @media (max-width: 767px) {
                .moon-events { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
            }

            @media (max-width: 399px) {
                .moon-events { grid-template-columns: 1fr; }
            }
        </style>

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
$data = $row2['phase'];
$TitleX = $row2['date'];



++$ix;
	 
}	 

$Zonex	= new DateTimeZone( "UTC" );
	$titlex2 = "@" . $TitleX;
	
	
	$titlex3= new DateTime($titlex2, $Zonex);
$titlex3->setTimeZone(new DateTimeZone($TimeZone1));
$titlex3 = $titlex3->format('r');
	







// The current Moon image, sign, and age below still come from moonsign.
	$phase = (int)$data;

	$MoonPhase = "";
	
	 
	 // code to make colls here.	
	 
	 
	 
	 // Do not edit Between this block.
	 
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
	
	// end do not edit this block.
	
	
	
	print '<div class="col-lg-12"><span class="NAV_Font">Moon Phase:</span><span class="DYKPlate_H1"> '. $MoonPhase. '</span><span class="NAV_Font">Sign:</span><span class="DYKPlate_H1"> ' . $sign . '</span><span class="DYKPlate_H1">' . $deg . '&deg;</span></div>';
	
	
	print '</div>';
	
	
	
	// print '<div>'. $phase . '</div>';
	

	 
	 print '<div class="clearfix"></div>';
print '<div class="col-lg-12 float-left"><span class="NAV_Font">Age In Days: </span><span class="About_H1">' . $data . '</span></div>';











	 print '<div class="clearfix"></div>';
print '<div class="col-lg-12"><span class="NAV_Font">Updated:</span><span class="Working_H1B"> ' . $titlex3 . '</span></div>';
	 print '<div class="clearfix"></div>';


// edit below this point. to make the cards for the moon phases.


print '<div class="clearfix"></div>';
// Current-month calendar from the monthly writer. Keep this independent of moonsign.
// This zone must match CALENDAR_TIMEZONE in update-phase.pl.
$moonCalendarZone = new DateTimeZone('America/Phoenix');
$moonCalendarNow = new DateTimeImmutable('now', $moonCalendarZone);
$moonMonthDate = $moonCalendarNow->format('Y-m-01');
$moonMonthTitle = $moonCalendarNow->format('F Y');
$moonDisplayZone = new DateTimeZone($TimeZone1);
$escapeMoonText = static function ($value) {
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
};
$moonPhaseImages = [
    'New Moon' => '01-New-Moon.png',
    'Waxing Crescent' => '02-waxing-cresent.png',
    'First Quarter' => '03-first-quarter.png',
    'Waxing Gibbous' => '04-waxing-gibbius.png',
    'Full Moon' => '05-full-moon.png',
    'Waning Gibbous' => '06-wanning-gibbius.png',
    'Last Quarter' => '07-last-quarter.png',
    'Waning Crescent' => '08-wanning-cresent.png',
    'Blue Moon' => '05-full-moon.png',
];
$moonEvents = [];
$moonError = false;
$moonConnection = null;
$moonStatement = null;
try {
    $moonConnection = new mysqli($host, $username, $password, $db);
    if ($moonConnection->connect_error) {
        throw new RuntimeException($moonConnection->connect_error);
    }
    if (!$moonConnection->set_charset('utf8mb4')) {
        throw new RuntimeException($moonConnection->error);
    }
    $moonStatement = $moonConnection->prepare(
        'SELECT `events_json` FROM `moonphase_new` WHERE `month` = ? AND `timezone` = ? LIMIT 1'
    );
    if (!$moonStatement) {
        throw new RuntimeException($moonConnection->error);
    }
    $moonCalendarTimezone = $moonCalendarZone->getName();
    if (!$moonStatement->bind_param('ss', $moonMonthDate, $moonCalendarTimezone)
        || !$moonStatement->execute()
        || !$moonStatement->bind_result($moonEventsJson)) {
        throw new RuntimeException($moonStatement->error);
    }
    $moonFetched = $moonStatement->fetch();
    if ($moonFetched === false) {
        throw new RuntimeException($moonStatement->error);
    }
    if ($moonFetched === true) {
        $moonDecoded = json_decode($moonEventsJson, true);
        if (json_last_error() !== JSON_ERROR_NONE || !is_array($moonDecoded)) {
            throw new UnexpectedValueException('Invalid monthly events JSON');
        }
        foreach ($moonDecoded as $moonEvent) {
            if (!is_array($moonEvent) || !isset($moonEvent['phase'])
                || !is_string($moonEvent['phase'])
                || !isset($moonPhaseImages[$moonEvent['phase']])
                || !isset($moonEvent['timestamp']) || !is_int($moonEvent['timestamp'])) {
                throw new UnexpectedValueException('Invalid monthly phase event');
            }
            $moonEvents[] = ['phase' => $moonEvent['phase'], 'stamp' => $moonEvent['timestamp']];
        }
    }
} catch (Exception $moonException) {
    error_log('Monthly moon calendar error: ' . $moonException->getMessage());
    $moonEvents = [];
    $moonError = true;
} finally {
    if ($moonStatement) {
        $moonStatement->close();
    }
    if ($moonConnection !== null && !$moonConnection->connect_error) {
        $moonConnection->close();
    }
}

usort($moonEvents, static function ($left, $right) {
    return $left['stamp'] <=> $right['stamp'];
});
?>
<section aria-labelledby="monthly-moon-heading">
    <h2 id="monthly-moon-heading" class="About_H1">Moon Events for <?= $escapeMoonText($moonMonthTitle) ?></h2>
    <?php if ($moonError): ?>
        <p>The moon calendar is temporarily unavailable. Please try again later.</p>
    <?php elseif (!$moonEvents): ?>
        <p>No moon events are available for <?= $escapeMoonText($moonMonthTitle) ?>.</p>
    <?php else: ?>
        <ol class="moon-events" role="list">
            <?php foreach ($moonEvents as $moonEvent): ?>
                <?php $moonEventDate = (new DateTimeImmutable('@' . $moonEvent['stamp']))->setTimezone($moonDisplayZone); ?>
                <li class="moon-phase-card">
                    <img class="moon-phase-image"
                         src="phases/<?= $escapeMoonText($moonPhaseImages[$moonEvent['phase']]) ?>"
                         alt="<?= $escapeMoonText($moonEvent['phase']) ?>"
                         width="153" height="153" loading="lazy" decoding="async">
                    <h3 class="moon-phase-name"><?= $escapeMoonText($moonEvent['phase']) ?></h3>
                    <time class="moon-phase-date" datetime="<?= $escapeMoonText($moonEventDate->format('c')) ?>"><?= $escapeMoonText($moonEventDate->format('r')) ?></time>
                </li>
            <?php endforeach; ?>
        </ol>
    <?php endif; ?>
</section>
<div class="clearfix">&nbsp;</div>
<?php

// print '<div class="clearfix"></div>';
// print '<div class="col-lg-12 float-left"><span class="NAV_Font">Sign: </span><span class="About_H1">' . $sign . '</span></div>';
			
			
?>
		
		</div>
		
		
		<div><p>&nbsp;</p><p>&nbsp;</p></div>
		<div class="textblocks"><a href="https://neo.ctopher.me/Moon-Full-Year.php">Yearly Calendar Of Full Moons</a></div>
		
		
		<div class="NAV_Font">All times <?php echo $TimeZone1; ?> and are approximate</div>
		<div class="About_Body">Set your timezone here: <a href="https://neo.ctopher.me/Overview.php">TimeZone Settings</a></div>
			
			
			<div class="About_Body">
    Astronomical calculations powered by
    <a href="https://www.astro.com/swisseph/" target="_blank" rel="noopener">
        Swiss Ephemeris
    </a>.
    
    <p>Read our <a href="https://neo.ctopher.me/About.php">About Page</a> for more details</p>
</div>

		
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
