# Regenera posts/index.json a partir do cabeçalho (front matter) dos ficheiros posts/*.md
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $root "posts"
$posts = @()

foreach ($f in Get-ChildItem -Path $dir -Filter *.md) {
    $text = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    $m = [regex]::Match($text, '^---\r?\n(.*?)\r?\n---', 'Singleline')
    if (-not $m.Success) { Write-Warning "$($f.Name): sem cabeçalho, ignorado"; continue }

    $meta = @{}
    foreach ($line in $m.Groups[1].Value -split '\r?\n') {
        if ($line -match '^\s*(\w+)\s*:\s*(.*)$') { $meta[$Matches[1]] = $Matches[2].Trim() }
    }

    $tags = @()
    if ($meta.tags) { $tags = @($meta.tags -split '\s*,\s*' | Where-Object { $_ }) }

    $posts += [pscustomobject]@{
        slug   = $f.BaseName
        titulo = $meta.titulo
        data   = $meta.data
        resumo = $meta.resumo
        tags   = $tags
    }
}

$posts = @($posts | Sort-Object data -Descending)
$json = if ($posts.Count -eq 0) { "[]" } else { ConvertTo-Json -InputObject $posts -Depth 4 }
[IO.File]::WriteAllText((Join-Path $dir "index.json"), $json, (New-Object Text.UTF8Encoding($false)))
Write-Host "index.json atualizado com $($posts.Count) texto(s)."
