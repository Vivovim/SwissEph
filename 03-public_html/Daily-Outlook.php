<?php


date_default_timezone_set( "America/Phoenix" );


set_include_path( '/path/to/support/files/' );
include 'session.php';





require('timezone.php');

		
		$date1		= date("n/j/Y");

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
        <title>Astro.Ctopher.Me | Daily Outlook....</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="css/bootstrap.css" rel="stylesheet" type="text/css">
        
      
        <link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
               
        <script src="js/jquery-3.6.0.min.js"></script>
        <script src="js/bootstrap.min.js"></script> 
        
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
       
		
		
	
    

    
     <meta name="description" content="Daily Outlook, Modern Astrology Written by a Zen Monk">

	<meta name="keywords" content="Astrology, Daily Outlook, modern astrology, Zen Monk, Zen, horoscope" >
	<meta name="author" content="Neo Ctopher" >

		
		
		
		
		
	
    
    </head>
<body>


    
<!-- Nav bar Code Here -->  
<?php require('swish.php'); ?>
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
 <div class="Logo"><p>&nbsp;</p></div>
</header>          

        
        
        
        
<main>   
        
        
        
        
        
                
                
<!-- Content Below -->
        
<div class="container">
	
	
	
	<div class="col-lg-8 float-left">
	
	
		<div class="About_Body">
			
	
		
		<h1 class="About_H1">Daily Outlook!</h1>

			
<?php 


$dbX = "DailyOutlook";

$connection = new mysqli($host, $username, $password, $dbX);
if ($connection->connect_error) die ($connection->connect_error);


$query = "SELECT * FROM Master WHERE date = ? LIMIT 1";

$stmt = $connection->prepare($query);

if (!$stmt) {
    die($connection->error);
}

$stmt->bind_param("s", $date1);

if (!$stmt->execute()) {
    die($stmt->error);
}

$results = $stmt->get_result();

if (!$results) {
    die($stmt->error);
}

$rows = $results->num_rows;			
			
// $query		= "SELECT * FROM outlook WHERE date = '$date1' LIMIT 1";
// $results	= $connection->query($query);
// 
// if (!$results) die ($connection->error);
//  
// $rows		= $results->num_rows;
 
print "<br>";
 
 for ($i = 0; $i < $rows; ++$i) {
 
 $results->data_seek($i);
 
 $row		= $results->fetch_array(MYSQLI_ASSOC);

$date2 = stripslashes($row['date']); 
$data = stripslashes($row['horoscope']);
 

 print "<p class=\"Working_H1B\">" . $date2 . "</p>\n";
 print "<p class=\"Working_H1B\">" . $data . "</p>\n";
}

			
			
?>
            

		
		</div>
			
   
    <div>
    <p>&nbsp;</p>
		<p class="About_Body">Get the MacOS&reg; App <a href="https://www.zenpi.app">Zen Pi</a>.</p>
		
		</div>
    
    </div>
		
		
	</div>
	
	
	
    
<!-- End Content -->
    
    
    <div class="clearfix"></div>
    
   
    
    <div><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p></div>
    
    
 </main>   	
		

    
    
<div class="container-fluid">    
        
<!-- Footer IS Magic -->
<?php require('Footer.php'); ?>
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
