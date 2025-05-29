<?php
$servername = "localhost";
$username   = "DB_USERNAME";
$password   = "DB_PWD";
$dbname     = "DB_NAME";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>