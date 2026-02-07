param($Port = 8000)

$Root = $PSScriptRoot
if (-not $Root) { $Root = Get-Location }

$Listener = $null
$CurrentPort = $Port

while ($null -eq $Listener -and $CurrentPort -lt $Port + 10) {
    try {
        $TempListener = New-Object System.Net.HttpListener
        $TempListener.Prefixes.Add("http://localhost:$CurrentPort/")
        $TempListener.Start()
        $Listener = $TempListener
        Write-Host "Server running at http://localhost:$CurrentPort/"
    }
    catch {
        Write-Host "Port $CurrentPort is in use. Trying next..."
        $CurrentPort++
    }
}

if ($null -eq $Listener) {
    Write-Error "Could not find an available port."
    exit 1
}

Write-Host "Root: $Root"
Write-Host "Press Ctrl+C to stop (if interactive)."

$MimeTypes = @{
    ".html"  = "text/html"
    ".js"    = "application/javascript"
    ".css"   = "text/css"
    ".svg"   = "image/svg+xml"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".json"  = "application/json"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"   = "font/ttf"
}

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        $Path = $Request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($Path)) { $Path = "index.html" }
        
        $FilePath = Join-Path $Root $Path
        
        # If it's a directory or doesn't exist, fallback to index.html for SPA routing
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            $FilePath = Join-Path $Root "index.html"
        }

        if (Test-Path $FilePath -PathType Leaf) {
            $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
            $ContentType = "application/octet-stream"
            if ($MimeTypes.ContainsKey($Extension)) {
                $ContentType = $MimeTypes[$Extension]
            }
            
            $Bytes = [System.IO.File]::ReadAllBytes($FilePath)
            $Response.ContentType = $ContentType
            $Response.ContentLength64 = $Bytes.Length
            $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
            $Response.StatusCode = 200
        }
        else {
            $Response.StatusCode = 404
        }
        $Response.Close()
    }
}
catch {
    Write-Host "Server error: $_"
}
finally {
    if ($null -ne $Listener) {
        $Listener.Stop()
    }
}
