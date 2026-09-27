<?php
set_include_path( '/path/to/support/files/' );
date_default_timezone_set( "America/Phoenix" );

ini_set( 'session.use_only_cookies', true );
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

require( 'swish.php' );







require('timezone.php');


       















if ($_SERVER['REQUEST_METHOD'] == 'GET') {?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>Astro.Ctopher.Me | TimeZone</title>
<link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
<link href="css/bootstrap.css?var=1" rel="stylesheet" type="text/css"/>

<link href="css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
<link href="css/lightbox.css" rel="stylesheet" type="text/css">
<script type="text/javascript" src="js/jquery-3.5.1.min.js"></script> 
<script src="js/bootstrap.min.js"></script> 

       
<meta name="viewport" content="width=device-width, initial-scale=1.0">

	
	
	<style>
		.center {
			align-content: center;
			text-align: center;
		}
	
	
	</style>
    </head>
<body>

<!-- Nav bar Code Here -->
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 

<!-- Logo Header -->
<header>
 <div class"Logo"><p>&nbsp;</p></div>
</header>



<main>

<!-- Content Below -->
<div class="container"> 
<p>Set your timezone here.</p>	

<div class="col-lg-8">
<div class="Working_H1B">Time Zone</div>

<p>&nbsp;</p>
<div class="float-left col-sm-1">
<?php echo $_SESSION['TZ']; ?>
</div> 
<div class="float-left col-sm-2">&nbsp;</div>
<div class="float-left col-md-4"> &dash; Current City</div>


<div class="clearfix"><p>&nbsp;</p></div>



<form action="<?php echo $_SERVER['PHP_SELF']?>" method="POST" enctype="application/x-www-form-urlencoded">

<div class="NAV_Font">Update Your Time Zone Here!</div>
<p>&nbsp;</p>
<p>Time Zone:  <select name="zone">

												 <option value="America/Anchorage">America/Anchorage</option>
                                                <option value="America/Argentina/Buenos_Aires">America/Argentina/Buenos_Aires</option>
                                                <option value="America/Aruba">America/Aruba</option>
                                                <option value="America/Barbados">America/Barbados</option>
                                                <option value="America/Boise">America/Boise</option>
                                                <option value="America/Cambridge_Bay">America/Cambridge_Bay</option>
                                                <option value="America/Campo_Grande">America/Campo_Grande</option>
                                                <option value="America/Cancun">America/Cancun</option>
                                                <option value="America/Chicago">America/Chicago</option>
                                                <option value="America/Dawson_Creek">America/Dawson_Creek</option>
                                                <option value="America/Denver">America/Denver</option>
                                                <option value="America/Detroit">America/Detroit</option>
                                                <option value="America/Goose_Bay">America/Goose_Bay</option>
                                                <option value="America/Grand_Turk">America/Grand_Turk</option>
                                                <option value="America/Havana">America/Havana</option>
                                                <option value="America/Indiana/Indianapolis">America/Indiana/Indianapolis</option>
                                                <option value="America/Indiana/Knox">America/Indiana/Knox</option>
                                                <option value="America/Indiana/Marengo">America/Indiana/Marengo</option>
                                                <option value="America/Indiana/Petersburg">America/Indiana/Petersburg</option>
                                                <option value="America/Indiana/Tell_City">America/Indiana/Tell_City</option>
                                                <option value="America/Indiana/Vevay">America/Indiana/Vevay</option>
                                                <option value="America/Indiana/Vincennes">America/Indiana/Vincennes</option>
                                                <option value="America/Indiana/Winamac">America/Indiana/Winamac</option>
                                                <option value="America/Kentucky/Louisville">America/Kentucky/Louisville</option>
                                                <option value="America/Kentucky/Monticello">America/Kentucky/Monticello</option>
                                                <option value="America/La_Paz">America/La_Paz</option>
                                                <option value="America/Lima">America/Lima</option>
                                                <option value="America/Los_Angeles">America/Los_Angeles</option>
                                                <option value="America/Lower_Princes">America/Lower_Princes</option>
                                                <option value="America/Maceio">America/Maceio</option>
                                                <option value="America/Managua">America/Managua</option>
                                                <option value="America/Manaus">America/Manaus</option>
                                                <option value="America/Marigot">America/Marigot</option>
                                                <option value="America/Martinique">America/Martinique</option>
                                                <option value="America/Matamoros">America/Matamoros</option>
                                                <option value="America/Mazatlan">America/Mazatlan</option>
                                                <option value="America/Menominee">America/Menominee</option>
                                                <option value="America/Merida">America/Merida</option>
                                                <option value="America/Metlakatla">America/Metlakatla</option>
                                                <option value="America/Mexico_City">America/Mexico_City</option>
                                                <option value="America/Miquelon">America/Miquelon</option>
                                                <option value="America/Moncton">America/Moncton</option>
                                                <option value="America/Monterrey">America/Monterrey</option>
                                                <option value="America/Montevideo">America/Montevideo</option>
                                                <option value="America/Montreal">America/Montreal</option>
                                                <option value="America/Montserrat">America/Montserrat</option>
                                                <option value="America/Nassau">America/Nassau</option>
                                                <option value="America/New_York">America/New_York</option>
                                                <option value="America/North_Dakota/Beulah">America/North_Dakota/Beulah</option>
                                                <option value="America/North_Dakota/Center">America/North_Dakota/Center</option>
                                                <option value="America/North_Dakota/New_Salem">America/North_Dakota/New_Salem</option>
                                                <option value="America/Ojinaga">America/Ojinaga</option>
                                                <option value="America/Panama">America/Panama</option>
                                                <option value="America/Phoenix">America/Phoenix</option>
                                                <option value="America/Port-au-Prince">America/Port-au-Prince</option>
                                                <option value="America/Port_of_Spain">America/Port_of_Spain</option>
                                                <option value="America/Porto_Velho">America/Porto_Velho</option>
                                                <option value="America/Puerto_Rico">America/Puerto_Rico</option>
                                                <option value="America/Rainy_River">America/Rainy_River</option>
                                                <option value="America/Rankin_Inlet">America/Rankin_Inlet</option>
                                                <option value="America/Resolute">America/Resolute</option>
                                                <option value="America/Rio_Branco">America/Rio_Branco</option>
                                                <option value="America/Santa_Isabel">America/Santa_Isabel</option>
                                                <option value="America/Santarem">America/Santarem</option>
                                                <option value="America/Santiago">America/Santiago</option>
                                                <option value="America/Santo_Domingo">America/Santo_Domingo</option>
                                                <option value="America/Sao_Paulo">America/Sao_Paulo</option>
                                                <option value="America/Scoresbysund">America/Scoresbysund</option>
                                                <option value="America/Shiprock">America/Shiprock</option>
                                                <option value="America/Sitka">America/Sitka</option>
                                                <option value="America/St_Barthelemy">America/St_Barthelemy</option>
                                                <option value="America/St_Johns">America/St_Johns</option>
                                                <option value="America/St_Kitts">America/St_Kitts</option>
                                                <option value="America/St_Lucia">America/St_Lucia</option>
                                                <option value="America/St_Thomas">America/St_Thomas</option>
                                                <option value="America/St_Vincent">America/St_Vincent</option>
                                                <option value="America/Swift_Current">America/Swift_Current</option>
                                                <option value="America/Thule">America/Thule</option>
                                                <option value="America/Thunder_Bay">America/Thunder_Bay</option>
                                                <option value="America/Tijuana">America/Tijuana</option>
                                                <option value="America/Toronto">America/Toronto</option>
                                                <option value="America/Tortola">America/Tortola</option>
                                                <option value="America/Vancouver">America/Vancouver</option>
                                                <option value="America/Whitehorse">America/Whitehorse</option>
                                                <option value="America/Winnipeg">America/Winnipeg</option>
                                                <option value="America/Yakutat">America/Yakutat</option>
                                                <option value="America/Yellowknife">America/Yellowknife</option>
                                                <option value="Antarctica/Casey">Antarctica/Casey</option>
                                                <option value="Antarctica/Davis">Antarctica/Davis</option>
                                                <option value="Antarctica/DumontDUrville">Antarctica/DumontDUrville</option>
                                                <option value="Antarctica/Macquarie">Antarctica/Macquarie</option>
                                                <option value="Antarctica/Mawson">Antarctica/Mawson</option>
                                                <option value="Antarctica/McMurdo">Antarctica/McMurdo</option>
                                                <option value="Antarctica/Palmer">Antarctica/Palmer</option>
                                                <option value="Antarctica/Rothera">Antarctica/Rothera</option>
                                                <option value="Antarctica/South_Pole">Antarctica/South_Pole</option>
                                                <option value="Antarctica/Syowa">Antarctica/Syowa</option>
                                                <option value="Antarctica/Vostok">Antarctica/Vostok</option>
                                                <option value="Arctic/Longyearbyen">Arctic/Longyearbyen</option>
                                                <option value="Atlantic/St_Helena">Atlantic/St_Helena</option>
                                                <option value="Atlantic/Stanley">Atlantic/Stanley</option>
                                               <option value="Asia/Brunei">Asia/Brunei</option> 
 <option value="Asia/Chita">Asia/Chita</option> 
 <option value="Asia/Choibalsan">Asia/Choibalsan</option> 
 <option value="Asia/Colombo">Asia/Colombo</option> 
 <option value="Asia/Damascus">Asia/Damascus</option> 
 <option value="Asia/Dhaka">Asia/Dhaka</option> 
 <option value="Asia/Dili">Asia/Dili</option> 
 <option value="Asia/Dubai">Asia/Dubai</option> 
 <option value="Asia/Dushanbe">Asia/Dushanbe</option> 
 <option value="Asia/Famagusta">Asia/Famagusta</option> 
 <option value="Asia/Gaza">Asia/Gaza</option> 
 <option value="Asia/Hebron">Asia/Hebron</option> 
 <option value="Asia/Ho_Chi_Minh">Asia/Ho_Chi_Minh</option> 
 <option value="Asia/Hong_Kong">Asia/Hong_Kong</option> 
 <option value="Asia/Hovd">Asia/Hovd</option> 
 <option value="Asia/Irkutsk">Asia/Irkutsk</option> 
 <option value="Asia/Jakarta">Asia/Jakarta</option> 
 <option value="Asia/Jayapura">Asia/Jayapura</option> 
 <option value="Asia/Jerusalem">Asia/Jerusalem</option> 
 <option value="Asia/Kabul">Asia/Kabul</option> 
 <option value="Asia/Kamchatka">Asia/Kamchatka</option> 
 <option value="Asia/Karachi">Asia/Karachi</option> 
 <option value="Asia/Kathmandu">Asia/Kathmandu</option> 
 <option value="Asia/Khandyga">Asia/Khandyga</option> 
 <option value="Asia/Kolkata">Asia/Kolkata</option> 
 <option value="Asia/Krasnoyarsk">Asia/Krasnoyarsk</option> 
 <option value="Asia/Kuala_Lumpur">Asia/Kuala_Lumpur</option> 
 <option value="Asia/Kuching">Asia/Kuching</option> 
 <option value="Asia/Kuwait">Asia/Kuwait</option> 
 <option value="Asia/Macau">Asia/Macau</option> 
 <option value="Asia/Magadan">Asia/Magadan</option> 
 <option value="Asia/Makassar">Asia/Makassar</option> 
 <option value="Asia/Manila">Asia/Manila</option> 
 <option value="Asia/Muscat">Asia/Muscat</option> 
 <option value="Asia/Nicosia">Asia/Nicosia</option> 
 <option value="Asia/Novokuznetsk">Asia/Novokuznetsk</option> 
 <option value="Asia/Novosibirsk">Asia/Novosibirsk</option> 
 <option value="Asia/Omsk">Asia/Omsk</option> 
 <option value="Asia/Oral">Asia/Oral</option> 
 <option value="Asia/Phnom_Penh">Asia/Phnom_Penh</option> 
 <option value="Asia/Pontianak">Asia/Pontianak</option> 
 <option value="Asia/Pyongyang">Asia/Pyongyang</option> 
 <option value="Asia/Qatar">Asia/Qatar</option> 
 <option value="Asia/Qostanay">Asia/Qostanay</option> 
 <option value="Asia/Qyzylorda">Asia/Qyzylorda</option> 
 <option value="Asia/Riyadh">Asia/Riyadh</option> 
 <option value="Asia/Sakhalin">Asia/Sakhalin</option> 
 <option value="Asia/Samarkand">Asia/Samarkand</option> 
 <option value="Asia/Seoul">Asia/Seoul</option> 
 <option value="Asia/Shanghai">Asia/Shanghai</option> 
 <option value="Asia/Singapore">Asia/Singapore</option> 
 <option value="Asia/Srednekolymsk">Asia/Srednekolymsk</option> 
 <option value="Asia/Taipei">Asia/Taipei</option> 
 <option value="Asia/Tashkent">Asia/Tashkent</option> 
 <option value="Asia/Tbilisi">Asia/Tbilisi</option> 
 <option value="Asia/Tehran">Asia/Tehran</option> 
 <option value="Asia/Thimphu">Asia/Thimphu</option> 
 <option value="Asia/Tokyo">Asia/Tokyo</option> 
 <option value="Asia/Tomsk">Asia/Tomsk</option> 
 <option value="Asia/Ulaanbaatar">Asia/Ulaanbaatar</option> 
 <option value="Asia/Urumqi">Asia/Urumqi</option> 
 <option value="Asia/Ust-Nera">Asia/Ust-Nera</option> 
 <option value="Asia/Vientiane">Asia/Vientiane</option> 
 <option value="Asia/Vladivostok">Asia/Vladivostok</option> 
 <option value="Asia/Yakutsk">Asia/Yakutsk</option> 
 <option value="Asia/Yangon">Asia/Yangon</option> 
 <option value="Asia/Yekaterinburg">Asia/Yekaterinburg</option> 
                                               
                                               
                                                <option value="Australia/Adelaide">Australia/Adelaide</option>
                                                <option value="Australia/Brisbane">Australia/Brisbane</option>
                                                <option value="Australia/Broken_Hill">Australia/Broken_Hill</option>
                                                <option value="Australia/Currie">Australia/Currie</option>
                                                <option value="Australia/Darwin">Australia/Darwin</option>
                                                <option value="Australia/Eucla">Australia/Eucla</option>
                                                <option value="Australia/Hobart">Australia/Hobart</option>
                                                <option value="Australia/Lindeman">Australia/Lindeman</option>
                                                <option value="Australia/Lord_Howe">Australia/Lord_Howe</option>
                                                <option value="Australia/Melbourne">Australia/Melbourne</option>
                                                <option value="Australia/Perth">Australia/Perth</option>
                                                <option value="Australia/Sydney">Australia/Sydney</option>
                                                <option value="Europe/Amsterdam">Europe/Amsterdam</option>
                                                <option value="Europe/Andorra">Europe/Andorra</option>
                                                <option value="Europe/Athens">Europe/Athens</option>
                                                <option value="Europe/Belgrade">Europe/Belgrade</option>
                                                <option value="Europe/Berlin">Europe/Berlin</option>
                                                <option value="Europe/Bratislava">Europe/Bratislava</option>
                                                <option value="Europe/Brussels">Europe/Brussels</option>
                                                <option value="Europe/Bucharest">Europe/Bucharest</option>
                                                <option value="Europe/Budapest">Europe/Budapest</option>
                                                <option value="Europe/Busingen">Europe/Busingen</option>
                                                <option value="Europe/Chisinau">Europe/Chisinau</option>
                                                <option value="Europe/Copenhagen">Europe/Copenhagen</option>
                                                <option value="Europe/Dublin">Europe/Dublin</option>
                                                <option value="Europe/Gibraltar">Europe/Gibraltar</option>
                                                <option value="Europe/Guernsey">Europe/Guernsey</option>
                                                <option value="Europe/Helsinki">Europe/Helsinki</option>
                                                <option value="Europe/Isle_of_Man">Europe/Isle_of_Man</option>
                                                <option value="Europe/Istanbul">Europe/Istanbul</option>
                                                <option value="Europe/Jersey">Europe/Jersey</option>
                                                <option value="Europe/Kaliningrad">Europe/Kaliningrad</option>
                                                <option value="Europe/Kiev">Europe/Kiev</option>
                                                <option value="Europe/Lisbon">Europe/Lisbon</option>
                                                <option value="Europe/Ljubljana">Europe/Ljubljana</option>
                                                <option value="Europe/London">Europe/London</option>
                                                <option value="Europe/Luxembourg">Europe/Luxembourg</option>
                                                <option value="Europe/Madrid">Europe/Madrid</option>
                                                <option value="Europe/Malta">Europe/Malta</option>
                                                <option value="Europe/Mariehamn">Europe/Mariehamn</option>
                                                <option value="Europe/Minsk">Europe/Minsk</option>
                                                <option value="Europe/Monaco">Europe/Monaco</option>
                                                <option value="Europe/Moscow">Europe/Moscow</option>
                                                <option value="Europe/Oslo">Europe/Oslo</option>
                                                <option value="Europe/Paris">Europe/Paris</option>
                                                <option value="Europe/Podgorica">Europe/Podgorica</option>
                                                <option value="Europe/Prague">Europe/Prague</option>
                                                <option value="Europe/Riga">Europe/Riga</option>
                                                <option value="Europe/Rome">Europe/Rome</option>
                                                <option value="Europe/Samara">Europe/Samara</option>
                                                <option value="Europe/San_Marino">Europe/San_Marino</option>
                                                <option value="Europe/Sarajevo">Europe/Sarajevo</option>
                                                <option value="Europe/Simferopol">Europe/Simferopol</option>
                                                <option value="Europe/Skopje">Europe/Skopje</option>
                                                <option value="Europe/Sofia">Europe/Sofia</option>
                                                <option value="Europe/Stockholm">Europe/Stockholm</option>
                                                <option value="Europe/Tallinn">Europe/Tallinn</option>
                                                <option value="Europe/Tirane">Europe/Tirane</option>
                                                <option value="Europe/Uzhgorod">Europe/Uzhgorod</option>
                                                <option value="Europe/Vaduz">Europe/Vaduz</option>
                                                <option value="Europe/Vatican">Europe/Vatican</option>
                                                <option value="Europe/Vienna">Europe/Vienna</option>
                                                <option value="Europe/Vilnius">Europe/Vilnius</option>
                                                <option value="Europe/Volgograd">Europe/Volgograd</option>
                                                <option value="Europe/Warsaw">Europe/Warsaw</option>
                                                <option value="Europe/Zagreb">Europe/Zagreb</option>
                                                <option value="Europe/Zaporozhye">Europe/Zaporozhye</option>
                                                <option value="Europe/Zurich">Europe/Zurich</option>
                                                <option value="Indian/Antananarivo">Indian/Antananarivo</option>
                                                <option value="Indian/Chagos">Indian/Chagos</option>
                                                <option value="Indian/Christmas">Indian/Christmas</option>
                                                <option value="Indian/Cocos">Indian/Cocos</option>
                                                <option value="Indian/Comoro">Indian/Comoro</option>
                                                <option value="Indian/Kerguelen">Indian/Kerguelen</option>
                                                <option value="Indian/Mahe">Indian/Mahe</option>
                                                <option value="Indian/Maldives">Indian/Maldives</option>
                                                <option value="Indian/Mauritius">Indian/Mauritius</option>
                                                <option value="Indian/Mayotte">Indian/Mayotte</option>
                                                <option value="Indian/Reunion">Indian/Reunion</option>
                                                <option value="Pacific/Apia">Pacific/Apia</option>
                                                <option value="Pacific/Auckland">Pacific/Auckland</option>
                                                <option value="Pacific/Chatham">Pacific/Chatham</option>
                                                <option value="Pacific/Chuuk">Pacific/Chuuk</option>
                                                <option value="Pacific/Easter">Pacific/Easter</option>
                                                <option value="Pacific/Efate">Pacific/Efate</option>
                                                <option value="Pacific/Enderbury">Pacific/Enderbury</option>
                                                <option value="Pacific/Fakaofo">Pacific/Fakaofo</option>
                                                <option value="Pacific/Fiji">Pacific/Fiji</option>
                                                <option value="Pacific/Funafuti">Pacific/Funafuti</option>
                                                <option value="Pacific/Galapagos">Pacific/Galapagos</option>
                                                <option value="Pacific/Gambier">Pacific/Gambier</option>
                                                <option value="Pacific/Guadalcanal">Pacific/Guadalcanal</option>
                                                <option value="Pacific/Guam">Pacific/Guam</option>
                                                <option value="Pacific/Honolulu">Pacific/Honolulu</option>
                                                <option value="Pacific/Johnston">Pacific/Johnston</option>
                                                <option value="Pacific/Kiritimati">Pacific/Kiritimati</option>
                                                <option value="Pacific/Kosrae">Pacific/Kosrae</option>
                                                <option value="Pacific/Kwajalein">Pacific/Kwajalein</option>
                                                <option value="Pacific/Majuro">Pacific/Majuro</option>
                                                <option value="Pacific/Marquesas">Pacific/Marquesas</option>
                                                <option value="Pacific/Midway">Pacific/Midway</option>
                                                <option value="Pacific/Nauru">Pacific/Nauru</option>
                                                <option value="Pacific/Niue">Pacific/Niue</option>
                                                <option value="Pacific/Norfolk">Pacific/Norfolk</option>
                                                <option value="Pacific/Noumea">Pacific/Noumea</option>
                                                <option value="Pacific/Pago_Pago">Pacific/Pago_Pago</option>
                                                <option value="Pacific/Palau">Pacific/Palau</option>
                                                <option value="Pacific/Pitcairn">Pacific/Pitcairn</option>
                                                <option value="Pacific/Pohnpei">Pacific/Pohnpei</option>
                                                <option value="Pacific/Port_Moresby">Pacific/Port_Moresby</option>
                                                <option value="Pacific/Rarotonga">Pacific/Rarotonga</option>
                                                <option value="Pacific/Saipan">Pacific/Saipan</option>
                                                <option value="Pacific/Tahiti">Pacific/Tahiti</option>
                                                <option value="Pacific/Tarawa">Pacific/Tarawa</option>
                                                <option value="Pacific/Tongatapu">Pacific/Tongatapu</option>
                                                <option value="Pacific/Wake">Pacific/Wake</option>
                                                <option value="Pacific/Wallis">Pacific/Wallis</option>
                                                <option value="UTC">UTC</option>
                                        </select>
                                        <p>&nbsp;</p>
                                        <button type="submit" class="btn btn-primary" name="submit2" value="Set Time">Change Time Zone</button>
                                </form>




</div>


</div>






    
     <div class="clearfix"></div>
     <div class="clearfix">&nbsp;</div>
           <div><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p></div>
    
   

<!-- End Content -->

<div class="clearfix"></div>

<!-- End Content --> 

<!-- Footer IS Magic -->
<?php require('Footer.php'); ?>
</body>
</html>
<?php
}


