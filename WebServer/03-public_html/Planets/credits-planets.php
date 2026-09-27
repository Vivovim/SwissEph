<?php
set_include_path( '/path/to/support/files/' );
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
        <title>Astro.Ctopher.Me | Planets Credits</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="https://neo.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css" />
        
        
        
        <link href="https://neo.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
                
        <script src="https://neo.ctopher.me/js/jquery-3.5.1.min.js"></script>
        <script src="https://neo.ctopher.me/js/bootstrap.min.js"></script>
        
      
        
        <link href="https://neo.ctopher.me/css/-theme-digital.css" rel="stylesheet" type="text/css" />
        
        
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
        
  

<script src="https://neo.ctopher.me/js/secondsXT.js"></script>



<style>
    
    . {
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
<div id="Logo">
    </div>
</header>        

<main>


<?php require "swish.php";?>


        
        
        
        
  
        
        
                
                
<!-- Content Below -->
<div class="container">
    
    <h1 class="About_H1">Planet Credits for images</h1>
    <div class="col-lg-12">
    
<div class="col-md-2 float-left"><img src="artwork/day-15.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Moon: </div> 
<div class="Working_H1B">Christopher Thomas</div>
	
<div class="clearfix"></div>

<div class="col-md-2 float-left"><img src="artwork/mercury.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Mercury: </div> 
<div class="body-style">Image credit: NASA/Johns Hopkins University Applied Physics Laboratory/Carnegie Institution of Washington</div>
	
<div class="clearfix"></div>
		
<div class="col-md-2 float-left"><img src="artwork/venus.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Venus: </div> 
<div class="Working_H1B">Unknown</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/earth.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Earth: </div> 
<div class="Working_H1B">Unknown</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/mars-02.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Mars: </div> 
<div class="Working_H1B">Unknown</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/jupiter.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Jupiter: </div> 
<div class="body-style">Credit: NASA, ESA, Jupiter ERS Team; image processing by Judy Schmidt</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/saturn.png" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Saturn: </div> 
<div class="Working_H1B  float-left">Unknown</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/uranus-02.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Uranus: </div> 
<div class="Working_H1B  float-left">Unknown</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/neptune.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Neptune: </div> 
<div class="Working_H1B  float-left">Unknown</div>
	
<div class="clearfix"></div>
<div class="col-md-2 float-left"><img src="artwork/pluto.jpg" width="100" height="100" alt=""/></div>
<div class="About_H1 float-left col-md-3">Pluto: </div> 
<div class="Working_H1B  float-left">Unknown</div>
	
<div class="clearfix"></div> 
		<div>I'm currently working to correct this page. It might take me some time.</div>
	</div>
		
		
    <div class="flex-column">
    
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
