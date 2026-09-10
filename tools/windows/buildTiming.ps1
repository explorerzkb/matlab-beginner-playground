$ErrorActionPreference='Stop'
$compilerPath=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$projectPath=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$outputPath=Join-Path $projectPath 'src/native/MatlabHiTiming.dll'
New-Item -ItemType Directory (Split-Path $outputPath -Parent) -Force | Out-Null
& $compilerPath /nologo /target:library /optimize+ "/out:$outputPath" (Join-Path $PSScriptRoot 'HighResolutionWaiter.cs')
if($LASTEXITCODE -ne 0){throw 'Timing assembly compilation failed'}
