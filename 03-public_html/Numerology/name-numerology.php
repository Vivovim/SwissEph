<?php

set_include_path( '/path/to/support/files/' );
date_default_timezone_set( "America/Phoenix" );


if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit('Method not allowed.');
}

// Utility: Sanitize and validate POST input
function get_sanitized_post(string $key, string $default = ''): string {
    return isset($_POST[$key]) ? sanity_Check_1($_POST[$key]) : $default;
}

// Utility: Validate integer, fallback to default
function get_valid_int(string $value, string $default): string {
    return ctype_digit($value) ? $value : $default;
}

// Utility: Validate alpha, fallback to default
function get_valid_alpha(string $value, string $default): string {
    return ctype_alpha($value) ? $value : $default;
}

// Numerology values mapping
function get_numerology_vals(): array {
    return [
        "a" => "1", "b" => "2", "c" => "3", "d" => "4", "e" => "5",
        "f" => "6", "g" => "7", "h" => "8", "i" => "9", "j" => "1",
        "k" => "2", "l" => "3", "m" => "4", "n" => "5", "o" => "6",
        "p" => "7", "q" => "8", "r" => "9", "s" => "1", "t" => "2",
        "u" => "3", "v" => "4", "w" => "5", "x" => "6", "y" => "7", "z" => "8",
    ];
}

// The main numerology sum function
function addUPNames(string $name, array $vals): int {
    $value = 0;
    foreach (str_split($name) as $ntn) {
        if (isset($vals[$ntn])) {
            $value += (int)$vals[$ntn];
        }
    }

    // Reduce to master or single digit
    foreach ([11, 22, 33] as $master) {
        if ($value == $master) return $master;
    }
    while ($value > 9 && !in_array($value, [11, 22, 33])) {
        $value = array_sum(str_split((string)$value));
    }
    return $value;
}

// Validate CSRF token
function validate_csrf_token(string $token): void {
    if (!hash_equals($_SESSION['csrf_token'] ?? '', $token)) {
        die("Bad Token");
    }
}

// Main logic
$day   = get_sanitized_post('day');
$month = get_sanitized_post('month');
$year  = get_sanitized_post('year');

$firstName  = get_sanitized_post('first');
$middleName = get_sanitized_post('middle');
$lastName   = get_sanitized_post('last');

$csrf_token = get_sanitized_post('csrf_token');
validate_csrf_token($csrf_token);

// Validate and assign date fields
$day1   = get_valid_int($day, "17");
$month1 = get_valid_int($month, "09");
$year1  = get_valid_int($year, "1974");

if (!checkdate((int) $month1, (int) $day1, (int) $year1)) {
    http_response_code(422);
    exit('Invalid date.');
}

$date   = "{$day1}:{$month1}:{$year1}";

// Run numerology command
$command = '/home/public_html/cgi-bin/WEB-Numerology.pl ' . escapeshellarg($date);
$vaX = exec($command);

// Validate and assign name fields
$firstNameX  = get_valid_alpha($firstName, "Joe");
$middleNameX = get_valid_alpha($middleName, "Joe");
$lastNameX   = get_valid_alpha($lastName, "Huffaker");

$names = [$firstNameX, $middleNameX, $lastNameX];
$full_name = strtolower(implode('', $names));
$vals = get_numerology_vals();

$xways = addUPNames($full_name, $vals);

// Calculate values for each name part
$scores = array_map(function ($name) use ($vals) {
    return addUPNames(strtolower($name), $vals);
}, $names);

$total = array_sum($scores);

// Reduce total to a single digit or master number
$total_reduced = $total;
foreach ([11, 22, 33] as $master) {
    if ($total == $master) {
        $total_reduced = $master;
        break;
    }
}
if (!in_array($total_reduced, [11, 22, 33])) {
    $total_reduced = array_sum(str_split((string)$total));
}

// Vowels and consonants numerology
$vowels = implode('', array_map(function ($name) {
    return preg_replace('/[bcdfghjklmnpqrstvwxz]/i', '', strtolower($name));
}, $names));
$vowel_score = addUPNames($vowels, $vals);

$consonants = implode('', array_map(function ($name) {
    return preg_replace('/[aeiouy]/i', '', strtolower($name));
}, $names));
$consonant_score = addUPNames($consonants, $vals);