else if ($_SERVER['REQUEST_METHOD'] == 'POST') { 

$zone2	= sanity_Check_1($_POST['zone']);

$_SESSION['TZ'] = $zone2;


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
        $Leap = date( 'L' );
        $time = date( 'G:i:s' );

        // Offset first day = 0;

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
<meta charset="utf-8"/>
<title>Astro.Ctopher.Me | Time Zone</title>
<link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
<link href="css/bootstrap.css?var=1" rel="stylesheet" type="text/css"/>

<link href="css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
<link href="css/lightbox.css" rel="stylesheet" type="text/css">
<script type="text/javascript" src="js/jquery-3.5.1.min.js"></script> 
<script src="js/bootstrap.min.js"></script> 

        
        
        
<meta name="viewport" content="width=device-width, initial-scale=1.0">

    
  


    
    </head>
<body>

<!-- Nav bar Code Here -->
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 

<!-- Logo Header -->
<header>
 <div class"Logo"><p>&nbsp;</p></div>
</header>

<!-- Content Below -->
<div class="container"> 
	


</div>


<div class="container">


<div><p>&nbsp;</p><p>&nbsp;</p></div>
<div class="col-lg-4">

</div>

<div class="col-lg-8">
<div class="Working_H1B">Time Zone</div>




<p>&nbsp;</p>
<div class="float-left col-sm-1">
<?php echo $_SESSION['TZ']; ?>
</div> 
<div class="float-left col-sm-2">&nbsp;</div>
<div class="float-left col-md-4"> &dash; Current City</div>


<div class="clearfix"><p>&nbsp;</p></div>


<div>Time Zone Here</div>




<form action="<?php echo $_SERVER['PHP_SELF']?>" method="POST" enctype="application/x-www-form-urlencoded">

<div class="NAV_Font">Update Your Time Zone Here!</div>
<p>&nbsp;</p>
<p>Time Zone:  <select name="zone">

												 <option value="America/Anchorage">America/Anchorage</option>
                                                <option value="America/Argentina/Buenos_Aires">America/Argentina/Buenos_Aires</option>
                                                <option value="America/Aruba">America/Aruba</option>
                                                <option value="America/Barbados">America/Barbados</option>
                                                <option value="America/Boise">America/Boise</option>
                                                <option value="America/Cambridge_Bay">America/Cambridge_Bay</option>
                                                <option value="America/Campo_Grande">America/Campo_Grande</option>
                                                <option value="America/Cancun">America/Cancun</option>
                                                <option value="America/Chicago">America/Chicago</option>
                                                <option value="America/Dawson_Creek">America/Dawson_Creek</option>
                                                <option value="America/Denver">America/Denver</option>
                                                <option value="America/Detroit">America/Detroit</option>
                                                <option value="America/Goose_Bay">America/Goose_Bay</option>
                                                <option value="America/Grand_Turk">America/Grand_Turk</option>
                                                <option value="America/Havana">America/Havana</option>
                                                <option value="America/Indiana/Indianapolis">America/Indiana/Indianapolis</option>
                                                <option value="America/Indiana/Knox">America/Indiana/Knox</option>
                                                <option value="America/Indiana/Marengo">America/Indiana/Marengo</option>
                                                <option value="America/Indiana/Petersburg">America/Indiana/Petersburg</option>
                                                <option value="America/Indiana/Tell_City">America/Indiana/Tell_City</option>
                                                <option value="America/Indiana/Vevay">America/Indiana/Vevay</option>
                                                <option value="America/Indiana/Vincennes">America/Indiana/Vincennes</option>
                                                <option value="America/Indiana/Winamac">America/Indiana/Winamac</option>
                                                <option value="America/Kentucky/Louisville">America/Kentucky/Louisville</option>
                                                <option value="America/Kentucky/Monticello">America/Kentucky/Monticello</option>
                                                <option value="America/La_Paz">America/La_Paz</option>
                                                <option value="America/Lima">America/Lima</option>
                                                <option value="America/Los_Angeles">America/Los_Angeles</option>
                                                <option value="America/Lower_Princes">America/Lower_Princes</option>
                                                <option value="America/Maceio">America/Maceio</option>
                                                <option value="America/Managua">America/Managua</option>
                                                <option value="America/Manaus">America/Manaus</option>
                                                <option value="America/Marigot">America/Marigot</option>
                                                <option value="America/Martinique">America/Martinique</option>
                                                <option value="America/Matamoros">America/Matamoros</option>
                                                <option value="America/Mazatlan">America/Mazatlan</option>
                                                <option value="America/Menominee">America/Menominee</option>
                                                <option value="America/Merida">America/Merida</option>
                                                <option value="America/Metlakatla">America/Metlakatla</option>
                                                <option value="America/Mexico_City">America/Mexico_City</option>
                                                <option value="America/Miquelon">America/Miquelon</option>
                                                <option value="America/Moncton">America/Moncton</option>
                                                <option value="America/Monterrey">America/Monterrey</option>
                                                <option value="America/Montevideo">America/Montevideo</option>
                                                <option value="America/Montreal">America/Montreal</option>
                                                <option value="America/Montserrat">America/Montserrat</option>
                                                <option value="America/Nassau">America/Nassau</option>
                                                <option value="America/New_York">America/New_York</option>
                                                <option value="America/North_Dakota/Beulah">America/North_Dakota/Beulah</option>
                                                <option value="America/North_Dakota/Center">America/North_Dakota/Center</option>
                                                <option value="America/North_Dakota/New_Salem">America/North_Dakota/New_Salem</option>
                                                <option value="America/Ojinaga">America/Ojinaga</option>
                                                <option value="America/Panama">America/Panama</option>
                                                <option value="America/Phoenix">America/Phoenix</option>
                                                <option value="America/Port-au-Prince">America/Port-au-Prince</option>
                                                <option value="America/Port_of_Spain">America/Port_of_Spain</option>
                                                <option value="America/Porto_Velho">America/Porto_Velho</option>
                                                <option value="America/Puerto_Rico">America/Puerto_Rico</option>
                                                <option value="America/Rainy_River">America/Rainy_River</option>
                                                <option value="America/Rankin_Inlet">America/Rankin_Inlet</option>
                                                <option value="America/Resolute">America/Resolute</option>
                                                <option value="America/Rio_Branco">America/Rio_Branco</option>
                                                <option value="America/Santa_Isabel">America/Santa_Isabel</option>
                                                <option value="America/Santarem">America/Santarem</option>
                                                <option value="America/Santiago">America/Santiago</option>
                                                <option value="America/Santo_Domingo">America/Santo_Domingo</option>
                                                <option value="America/Sao_Paulo">America/Sao_Paulo</option>
                                                <option value="America/Scoresbysund">America/Scoresbysund</option>
                                                <option value="America/Shiprock">America/Shiprock</option>
                                                <option value="America/Sitka">America/Sitka</option>
                                                <option value="America/St_Barthelemy">America/St_Barthelemy</option>
                                                <option value="America/St_Johns">America/St_Johns</option>
                                                <option value="America/St_Kitts">America/St_Kitts</option>
                                                <option value="America/St_Lucia">America/St_Lucia</option>
                                                <option value="America/St_Thomas">America/St_Thomas</option>
                                                <option value="America/St_Vincent">America/St_Vincent</option>
                                                <option value="America/Swift_Current">America/Swift_Current</option>
                                                <option value="America/Thule">America/Thule</option>
                                                <option value="America/Thunder_Bay">America/Thunder_Bay</option>
                                                <option value="America/Tijuana">America/Tijuana</option>
                                                <option value="America/Toronto">America/Toronto</option>
                                                <option value="America/Tortola">America/Tortola</option>
                                                <option value="America/Vancouver">America/Vancouver</option>
                                                <option value="America/Whitehorse">America/Whitehorse</option>
                                                <option value="America/Winnipeg">America/Winnipeg</option>
                                                <option value="America/Yakutat">America/Yakutat</option>
                                                <option value="America/Yellowknife">America/Yellowknife</option>
                                                <option value="Antarctica/Casey">Antarctica/Casey</option>
                                                <option value="Antarctica/Davis">Antarctica/Davis</option>
                                                <option value="Antarctica/DumontDUrville">Antarctica/DumontDUrville</option>
                                                <option value="Antarctica/Macquarie">Antarctica/Macquarie</option>
                                                <option value="Antarctica/Mawson">Antarctica/Mawson</option>
                                                <option value="Antarctica/McMurdo">Antarctica/McMurdo</option>
                                                <option value="Antarctica/Palmer">Antarctica/Palmer</option>
                                                <option value="Antarctica/Rothera">Antarctica/Rothera</option>
                                                <option value="Antarctica/South_Pole">Antarctica/South_Pole</option>
                                                <option value="Antarctica/Syowa">Antarctica/Syowa</option>
                                                <option value="Antarctica/Vostok">Antarctica/Vostok</option>
                                                <option value="Arctic/Longyearbyen">Arctic/Longyearbyen</option>
                                                <option value="Atlantic/St_Helena">Atlantic/St_Helena</option>
                                                <option value="Atlantic/Stanley">Atlantic/Stanley</option>
                                               <option value="Asia/Brunei">Asia/Brunei</option> 
 <option value="Asia/Chita">Asia/Chita</option> 
 <option value="Asia/Choibalsan">Asia/Choibalsan</option> 
 <option value="Asia/Colombo">Asia/Colombo</option> 
 <option value="Asia/Damascus">Asia/Damascus</option> 
 <option value="Asia/Dhaka">Asia/Dhaka</option> 
 <option value="Asia/Dili">Asia/Dili</option> 
 <option value="Asia/Dubai">Asia/Dubai</option> 
 <option value="Asia/Dushanbe">Asia/Dushanbe</option> 
 <option value="Asia/Famagusta">Asia/Famagusta</option> 
 <option value="Asia/Gaza">Asia/Gaza</option> 
 <option value="Asia/Hebron">Asia/Hebron</option> 
 <option value="Asia/Ho_Chi_Minh">Asia/Ho_Chi_Minh</option> 
 <option value="Asia/Hong_Kong">Asia/Hong_Kong</option> 
 <option value="Asia/Hovd">Asia/Hovd</option> 
 <option value="Asia/Irkutsk">Asia/Irkutsk</option> 
 <option value="Asia/Jakarta">Asia/Jakarta</option> 
 <option value="Asia/Jayapura">Asia/Jayapura</option> 
 <option value="Asia/Jerusalem">Asia/Jerusalem</option> 
 <option value="Asia/Kabul">Asia/Kabul</option> 
 <option value="Asia/Kamchatka">Asia/Kamchatka</option> 
 <option value="Asia/Karachi">Asia/Karachi</option> 
 <option value="Asia/Kathmandu">Asia/Kathmandu</option> 
 <option value="Asia/Khandyga">Asia/Khandyga</option> 
 <option value="Asia/Kolkata">Asia/Kolkata</option> 
 <option value="Asia/Krasnoyarsk">Asia/Krasnoyarsk</option> 
 <option value="Asia/Kuala_Lumpur">Asia/Kuala_Lumpur</option> 
 <option value="Asia/Kuching">Asia/Kuching</option> 
 <option value="Asia/Kuwait">Asia/Kuwait</option> 
 <option value="Asia/Macau">Asia/Macau</option> 
 <option value="Asia/Magadan">Asia/Magadan</option> 
 <option value="Asia/Makassar">Asia/Makassar</option> 
 <option value="Asia/Manila">Asia/Manila</option> 
 <option value="Asia/Muscat">Asia/Muscat</option> 
 <option value="Asia/Nicosia">Asia/Nicosia</option> 
 <option value="Asia/Novokuznetsk">Asia/Novokuznetsk</option> 
 <option value="Asia/Novosibirsk">Asia/Novosibirsk</option> 
 <option value="Asia/Omsk">Asia/Omsk</option> 
 <option value="Asia/Oral">Asia/Oral</option> 
 <option value="Asia/Phnom_Penh">Asia/Phnom_Penh</option> 
 <option value="Asia/Pontianak">Asia/Pontianak</option> 
 <option value="Asia/Pyongyang">Asia/Pyongyang</option> 
 <option value="Asia/Qatar">Asia/Qatar</option> 
 <option value="Asia/Qostanay">Asia/Qostanay</option> 
 <option value="Asia/Qyzylorda">Asia/Qyzylorda</option> 
 <option value="Asia/Riyadh">Asia/Riyadh</option> 
 <option value="Asia/Sakhalin">Asia/Sakhalin</option> 
 <option value="Asia/Samarkand">Asia/Samarkand</option> 
 <option value="Asia/Seoul">Asia/Seoul</option> 
 <option value="Asia/Shanghai">Asia/Shanghai</option> 
 <option value="Asia/Singapore">Asia/Singapore</option> 
 <option value="Asia/Srednekolymsk">Asia/Srednekolymsk</option> 
 <option value="Asia/Taipei">Asia/Taipei</option> 
 <option value="Asia/Tashkent">Asia/Tashkent</option> 
 <option value="Asia/Tbilisi">Asia/Tbilisi</option> 
 <option value="Asia/Tehran">Asia/Tehran</option> 
 <option value="Asia/Thimphu">Asia/Thimphu</option> 
 <option value="Asia/Tokyo">Asia/Tokyo</option> 
 <option value="Asia/Tomsk">Asia/Tomsk</option> 
 <option value="Asia/Ulaanbaatar">Asia/Ulaanbaatar</option> 
 <option value="Asia/Urumqi">Asia/Urumqi</option> 
 <option value="Asia/Ust-Nera">Asia/Ust-Nera</option> 
 <option value="Asia/Vientiane">Asia/Vientiane</option> 
 <option value="Asia/Vladivostok">Asia/Vladivostok</option> 
 <option value="Asia/Yakutsk">Asia/Yakutsk</option> 
 <option value="Asia/Yangon">Asia/Yangon</option> 
 <option value="Asia/Yekaterinburg">Asia/Yekaterinburg</option> 
                                               
                                               
                                                <option value="Australia/Adelaide">Australia/Adelaide</option>
                                                <option value="Australia/Brisbane">Australia/Brisbane</option>
                                                <option value="Australia/Broken_Hill">Australia/Broken_Hill</option>
                                                <option value="Australia/Currie">Australia/Currie</option>
                                                <option value="Australia/Darwin">Australia/Darwin</option>
                                                <option value="Australia/Eucla">Australia/Eucla</option>
                                                <option value="Australia/Hobart">Australia/Hobart</option>
                                                <option value="Australia/Lindeman">Australia/Lindeman</option>
                                                <option value="Australia/Lord_Howe">Australia/Lord_Howe</option>
                                                <option value="Australia/Melbourne">Australia/Melbourne</option>
                                                <option value="Australia/Perth">Australia/Perth</option>
                                                <option value="Australia/Sydney">Australia/Sydney</option>
                                                <option value="Europe/Amsterdam">Europe/Amsterdam</option>
                                                <option value="Europe/Andorra">Europe/Andorra</option>
                                                <option value="Europe/Athens">Europe/Athens</option>
                                                <option value="Europe/Belgrade">Europe/Belgrade</option>
                                                <option value="Europe/Berlin">Europe/Berlin</option>
                                                <option value="Europe/Bratislava">Europe/Bratislava</option>
                                                <option value="Europe/Brussels">Europe/Brussels</option>
                                                <option value="Europe/Bucharest">Europe/Bucharest</option>
                                                <option value="Europe/Budapest">Europe/Budapest</option>
                                                <option value="Europe/Busingen">Europe/Busingen</option>
                                                <option value="Europe/Chisinau">Europe/Chisinau</option>
                                                <option value="Europe/Copenhagen">Europe/Copenhagen</option>
                                                <option value="Europe/Dublin">Europe/Dublin</option>
                                                <option value="Europe/Gibraltar">Europe/Gibraltar</option>
                                                <option value="Europe/Guernsey">Europe/Guernsey</option>
                                                <option value="Europe/Helsinki">Europe/Helsinki</option>
                                                <option value="Europe/Isle_of_Man">Europe/Isle_of_Man</option>
                                                <option value="Europe/Istanbul">Europe/Istanbul</option>
                                                <option value="Europe/Jersey">Europe/Jersey</option>
                                                <option value="Europe/Kaliningrad">Europe/Kaliningrad</option>
                                                <option value="Europe/Kiev">Europe/Kiev</option>
                                                <option value="Europe/Lisbon">Europe/Lisbon</option>
                                                <option value="Europe/Ljubljana">Europe/Ljubljana</option>
                                                <option value="Europe/London">Europe/London</option>
                                                <option value="Europe/Luxembourg">Europe/Luxembourg</option>
                                                <option value="Europe/Madrid">Europe/Madrid</option>
                                                <option value="Europe/Malta">Europe/Malta</option>
                                                <option value="Europe/Mariehamn">Europe/Mariehamn</option>
                                                <option value="Europe/Minsk">Europe/Minsk</option>
                                                <option value="Europe/Monaco">Europe/Monaco</option>
                                                <option value="Europe/Moscow">Europe/Moscow</option>
                                                <option value="Europe/Oslo">Europe/Oslo</option>
                                                <option value="Europe/Paris">Europe/Paris</option>
                                                <option value="Europe/Podgorica">Europe/Podgorica</option>
                                                <option value="Europe/Prague">Europe/Prague</option>
                                                <option value="Europe/Riga">Europe/Riga</option>
                                                <option value="Europe/Rome">Europe/Rome</option>
                                                <option value="Europe/Samara">Europe/Samara</option>
                                                <option value="Europe/San_Marino">Europe/San_Marino</option>
                                                <option value="Europe/Sarajevo">Europe/Sarajevo</option>
                                                <option value="Europe/Simferopol">Europe/Simferopol</option>
                                                <option value="Europe/Skopje">Europe/Skopje</option>
                                                <option value="Europe/Sofia">Europe/Sofia</option>
                                                <option value="Europe/Stockholm">Europe/Stockholm</option>
                                                <option value="Europe/Tallinn">Europe/Tallinn</option>
                                                <option value="Europe/Tirane">Europe/Tirane</option>
                                                <option value="Europe/Uzhgorod">Europe/Uzhgorod</option>
                                                <option value="Europe/Vaduz">Europe/Vaduz</option>
                                                <option value="Europe/Vatican">Europe/Vatican</option>
                                                <option value="Europe/Vienna">Europe/Vienna</option>
                                                <option value="Europe/Vilnius">Europe/Vilnius</option>
                                                <option value="Europe/Volgograd">Europe/Volgograd</option>
                                                <option value="Europe/Warsaw">Europe/Warsaw</option>
                                                <option value="Europe/Zagreb">Europe/Zagreb</option>
                                                <option value="Europe/Zaporozhye">Europe/Zaporozhye</option>
                                                <option value="Europe/Zurich">Europe/Zurich</option>
                                                <option value="Indian/Antananarivo">Indian/Antananarivo</option>
                                                <option value="Indian/Chagos">Indian/Chagos</option>
                                                <option value="Indian/Christmas">Indian/Christmas</option>
                                                <option value="Indian/Cocos">Indian/Cocos</option>
                                                <option value="Indian/Comoro">Indian/Comoro</option>
                                                <option value="Indian/Kerguelen">Indian/Kerguelen</option>
                                                <option value="Indian/Mahe">Indian/Mahe</option>
                                                <option value="Indian/Maldives">Indian/Maldives</option>
                                                <option value="Indian/Mauritius">Indian/Mauritius</option>
                                                <option value="Indian/Mayotte">Indian/Mayotte</option>
                                                <option value="Indian/Reunion">Indian/Reunion</option>
                                                <option value="Pacific/Apia">Pacific/Apia</option>
                                                <option value="Pacific/Auckland">Pacific/Auckland</option>
                                                <option value="Pacific/Chatham">Pacific/Chatham</option>
                                                <option value="Pacific/Chuuk">Pacific/Chuuk</option>
                                                <option value="Pacific/Easter">Pacific/Easter</option>
                                                <option value="Pacific/Efate">Pacific/Efate</option>
                                                <option value="Pacific/Enderbury">Pacific/Enderbury</option>
                                                <option value="Pacific/Fakaofo">Pacific/Fakaofo</option>
                                                <option value="Pacific/Fiji">Pacific/Fiji</option>
                                                <option value="Pacific/Funafuti">Pacific/Funafuti</option>
                                                <option value="Pacific/Galapagos">Pacific/Galapagos</option>
                                                <option value="Pacific/Gambier">Pacific/Gambier</option>
                                                <option value="Pacific/Guadalcanal">Pacific/Guadalcanal</option>
                                                <option value="Pacific/Guam">Pacific/Guam</option>
                                                <option value="Pacific/Honolulu">Pacific/Honolulu</option>
                                                <option value="Pacific/Johnston">Pacific/Johnston</option>
                                                <option value="Pacific/Kiritimati">Pacific/Kiritimati</option>
                                                <option value="Pacific/Kosrae">Pacific/Kosrae</option>
                                                <option value="Pacific/Kwajalein">Pacific/Kwajalein</option>
                                                <option value="Pacific/Majuro">Pacific/Majuro</option>
                                                <option value="Pacific/Marquesas">Pacific/Marquesas</option>
                                                <option value="Pacific/Midway">Pacific/Midway</option>
                                                <option value="Pacific/Nauru">Pacific/Nauru</option>
                                                <option value="Pacific/Niue">Pacific/Niue</option>
                                                <option value="Pacific/Norfolk">Pacific/Norfolk</option>
                                                <option value="Pacific/Noumea">Pacific/Noumea</option>
                                                <option value="Pacific/Pago_Pago">Pacific/Pago_Pago</option>
                                                <option value="Pacific/Palau">Pacific/Palau</option>
                                                <option value="Pacific/Pitcairn">Pacific/Pitcairn</option>
                                                <option value="Pacific/Pohnpei">Pacific/Pohnpei</option>
                                                <option value="Pacific/Port_Moresby">Pacific/Port_Moresby</option>
                                                <option value="Pacific/Rarotonga">Pacific/Rarotonga</option>
                                                <option value="Pacific/Saipan">Pacific/Saipan</option>
                                                <option value="Pacific/Tahiti">Pacific/Tahiti</option>
                                                <option value="Pacific/Tarawa">Pacific/Tarawa</option>
                                                <option value="Pacific/Tongatapu">Pacific/Tongatapu</option>
                                                <option value="Pacific/Wake">Pacific/Wake</option>
                                                <option value="Pacific/Wallis">Pacific/Wallis</option>
                                                <option value="UTC">UTC</option>
                                        </select>
                                        <p>&nbsp;</p>
                                        <button type="submit" class="btn btn-primary" name="submit2" value="Set Time">Change Time Zone</button>
                                </form>







</div>




</div>

</div>




    
     <div class="clearfix"></div>
     <div class="clearfix">&nbsp;</div>
           <div><p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p></div>
    
   

<!-- End Content -->

<div class="clearfix"></div>

<!-- End Content --> 
</main>


<!-- Footer IS Magic -->
<footer>
<?php require('Footer.php'); ?>
</footer>

</body>
</html>


<?php

}


?>



<?php
function sanity_Check_1($var)
  {
    $var = strip_tags($var);
    $var = htmlentities($var, $flags = ENT_QUOTES);
    return $var;
  }    
    


?>
