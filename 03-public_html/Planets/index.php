<?php
set_include_path( '/path/to/support/files/' );
date_default_timezone_set( "America/Phoenix" );


if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

$_SESSION['csrf_token'] = bin2hex(random_bytes(32));





?>
<!DOCTYPE html>
<html lang="en" >
    <head>
        <meta charset="utf-8" />
        <title>Astro.Ctopher.Me | Calculate Your Planet Revolutions</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="https://astro.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css" />
        
        
        
        <link href="https://astro.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
                
        <script src="https://astro.ctopher.me/js/jquery-3.6.0.min.js"></script>
        <script src="https://astro.ctopher.me/js/bootstrap.min.js"></script>
        
        <script src="https://astro.ctopher.me/js/odometer.min.js"></script>
        
        
        <link href="https://astro.ctopher.me/css/odometer-theme-digital.css" rel="stylesheet" type="text/css" />
        
         <script src="https://astro.ctopher.me/js/jquery.form.min.js"></script>   
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
         <meta property="og:image" content="https://neo.ctopher.me/artwork/neo-ctopher-placecard.jpg"/>
        
 



<style>
    
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
 <h1 class="About_H1">Calculate Your Planet Revolutions</h1>
        <div id="Planets" class="container">
               
                <form id="htmlForm" action="https://astro.ctopher.me/Planets/calculate.php" method="post" onSubmit="return validateForm()"> 
               
<input id="year" type="text" name="year" placeholder="Year = 1970"> 
<input type="text" name="month" id="month" placeholder="Month = 1 - 12"> 
<input type="text" name="day" id="day" placeholder="Day = 1 - 31">
	
	

 <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">

        
        <div>Enter your birth date, in Year, Month, Day format, to see your results.</div>
        <div>Results, are never stored on our system, your data remains private.</div>
        <div>&nbsp;</div>
               
               
               
               
             
               


        
        
  
   
		
		
    <div class="flex-column">
     <button class="glass"">Calculate Planet Age</button>
     
     
       </form>
               
    </div>
    
    
   
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
