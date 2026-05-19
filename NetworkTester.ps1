$ErrorActionPreference = 'Stop'

$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-PortOpen {
    param([int]$Port)

    try {
        $client = New-Object Net.Sockets.TcpClient
        $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne(200, $false)
        if ($connected) {
            $client.EndConnect($async)
        }
        $client.Close()
        return $connected
    }
    catch {
        return $false
    }
}

$port = 8757
while (Test-PortOpen -Port $port) {
    $port++
}

$url = "http://127.0.0.1:$port"

$serverJob = Start-Job -ArgumentList $appRoot, $port -ScriptBlock {
    param($Root, $Port)

    $ErrorActionPreference = 'Stop'
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://127.0.0.1:$Port/")
    $listener.Start()

    function Send-Bytes {
        param(
            [System.Net.HttpListenerResponse]$Response,
            [byte[]]$Bytes,
            [string]$ContentType = 'application/octet-stream',
            [int]$StatusCode = 200
        )

        $Response.StatusCode = $StatusCode
        $Response.ContentType = $ContentType
        $Response.ContentLength64 = $Bytes.Length
        $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        $Response.OutputStream.Close()
    }

    function Send-Text {
        param(
            [System.Net.HttpListenerResponse]$Response,
            [string]$Text,
            [string]$ContentType = 'text/plain; charset=utf-8',
            [int]$StatusCode = 200
        )

        Send-Bytes -Response $Response -Bytes ([Text.Encoding]::UTF8.GetBytes($Text)) -ContentType $ContentType -StatusCode $StatusCode
    }

    function Send-Json {
        param(
            [System.Net.HttpListenerResponse]$Response,
            [object]$Data,
            [int]$StatusCode = 200
        )

        Send-Text -Response $Response -Text ($Data | ConvertTo-Json -Compress -Depth 4) -ContentType 'application/json; charset=utf-8' -StatusCode $StatusCode
    }

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            $path = $request.Url.AbsolutePath

            $response.Headers.Add('Cache-Control', 'no-cache, no-store, must-revalidate')

            try {
                if ($path -eq '/' -or $path -eq '/index.php') {
                    $file = Join-Path $Root 'public\index.html'
                    Send-Bytes -Response $response -Bytes ([IO.File]::ReadAllBytes($file)) -ContentType 'text/html; charset=utf-8'
                }
                elseif ($path -eq '/styles.css') {
                    $file = Join-Path $Root 'public\styles.css'
                    Send-Bytes -Response $response -Bytes ([IO.File]::ReadAllBytes($file)) -ContentType 'text/css; charset=utf-8'
                }
                elseif ($path -eq '/app.js') {
                    $file = Join-Path $Root 'public\app.js'
                    Send-Bytes -Response $response -Bytes ([IO.File]::ReadAllBytes($file)) -ContentType 'application/javascript; charset=utf-8'
                }
                elseif ($path -eq '/api/ping') {
                    Send-Json -Response $response -Data @{
                        status = 'pong'
                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                }
                elseif ($path -eq '/api/download-test') {
                    $sizeText = $request.QueryString['size']
                    $size = 1024 * 1024
                    if ([int]::TryParse($sizeText, [ref]$size)) {
                        $size = [Math]::Min($size, 100 * 1024 * 1024)
                    }

                    $response.StatusCode = 200
                    $response.ContentType = 'application/octet-stream'
                    $response.ContentLength64 = $size

                    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
                    $buffer = New-Object byte[] (64 * 1024)
                    $remaining = $size
                    while ($remaining -gt 0) {
                        $count = [Math]::Min($buffer.Length, $remaining)
                        $random.GetBytes($buffer)
                        $response.OutputStream.Write($buffer, 0, $count)
                        $remaining -= $count
                    }
                    $random.Dispose()
                    $response.OutputStream.Close()
                }
                elseif ($path -eq '/api/upload-test') {
                    $buffer = New-Object byte[] 65536
                    $total = 0
                    do {
                        $read = $request.InputStream.Read($buffer, 0, $buffer.Length)
                        $total += $read
                    } while ($read -gt 0)

                    Send-Json -Response $response -Data @{
                        status = 'success'
                        received = $total
                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                }
                elseif ($path -eq '/api/website-test') {
                    $target = $request.QueryString['url']
                    if ([string]::IsNullOrWhiteSpace($target)) {
                        Send-Json -Response $response -Data @{ error = 'URL is required' } -StatusCode 400
                        continue
                    }

                    if ($target -notmatch '^https?://') {
                        $target = "https://$target"
                    }

                    $watch = [Diagnostics.Stopwatch]::StartNew()
                    try {
                        $siteResponse = Invoke-WebRequest -Uri $target -UseBasicParsing -MaximumRedirection 5 -TimeoutSec 15
                        $watch.Stop()
                        Send-Json -Response $response -Data @{
                            url = $target
                            finalUrl = $siteResponse.BaseResponse.ResponseUri.AbsoluteUri
                            statusCode = [int]$siteResponse.StatusCode
                            totalTimeMs = [int]$watch.ElapsedMilliseconds
                            dnsTimeMs = $null
                            connectTimeMs = $null
                            firstByteTimeMs = $null
                            downloadBytes = $siteResponse.RawContentLength
                        }
                    }
                    catch {
                        $watch.Stop()
                        Send-Json -Response $response -Data @{ error = $_.Exception.Message } -StatusCode 502
                    }
                }
                else {
                    Send-Text -Response $response -Text '404 - Page not found' -StatusCode 404
                }
            }
            catch {
                Send-Json -Response $response -Data @{ error = $_.Exception.Message } -StatusCode 500
            }
        }
    }
    finally {
        if ($listener.IsListening) {
            $listener.Stop()
        }
        $listener.Close()
    }
}

$ready = $false
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    try {
        $response = Invoke-WebRequest -Uri "$url/api/ping" -UseBasicParsing -TimeoutSec 1
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    }
    catch {
    }
}

if (-not $ready) {
    Stop-Job -Job $serverJob -ErrorAction SilentlyContinue
    Remove-Job -Job $serverJob -Force -ErrorAction SilentlyContinue
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        'Network Tester could not start the local app server.',
        'Network Tester',
        'OK',
        'Error'
    ) | Out-Null
    exit 1
}

$browserCandidates = @(
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
)

$browser = $browserCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

try {
    if ($browser) {
        $browserProcess = Start-Process -FilePath $browser -ArgumentList @("--app=$url") -PassThru
        Wait-Process -Id $browserProcess.Id
    }
    else {
        Start-Process $url
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "Network Tester is running at $url.`n`nClose this message when you are done to stop the local server.",
            'Network Tester',
            'OK',
            'Information'
        ) | Out-Null
    }
}
finally {
    Stop-Job -Job $serverJob -ErrorAction SilentlyContinue
    Remove-Job -Job $serverJob -Force -ErrorAction SilentlyContinue
}
