<?php
// Website test endpoint - checks a URL from this PC and reports timing details.

header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');

$url = isset($_GET['url']) ? trim($_GET['url']) : '';

if ($url === '') {
    http_response_code(400);
    echo json_encode(['error' => 'URL is required']);
    exit;
}

if (!preg_match('/^https?:\/\//i', $url)) {
    $url = 'https://' . $url;
}

$parts = parse_url($url);
if ($parts === false || !isset($parts['host']) || !in_array(strtolower($parts['scheme']), ['http', 'https'], true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Enter a valid http or https URL']);
    exit;
}

if (function_exists('curl_init')) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS => 5,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_USERAGENT => 'Network Tester/1.0',
        CURLOPT_HEADER => false,
    ]);

    $body = curl_exec($ch);
    $error = curl_error($ch);
    $info = curl_getinfo($ch);
    curl_close($ch);

    if ($body === false) {
        http_response_code(502);
        echo json_encode(['error' => $error ?: 'Website request failed']);
        exit;
    }

    echo json_encode([
        'url' => $url,
        'finalUrl' => $info['url'] ?? $url,
        'statusCode' => $info['http_code'] ?? 0,
        'totalTimeMs' => round(($info['total_time'] ?? 0) * 1000),
        'dnsTimeMs' => round(($info['namelookup_time'] ?? 0) * 1000),
        'connectTimeMs' => round(($info['connect_time'] ?? 0) * 1000),
        'firstByteTimeMs' => round(($info['starttransfer_time'] ?? 0) * 1000),
        'downloadBytes' => strlen($body),
    ]);
    exit;
}

$start = microtime(true);
$context = stream_context_create([
    'http' => [
        'method' => 'GET',
        'timeout' => 15,
        'ignore_errors' => true,
        'user_agent' => 'Network Tester/1.0',
    ],
]);

$body = @file_get_contents($url, false, $context);
$totalTimeMs = round((microtime(true) - $start) * 1000);

if ($body === false) {
    http_response_code(502);
    echo json_encode(['error' => 'Website request failed']);
    exit;
}

$statusCode = 0;
if (isset($http_response_header[0]) && preg_match('/\s(\d{3})\s/', $http_response_header[0], $matches)) {
    $statusCode = (int)$matches[1];
}

echo json_encode([
    'url' => $url,
    'finalUrl' => $url,
    'statusCode' => $statusCode,
    'totalTimeMs' => $totalTimeMs,
    'dnsTimeMs' => null,
    'connectTimeMs' => null,
    'firstByteTimeMs' => null,
    'downloadBytes' => strlen($body),
]);
exit;
?>
