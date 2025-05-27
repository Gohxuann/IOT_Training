<?php
error_reporting(0);
include_once("dbconnect.php");

$id = $_GET['id'];
$temp = $_GET['temp'];
$hum = $_GET['hum'];

$sqlinsert = "INSERT INTO `dhthttp_train_table`(`user_id`, `temp`, `hum`) VALUES ('$id','$temp','$hum')";

if ($conn->query($sqlinsert) === TRUE){
    echo "success";
}else{
    echo "failed";
}

?>