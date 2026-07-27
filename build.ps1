# Rebuild Narcotics.dll against the local RimWorld install.
$ErrorActionPreference = "Stop"

$managed = "C:\Program Files (x86)\Steam\steamapps\common\Rimworld\RimWorld\RimWorldWin64_Data\Managed"
$cscCandidates = @(
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe",
    "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\Roslyn\csc.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\Roslyn\csc.exe"
)
$csc = $cscCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) { throw "csc.exe not found. Install Visual Studio Build Tools / .NET desktop workload." }

$netstandard = @(
    "$managed\netstandard.dll",
    "C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7.2\Facades\netstandard.dll"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $root "Assemblies\Narcotics.dll"
New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null

$sources = @(Get-ChildItem (Join-Path $root "Source") -Filter *.cs | ForEach-Object { $_.FullName })
if (-not $sources -or $sources.Count -eq 0) { throw "No Source\*.cs files found." }

$refs = @(
    "/reference:$managed\Assembly-CSharp.dll",
    "/reference:$managed\UnityEngine.CoreModule.dll",
    "/reference:$managed\UnityEngine.dll",
    "/reference:$managed\UnityEngine.IMGUIModule.dll",
    "/reference:$managed\UnityEngine.TextRenderingModule.dll"
)
if ($netstandard) { $refs += "/reference:$netstandard" }

& $csc /nologo /target:library /optimize+ /langversion:latest /out:$out @refs @sources

if ($LASTEXITCODE -ne 0) { throw "Compile failed with exit $LASTEXITCODE" }
Get-Item $out | Format-List FullName, Length, LastWriteTime
Write-Host "Build OK."
