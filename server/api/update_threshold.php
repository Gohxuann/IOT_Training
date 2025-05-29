<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

include "dbconnect.php";

// Get values from POST request
$temp = isset($_POST['temp_threshold']) ? floatval($_POST['temp_threshold']) : null;
$hum = isset($_POST['hum_threshold']) ? floatval($_POST['hum_threshold']) : null;

if ($temp !== null && $hum !== null) {
    // Save to threshold_table
    $sql = "INSERT INTO `threshold_table`(`temp_threshold`, `hum_threshold`) VALUES ('$temp', '$hum')";

    if ($conn->query($sql) === TRUE) {
        echo "Threshold updated successfully.";
    } else {
        echo "Error: " . $conn->error;
    }
} else {
    echo "Invalid input.";
}

$conn->close();
?>
