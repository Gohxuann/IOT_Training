<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

include "dbconnect.php";

// Get the latest threshold settings
$sql = "SELECT `temp_threshold`, `hum_threshold` FROM `threshold_table` ORDER BY `updated_at` DESC LIMIT 1";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode($result->fetch_assoc());
} else {
    // Default fallback if no data found
    echo json_encode([
        "temp_threshold" => 32.00,
        "hum_threshold" => 90.00
    ]);
}

$conn->close();
?>
