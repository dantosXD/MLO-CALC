param(
  [int]$Port = 4173,
  [string]$Host = '127.0.0.1'
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  $python = Get-Command py -ErrorAction SilentlyContinue
}

if (-not $python) {
  throw 'Python is required to serve build/web on 127.0.0.1:4173.'
}

& $python.Source -m http.server $Port --bind $Host --directory build\web
