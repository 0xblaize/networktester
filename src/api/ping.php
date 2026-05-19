<?php
// Ping endpoint - responds quickly to test latency
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');

$response = [
    'status' => 'pong',
    'timestamp' => microtime(true)
];

echo json_encode($response);
?>
