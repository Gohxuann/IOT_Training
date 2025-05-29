<?php
error_reporting(0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

include_once("dbconnect.php");

$id = $_GET['id'];
$temp = $_GET['temp'];
$hum = $_GET['hum'];
$relay_status = $_GET['relay_status'];

$sqlinsert = "INSERT INTO `dhthttp_train_table`(`user_id`, `temp`, `hum`, `relay_status`) VALUES ('$id','$temp','$hum','$relay_status')";

if ($conn->query($sqlinsert) === TRUE){
    echo "success";
}else{
    echo "failed";
}

?>