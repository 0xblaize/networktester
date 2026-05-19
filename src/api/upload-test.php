<?php
// Upload speed test endpoint
// Receives test data to measure upload speed

header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');

// Get the raw request body
$input = file_get_contents('php://input');
$uploadedBytes = strlen($input);

// Simulate some server-side processing
$processingTime = rand(50, 150) / 1000; // 50-150 ms
usleep($processingTime * 1000000);

// Return response with upload info
$response = [
    'status' => 'success',
    'received' => $uploadedBytes,
    'timestamp' => microtime(true)
];

echo json_encode($response);
exit;
?>
