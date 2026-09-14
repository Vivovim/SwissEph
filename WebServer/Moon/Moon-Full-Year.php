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




// Calendar selection is separate from the current-year countdown above.
$calendarYear = filter_var($_GET['year'] ?? date('Y'), FILTER_VALIDATE_INT,
    ['options' => ['min_range' => 1000, 'max_range' => 9999]]);
if ($calendarYear === false) {
    $calendarYear = (int) date('Y');
}
$escapeMoonText = static function ($value) {
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
};
$monthsx = [1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April',
    5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August',
    9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'];

// swish.php supplies $host, $username, $password, and $db.
$moonEvents = [];
$moonError = false;
$moonConnection = null;
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
try {
    $moonConnection = new mysqli($host, $username, $password, $db);
    $moonConnection->set_charset('utf8mb4');
    $startDate = sprintf('%04d-01-01', $calendarYear);
    $endDate = sprintf('%04d-12-31', $calendarYear);
    $moonStatement = $moonConnection->prepare(
        'SELECT * FROM `yearphase_new` WHERE `date` >= ? AND `date` <= ? ORDER BY `date` ASC'
    );
    $moonStatement->bind_param('ss', $startDate, $endDate);
    $moonStatement->execute();
    $moonResults = $moonStatement->get_result();
    while ($row = $moonResults->fetch_assoc()) {
        for ($slot = 1; $slot <= 9; $slot++) {
            $label = $row['phase' . $slot];
            $stamp = $row['stamp' . $slot];
            if ($label === 'na' || $label === '' || $stamp === null) {
                continue;
            }
            if ($label !== 'Full Moon' && $label !== 'Blue Moon') {
                continue;
            }
            $moonEvents[] = ['phase' => $label, 'stamp' => (int) $stamp];
        }
    }
    $moonResults->free();
    $moonStatement->close();
} catch (mysqli_sql_exception $error) {
    error_log('Moon calendar database error: ' . $error->getMessage());
    $moonEvents = [];
    $moonError = true;
} finally {
    if ($moonConnection !== null) {
        $moonConnection->close();
    }
}

// Keep each label attached to its timestamp; format dates only after sorting.
usort($moonEvents, static function ($left, $right) {
    return $left['stamp'] <=> $right['stamp'];
});

?>
<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
        <title>Neo Ctopher | Full Moons for <?= $calendarYear ?></title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="css/bootstrap.css" rel="stylesheet" type="text/css" />
       

        <link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />

        
        <script src="js/jquery-3.5.1.min.js"></script>
        <script src="js/bootstrap.min.js"></script> 


        <link href="css/lightbox.css" rel="stylesheet" type="text/css">
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        
		
		


<script src="js/secondsXT.js"></script>


    
    </head>
<body onload="secondsXT()">


    
<!-- Nav bar Code Here -->  
<?php require('Neo-Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        

        
        
        
        
        
        
<main>        
        
        
        
        
                
                
<!-- Content Below -->
        
<div class="container">
	
	<div><p>&nbsp;</p><p>&nbsp;</p></div>
	
	<div class="float-left col-lg-12">
	
	
		<div class="About_Body">
		
			
					<div class="container">
			
			<h1 class="About_H1">Full Moons for <?= $calendarYear ?></h1>
		
		
						
						
						
						
		<?php if ($moonError): ?>
    <p>The moon calendar is temporarily unavailable. Please try again later.</p>
<?php elseif (!$moonEvents): ?>
    <p>No full moons are available for <?= $calendarYear ?>.</p>
<?php else: ?>
    <ol class="moon-events">
        <?php foreach ($moonEvents as $event): ?>
            <li class="mb-3">
                <div class="textblocks"><?= $escapeMoonText($event['phase']) ?></div>
                <div class="Working_H1B"><?= $escapeMoonText(date('r', $event['stamp'])) ?></div>
            </li>
        <?php endforeach; ?>
    </ol>
<?php endif; ?>

<div class="clearfix"></div>		
		</div>
		<div class="NAV_Font">Times shown in <?= $escapeMoonText(date_default_timezone_get()) ?> and are approximate.</div>
            <div class="About_H1">Moon Events by Month — <?= $calendarYear ?></div>
            <?php foreach ($monthsx as $monthNumber => $monthName): ?>
                <div class="col-md-2 float-left"><a href="Moon-Year.php?year=<?= $calendarYear ?>&amp;month=<?= $monthNumber ?>"><?= $monthName ?></a></div>
            <?php endforeach; ?>
            <div class="clearfix"></div>
            <p><a href="Moon-Full-Year.php?year=<?= $calendarYear ?>">All Full Moons for <?= $calendarYear ?></a></p>
            <form method="get">
                <label for="moon-calendar-year">Calendar year</label>
                <input id="moon-calendar-year" type="number" name="year" min="1000" max="9999" value="<?= $calendarYear ?>" required>

                <button type="submit">Show calendar</button>
            </form>	
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
