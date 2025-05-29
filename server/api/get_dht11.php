<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

include("dbconnect.php");

$limit = isset($_GET['limit']) ? intval($_GET['limit']) : 50;
$sql = "SELECT * FROM `dhthttp_train_table` ORDER BY `id` DESC LIMIT $limit";
$result = mysqli_query($conn, $sql);

$data = array();
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = array(
        'id' => $row['id'],
        'temp' => $row['temp'],
        'hum' => $row['hum'],
        'relay_status' => $row['relay_status'],
        'date' => $row['date'] ?? ''
    );
}

// Reverse the array so it goes oldest -> newest
$data = array_reverse($data);

echo json_encode($data);
?>
