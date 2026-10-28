# Uso: .\novo-post.ps1 "Título do texto"
param([Parameter(Mandatory = $true)][string]$Titulo)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$slug = $Titulo.Normalize([Text.NormalizationForm]::FormD)
$slug = [regex]::Replace($slug, '\p{Mn}', '')
$slug = ($slug.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
$file = Join-Path $root "posts\$slug.md"

if (Test-Path $file) { Write-Error "Já existe: $file"; exit 1 }

$content = @"
---
titulo: $Titulo
data: $(Get-Date -Format 'yyyy-MM-dd')
resumo:
tags:
---

Escreve aqui.
"@
[IO.File]::WriteAllText($file, $content, (New-Object Text.UTF8Encoding($false)))
Write-Host "Criado: $file"
Write-Host "Depois de escrever, corre .\atualizar.ps1"
