param([string]$TaskName = 'TEMDAS-PROD-Backup')
$ErrorActionPreference = 'Stop'
$daily = Get-ScheduledTask -TaskName $TaskName
if ($daily.Actions.Count -ne 1 -or $daily.Actions[0].Arguments -notmatch ' run --config ') {
    throw 'Daily action differs; no task was changed'
}
$testName = "$TaskName-CopyValidation"
if (Get-ScheduledTask -TaskName $testName -ErrorAction SilentlyContinue) { throw 'Validation task already exists' }
$argsCopy = $daily.Actions[0].Arguments -replace ' run --config ', ' copy --config '
$action = New-ScheduledTaskAction -Execute $daily.Actions[0].Execute -Argument $argsCopy
try {
    Register-ScheduledTask -TaskName $testName -Action $action -Principal $daily.Principal -Settings $daily.Settings | Out-Null
    $before = Get-Date
    Start-ScheduledTask -TaskName $testName
    $deadline = (Get-Date).AddMinutes(3)
    do {
        Start-Sleep -Seconds 2
        $info = Get-ScheduledTaskInfo -TaskName $testName
        $task = Get-ScheduledTask -TaskName $testName
    } while (($info.LastRunTime -lt $before.AddSeconds(-2) -or $task.State -eq 'Running') -and (Get-Date) -lt $deadline)
    if ($task.State -eq 'Running' -or $info.LastTaskResult -ne 0) { throw 'Scheduled copy validation failed' }
    @{copyOnly=$true;validationExit=$info.LastTaskResult;dailyTaskUnchanged=$true} | ConvertTo-Json -Compress
} finally {
    $task = Get-ScheduledTask -TaskName $testName -ErrorAction SilentlyContinue
    if ($task -and $task.State -ne 'Running') { Unregister-ScheduledTask -TaskName $testName -Confirm:$false }
}