// Reduce consonant score if not a master number
$consonant_reduced = $consonant_score;
if (!in_array($consonant_score, [11, 22, 33])) {
    $consonant_reduced = array_sum(str_split((string)$consonant_score));
}

// Group results
$resultsXX = [
    'First'       => $scores[0],
    'Middle'      => $scores[1],
    'Last'        => $scores[2],
    'Total'       => $total,
    'TotalReduced'=> $total_reduced,
    'LifePath'    => $vaX,
    'Soul'        => $vowel_score,
    'Personality' => $consonant_reduced,
];

// Example usage/print
// print_r($results);

?>
<?php
set_include_path( '/path/to/support/files/' );
date_default_timezone_set( "America/Phoenix" );

ini_set( 'session.use_only_cookies', true );
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}




$setT   = date('U');



        if ( isset( $_SESSION[ 'TZ' ] ) ) {
                $TimeZone1 = sanity_Check_1( $_SESSION[ 'TZ' ] );
                date_default_timezone_set( $TimeZone1 );

        } else {

                $TimeZone1 = "America/Phoenix";

                date_default_timezone_set( $TimeZone1 );

        }


        



?>
<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
        <title>Astro.Ctopher.Me | Numerology Scores</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="https://astro.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css" />
        
        
        
        <link href="https://astro.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
                
        <script src="https://astro.ctopher.me/js/jquery-3.6.0.min.js"></script>
        <script src="https://astro.ctopher.me/js/bootstrap.js"></script>
        
        <script src="https://astro.ctopher.me/js/odometer.min.js"></script>
        
        
        <link href="https://astro.ctopher.me/css/odometer-theme-digital.css" rel="stylesheet" type="text/css" />
        
         <script src="https://astro.ctopher.me/js/jquery.form.min.js"></script>   
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
         <meta property="og:image" content="https://neo.ctopher.me/artwork/neo-ctopher-placecard.jpg"/>
        




<style>
    
    .float-left {
    float: left;
}
    
    
    .odometer {
  font-size: 42px;
  line-height: 100px;
}
        </style>
        
        
</head>
<body>


    
<!-- Nav bar Code Here -->  
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
        
        
<!-- Logo Header -->        
<header>                
<div id="Logo">
    </div>
</header>        


<main>
<div class="container">
 <h1 class="About_H1">Numerology Calculations For You!!</h1>
        <div id="Planets" class="container">
               
          <div class="row Numerology">



             <div class="About_H1 float-left">Life Path: &nbsp;</div> <div class="float-left"><?php echo $resultsXX["LifePath"]; ?></div>             
             </div>
             
             <div class="clearfix">&nbsp;</div>
             
             <div class="About_H1">First Name: <?php echo $resultsXX["First"]; ?></div>
             
             <div class="About_H1">Middle Name: <?php echo $resultsXX["Middle"]; ?></div>
             
             <div class="About_H1">Last Name: <?php echo $resultsXX["Last"]; ?></div>
             
             <div class="row Numerology">
             
             <div class="About_H1 float-left">Expression Numbers:&nbsp;</div><div class="About_H1 float-left"> <?php echo $resultsXX["TotalReduced"]; ?>/</div><div class="float-left"><?php echo $resultsXX["Total"]; ?></div>
             </div>
             <div class="clearfix">&nbsp;</div>
             
             
             <div class="row Numerology">
             <div class="About_H1 float-left">Soul Desire:&nbsp;</div><div class="float-left"> <?php echo $resultsXX["Soul"]; ?></div>
             </div>
             
             
             <div class="clearfix">&nbsp;</div>
             
             <div class="row Numerology">
             <div class="About_H1 float-left">Personality:&nbsp;</div><div class="float-left"> <?php echo $resultsXX["Personality"]; ?></div>
             </div>
             <div class="clearfix">&nbsp;</div>
             
             
     
     
</div>    
               
    </div>
    
    <div class="container">
    <p class="DYKPlate">
    Calculations Provided, with no warranty  of any kind. Use at your own risk.
    </p>
    <p class="DYKPlate">
    Do your own research on the numbers. I won't provide the info about them.
	</p>
	
	
	<p class="DYKPlate">
	This book will answer your questions: <a href="https://www.amazon.com/Ultimate-Guide-Practical-Numerology-Mapping-ebook/dp/B09VMQJNW2/">The Ultimate Guide to Numerology</a>
	</p>
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
<?php require('Footer.php'); ?>
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
