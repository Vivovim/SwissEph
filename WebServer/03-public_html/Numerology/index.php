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
        <title>Astro.Ctopher.Me | Numerology Calculator</title>
        
        
        
        <link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
        <link href="https://astro.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css" />
        
        
        
        <link href="https://astro.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css" />
                
        <script src="https://astro.ctopher.me/js/jquery-3.6.0.min.js"></script>
        <script src="https://astro.ctopher.me/js/bootstrap.min.js"></script>
        
        <script src="https://astro.ctopher.me/js/odometer.min.js"></script>
        
        
        <link href="https://astro.ctopher.me/css/odometer-theme-digital.css" rel="stylesheet" type="text/css" />
        
         <script src="https://astro.ctopher.me/js/jquery.form.min.js"></script>   
        
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    



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
 <h1 class="About_H1">Numerology Calculations For You!!</h1>
        <div id="Planets" class="container">
               
                <form id="htmlForm" action="https://astro.ctopher.me/Numerology/name-numerology.php" method="post"> 
<div class="d-flex flex-row">
<div class="p-2">
<select name="month" class="form-control">
<option value="01">January</option>
<option value="02">February</option>
<option value="03">March</option>
<option value="04">April</option>
<option value="05">May</option>
<option value="06">June</option>
<option value="07">July</option>
<option value="08">August</option>
<option value="09">September</option>
<option value="10">October</option>
<option value="11">November</option>
<option value="12">December</option>
</select>
</div>


<div class="p-2">
<select name="day" class="form-control">
<option value="01">01</option>
<option value="02">02</option>
<option value="03">03</option>
<option value="04">04</option>
<option value="05">05</option>
<option value="06">06</option>
<option value="07">07</option>
<option value="08">08</option>
<option value="09">09</option>
<option value="10">10</option>
<option value="11">11</option>
<option value="12">12</option>
<option value="13">13</option>
<option value="14">14</option>
<option value="15">15</option>
<option value="16">16</option>
<option value="17">17</option>
<option value="18">18</option>
<option value="19">19</option>
<option value="20">20</option>
<option value="21">21</option>
<option value="22">22</option>
<option value="23">23</option>
<option value="24">24</option>
<option value="25">25</option>
<option value="26">26</option>
<option value="27">27</option>
<option value="28">28</option>
<option value="29">29</option>
<option value="30">30</option>
<option value="31">31</option>

</select>
</div>
<div class="p-2">

<select name="year" class="form-control">
<option value="1940">1940</option>
<option value="1941">1941</option>
<option value="1942">1942</option>
<option value="1943">1943</option>
<option value="1944">1944</option>
<option value="1945">1945</option>
<option value="1946">1946</option>
<option value="1947">1947</option>
<option value="1948">1948</option>
<option value="1949">1949</option>
<option value="1950">1950</option>
<option value="1951">1951</option>
<option value="1952">1952</option>
<option value="1953">1953</option>
<option value="1954">1954</option>
<option value="1955">1955</option>
<option value="1956">1956</option>
<option value="1957">1957</option>
<option value="1958">1958</option>
<option value="1959">1959</option>
<option value="1960">1960</option>
<option value="1961">1961</option>
<option value="1962">1962</option>
<option value="1963">1963</option>
<option value="1964">1964</option>
<option value="1965">1965</option>
<option value="1966">1966</option>
<option value="1967">1967</option>
<option value="1968">1968</option>
<option value="1969">1969</option>
<option value="1970">1970</option>
<option value="1971">1971</option>
<option value="1972">1972</option>
<option value="1973">1973</option>
<option value="1974">1974</option>
<option value="1975">1975</option>
<option value="1976">1976</option>
<option value="1977">1977</option>
<option value="1978">1978</option>
<option value="1979">1979</option>
<option value="1980">1980</option>
<option value="1981">1981</option>
<option value="1982">1982</option>
<option value="1983">1983</option>
<option value="1984">1984</option>
<option value="1985">1985</option>
<option value="1986">1986</option>
<option value="1987">1987</option>
<option value="1988">1988</option>
<option value="1989">1989</option>
<option value="1990">1990</option>
<option value="1991">1991</option>
<option value="1992">1992</option>
<option value="1993">1993</option>
<option value="1994">1994</option>
<option value="1995">1995</option>
<option value="1996">1996</option>
<option value="1997">1997</option>
<option value="1998">1998</option>
<option value="1999">1999</option>
<option value="2000">2000</option>
<option value="2001">2001</option>
<option value="2002">2002</option>
<option value="2003">2003</option>
<option value="2004">2004</option>
<option value="2005">2005</option>
<option value="2006">2006</option>
<option value="2007">2007</option>
<option value="2008">2008</option>
<option value="2009">2009</option>
<option value="2010">2010</option>
<option value="2011">2011</option>
<option value="2012">2012</option>
<option value="2013">2013</option>
<option value="2014">2014</option>
<option value="2015">2015</option>
<option value="2016">2016</option>
<option value="2017">2017</option>
<option value="2018">2018</option>
<option value="2019">2019</option>
<option value="2020">2020</option>
<option value="2021">2021</option>
<option value="2022">2022</option>
<option value="2023">2023</option>
<option value="2024">2024</option>
</select>
</div>
</div>

<div class="clearfix">&nbsp;</div>



<div class="d-flex flex-row">
<div class="p-2"><input id="first" type="text" name="first" placeholder="First Name"> </div>
<div class="p-2"><input type="text" name="middle" id="middle" placeholder="Middle Name"></div> 
<div class="p-2"><input type="text" name="last" id="last" placeholder="Last Name"></div>
</div>
	
	
 <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">


        
        <div>Enter your Birthday, and full name.</div>
        <div>The letter, "Y" is treated as a vowel. Please do not use, if the letter Y is a consonant in your name.</div>
        <div>For entertainment purposes only; use at your own risk!!!</div>
        <div>Results, are never stored on our system, your data remains private.</div>
        <div>&nbsp;</div>
               
               
               
               
             
               


        
        
  
   
		
		
    <div class="flex-column">
     <button class="glass"">Numerology Score</button>
     
     
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
