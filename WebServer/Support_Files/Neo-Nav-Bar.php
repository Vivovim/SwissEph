<?php

set_include_path( '__HIDDEN__' );

require("swish.php");
?>


<!-- Nav bar Code Here -->
<div class="container-fluid">
        <nav class="navbar navbar-default navbar-dark fixed-top NAV_Font" id="Half50">
                <nav class="navbar navbar-inner navbar-expand-lg"><img src="https://neo.ctopher.me/neo.png" style="max-width: 50px;" alt="Pi Symbol" > <a class="navbar-brand NAV_Space" href="https://neo.ctopher.me/">Neo Ctopher</a>
                        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation"> <span class="navbar-toggler-icon"></span> </button>
                        <div class="collapse navbar-collapse" id="navbarNav">
                                <ul class="navbar-nav">
                                       
                                       
                                      

					
													
                        
                                                    
                                                    

                                      
                            
                                        
                                       
                                       
                                    
                                   
                                 
                                    <li class="nav-item NAV_Space"><a href="https://neo.ctopher.me/time.php" class="nav-link"><span id="ClockSecondsX"></span></a></li>
                                    
                                    
                             
                            
                            
      </ul>
      
      
      <select id="jm1" class="jumpmenu">
      <option value="">Links Please Choose</option>
   <?php

                        $connection = new mysqli( $host, $username, $password, $db );
                        if ( $connection->connect_error )die( $connection->connect_error );


                        $query = "SELECT link, title FROM neoctopher ORDER BY recid";
                        $results = $connection->query( $query );

                        if ( !$results )die( $connection->error );

                        $rows = $results->num_rows;


                        for ( $i = 0; $i < $rows; ++$i ) {

                                $results->data_seek( $i );

                                $row = $results->fetch_array( MYSQLI_ASSOC );

                                $link = $row[ 'link' ];
                                $title = $row[ 'title' ];

								

print " <option value=\"" . $link . "\">". $title . "</option>\n";

                                



                        }


                        ?>
    
</select>

 <ul class="navbar-nav">
      
      <li class="nav-item NAV_Space"><a href="https://search42.xyzzy42.me" class="nav-link" target="_blank">Search</a></li>
        
      
      </ul>
                           
                        </div>
                </nav>
        </nav>
</div>


<script src="https://neo.ctopher.me/js/Jump-Menu.js"></script> 






                



<!-- end Nav Bar Code --> 
