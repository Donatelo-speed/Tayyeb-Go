param(
  [ValidateSet("all", "customer", "partner", "driver", "admin", "functions")]
  [string]$App = "all"
)

if ($App -eq "all") {
  $apps = @("customer", "partner", "driver", "admin")
} elseif ($App -eq "functions") {
  $apps = @()
} else {
  $apps = @($App)
}

# Build Flutter apps
foreach ($a in $apps) {
  Write-Host "=== Building $a ===" -ForegroundColor Cyan
  Push-Location "apps/tayyebgo_$a"
  flutter build web --release
  Pop-Location
}

Write-Host ""
Write-Host "=== Installing Functions Dependencies ===" -ForegroundColor Cyan
Push-Location "functions"
npm install
Pop-Location

Write-Host ""
Write-Host "=== Deploying ===" -ForegroundColor Cyan

if ($App -eq "all") {
  # Deploy functions first (they may be needed by app code)
  firebase deploy --only functions
  # Then deploy all hosting targets
  foreach ($a in $apps) {
    firebase deploy --only hosting:$a
  }
} elseif ($App -eq "functions") {
  firebase deploy --only functions
} else {
  firebase deploy --only hosting:$App
}

Write-Host "=== Done ===" -ForegroundColor Green
