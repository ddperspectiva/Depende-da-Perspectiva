# Servidor local simples: abre http://localhost:8080
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8080
$types = @{
    ".html" = "text/html; charset=utf-8"; ".css" = "text/css; charset=utf-8"
    ".js" = "text/javascript; charset=utf-8"; ".json" = "application/json; charset=utf-8"
    ".md" = "text/plain; charset=utf-8"; ".png" = "image/png"; ".jpg" = "image/jpeg"
    ".svg" = "image/svg+xml"; ".ico" = "image/x-icon"
}

$listener = New-Object Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "A servir $root em http://localhost:$port  (Ctrl+C para parar)"

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
        if ($rel -eq "") { $rel = "index.html" }
        $path = [IO.Path]::GetFullPath((Join-Path $root $rel))

        if ($path.StartsWith($root) -and (Test-Path $path -PathType Leaf)) {
            $ext = [IO.Path]::GetExtension($path).ToLower()
            $ctx.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { "application/octet-stream" }
            $bytes = [IO.File]::ReadAllBytes($path)
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
        $ctx.Response.Close()
    }
} finally {
    $listener.Stop()
}
