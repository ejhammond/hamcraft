# Hidden supervisor: launches the server with a held-open stdin (a closed/invalid
# stdin makes the Minecraft server shut itself down right after "Done"), captures
# output to console.log, and exits when the server exits. No visible window.
$serverDir = 'C:\Users\ejh89\mc-server'
$java = 'C:\Users\ejh89\java\jdk-25.0.4.1+1-jre\bin\java.exe'
$jars = Get-ChildItem -Path "$serverDir\libraries" -Recurse -Filter '*.jar' | ForEach-Object { $_.FullName }
$cp = 'fabric-loader-0.19.5.jar;server.jar;' + ($jars -join ';')
$jvmArgs = '-Xms6G -Xmx6G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 ' +
  '-XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch ' +
  '-XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M ' +
  '-XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 ' +
  '-XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 ' +
  '-XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem ' +
  '-XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true ' +
  '-cp "' + $cp + '" net.fabricmc.loader.impl.launch.knot.KnotServer nogui'

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $java
$psi.Arguments = $jvmArgs
$psi.WorkingDirectory = $serverDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true

$outLog = "$serverDir\console.log"
$errLog = "$serverDir\console-err.log"
Set-Content -Path $outLog -Value $null
Set-Content -Path $errLog -Value $null

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$proc.EnableRaisingEvents = $true
Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -MessageData $outLog -Action {
  if ($EventArgs.Data) { Add-Content -Path $Event.MessageData -Value $EventArgs.Data }
} | Out-Null
Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -MessageData $errLog -Action {
  if ($EventArgs.Data) { Add-Content -Path $Event.MessageData -Value $EventArgs.Data }
} | Out-Null

$proc.Start() | Out-Null
$proc.BeginOutputReadLine()
$proc.BeginErrorReadLine()
$stdin = $proc.StandardInput  # held open forever: server never sees stdin EOF
$proc.Id | Out-File "$serverDir\server.pid"
$cmdFile = "$serverDir\stdin-cmd.txt"
if (Test-Path $cmdFile) { Remove-Item $cmdFile -Force }
while (-not $proc.HasExited) {
  # Console bridge: drop commands (one per line) into stdin-cmd.txt and the
  # supervisor forwards them to the server console, then deletes the file.
  if (Test-Path $cmdFile) {
    $lines = @(Get-Content $cmdFile)
    Remove-Item $cmdFile -Force -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
      if ($line.Trim() -ne '') { $stdin.WriteLine($line) }
    }
    $stdin.Flush()
  }
  Start-Sleep -Seconds 3
}
