param([string]$DoFile='stata/tests/run_all.do', [string]$StataExe=$env:STATA_EXE)
$ErrorActionPreference='Stop'
if (!$StataExe) {
    $candidate=Get-Command StataSE-64.exe,StataMP-64.exe,Stata-64.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { $StataExe=$candidate.Source }
}
if (!$StataExe) { throw 'Pass -StataExe or set STATA_EXE to your licensed Stata executable.' }
$resolved=(Resolve-Path -LiteralPath $DoFile).Path
$proc=Start-Process -FilePath $StataExe -ArgumentList "/e do `"$resolved`"" -WorkingDirectory (Get-Location).Path -WindowStyle Hidden -PassThru
if (!$proc.WaitForExit(60000)) { Write-Output "Stata still running: PID $($proc.Id)"; exit 2 }
$log=Join-Path (Get-Location) ([IO.Path]::GetFileNameWithoutExtension($DoFile)+'.log')
if (!(Test-Path -LiteralPath $log)) { throw 'Stata did not produce its expected batch log.' }
$errors=Select-String -LiteralPath $log -Pattern '^r\([1-9][0-9]*\);'
if ($errors) { throw "Stata reported an error in $log. Windows process exit codes alone do not verify do-file success." }
Write-Output "Stata exit code: $($proc.ExitCode)"
exit $proc.ExitCode
