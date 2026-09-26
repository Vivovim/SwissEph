<?php





  try {
  $TimeZone1 = sanity_Check_1($_SESSION['TZ'] ?? '');
  new DateTimeZone($TimeZone1);              // throws if invalid
} catch (Exception $e) {
  $TimeZone1 = "America/Phoenix";
}
date_default_timezone_set($TimeZone1);
$_SESSION['TZ'] = $TimeZone1;
  
  
  
?>