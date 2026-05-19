<?php
// Download speed test endpoint
// Serves test data for download speed measurement

header('Content-Type: application/octet-stream');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');

// Get requested file size from query parameter
$size = isset($_GET['size']) ? (int)$_GET['size'] : 1024 * 1024; // Default 1 MB
$size = min($size, 100 * 1024 * 1024); // Max 100 MB to prevent abuse

// Generate random data in chunks to simulate file download
$chunkSize = 64 * 1024; // 64 KB chunks
$remaining = $size;

while ($remaining > 0) {
    $currentChunk = min($chunkSize, $remaining);
    echo openssl_random_pseudo_bytes($currentChunk);
    $remaining -= $currentChunk;
    flush(); // Send data immediately
    
    // Allow script to continue running
    if (connection_status() != 0) {
        break;
    }
}

exit;
?>
