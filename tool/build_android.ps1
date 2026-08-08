$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutter = Join-Path $projectRoot '.flutter-sdk\bin\flutter.bat'
$javaRoot = Get-ChildItem (Join-Path $projectRoot 'toolchains\jdk17-extracted') -Directory | Select-Object -First 1 -ExpandProperty FullName
$androidRoot = Join-Path $projectRoot 'toolchains\android-sdk'

$env:JAVA_HOME = $javaRoot
$env:ANDROID_HOME = $androidRoot
$env:ANDROID_SDK_ROOT = $androidRoot
$env:Path = (Join-Path $javaRoot 'bin') + ';' + (Join-Path $androidRoot 'platform-tools') + ';' + $env:Path

Push-Location $projectRoot
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed' }
    & $flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
    & $flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk failed' }
} finally {
    Pop-Location
}
