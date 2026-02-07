param($Port = 8000)

$Root = Get-Location
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")
try {
    $Listener.Start()
}
catch {
    Write-Host "Port $Port is in use. Trying port $($Port + 1)..."
    $Port++
    $Listener.Prefixes.Clear()
    $Listener.Prefixes.Add("http://localhost:$Port/")
    $Listener.Start()
}

Write-Host "Server running at http://localhost:$Port/"
Write-Host "Root: $Root"
Write-Host "Press Ctrl+C to stop."

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

while ($Listener.IsListening) {
    try {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        $Path = $Request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($Path)) { $Path = "index.html" }
        
        $FilePath = Join-Path $Root $Path
        
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
    }
    catch {
        Write-Host "Error processing request: $_"
        if ($Response) { try { $Response.Close() } catch {} }
    }
    finally {
        if ($Response) { try { $Response.Close() } catch {} }
    }
}
