<?php
// PHP Internet Speed Tester
// Main application entry point

session_start();

// Simple router
$request_uri = $_SERVER['REQUEST_URI'];
$base_path = str_replace('\\', '/', dirname($_SERVER['PHP_SELF']));

if ($base_path !== '/') {
    $request_uri = str_replace($base_path, '', $request_uri);
}

// Remove query string from request
$request_uri = parse_url($request_uri, PHP_URL_PATH);

// Route requests
if ($request_uri === '/' || $request_uri === '/index.php' || empty($request_uri)) {
    include 'public/index.html';
} elseif (preg_match('/^\/api\//', $request_uri)) {
    header('Content-Type: application/json');
    
    if ($request_uri === '/api/ping') {
        include 'src/api/ping.php';
    } elseif ($request_uri === '/api/download-test') {
        include 'src/api/download-test.php';
    } elseif ($request_uri === '/api/upload-test') {
        include 'src/api/upload-test.php';
    } elseif ($request_uri === '/api/website-test') {
        include 'src/api/website-test.php';
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'API endpoint not found']);
    }
} else {
    http_response_code(404);
    echo "404 - Page not found";
}
?>
