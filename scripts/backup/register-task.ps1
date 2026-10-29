param(
    [string]$Distro = 'Ubuntu-24.04',
    [string]$LinuxUser = 'kelvin',
    [string]$ScriptPath = '/home/kelvin/.local/share/temdas-backup/bin/backup.py',
    [string]$ConfigPath = '/home/kelvin/.config/temdas-backup/config.json',
    [string]$TaskName = 'TEMDAS-PROD-Backup',
    [switch]$Verify
)
$ErrorActionPreference = 'Stop'
# No Windows password or Linux/DB secret is stored in this task definition.
foreach ($value in @($Distro, $LinuxUser, $ScriptPath, $ConfigPath)) {
    if ($value -notmatch '^[a-zA-Z0-9_./-]+$') { throw 'Unsupported argument characters' }
}
$account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$exe = Join-Path $env:WINDIR 'System32\wsl.exe'
$arguments = "--distribution $Distro --user $LinuxUser --exec /usr/bin/python3 $ScriptPath run --config $ConfigPath"
$principal = New-ScheduledTaskPrincipal -UserId $account -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 15) -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$action = New-ScheduledTaskAction -Execute $exe -Argument $arguments
$triggers = @((New-ScheduledTaskTrigger -Daily -At '03:00'), (New-ScheduledTaskTrigger -AtLogOn -User $account))
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.Actions.Count -ne 1 -or $existing.Actions[0].Execute -ne $exe -or $existing.Actions[0].Arguments -ne $arguments) {
        throw 'Existing task differs; no task was overwritten'
    }
} else {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $triggers `
        -Principal $principal -Settings $settings -Description 'Encrypted read-only TEMDAS PROD backup in WSL; UTC retention and missed-run detection.' | Out-Null
}
if ($Verify) {
    # Run one real backup through Task Scheduler, without changing the daily task.
    $testName = "$TaskName-Validation"
    if (Get-ScheduledTask -TaskName $testName -ErrorAction SilentlyContinue) { throw 'Validation task already exists' }
    $testAction = New-ScheduledTaskAction -Execute $exe -Argument "$arguments --force"
    try {
        Register-ScheduledTask -TaskName $testName -Action $testAction -Principal $principal -Settings $settings | Out-Null
        $before = Get-Date
        Start-ScheduledTask -TaskName $testName
        $deadline = (Get-Date).AddMinutes(5)
        do {
            Start-Sleep -Seconds 2
            $info = Get-ScheduledTaskInfo -TaskName $testName
            $task = Get-ScheduledTask -TaskName $testName
        } while (($info.LastRunTime -lt $before.AddSeconds(-2) -or $task.State -eq 'Running') -and (Get-Date) -lt $deadline)
        if ($task.State -eq 'Running' -or $info.LastTaskResult -ne 0) { throw 'Scheduled backup validation failed' }
        @{ registered = $true; validationExit = $info.LastTaskResult; dailyLocalTime = '03:00'; catchUpAtLogon = $true; requiresWindowsLogon = $true } | ConvertTo-Json -Compress
    } finally {
        # Do not delete a still-running task or stop a backup in progress.
        $task = Get-ScheduledTask -TaskName $testName -ErrorAction SilentlyContinue
        if ($task -and $task.State -ne 'Running') { Unregister-ScheduledTask -TaskName $testName -Confirm:$false }
    }
} else {
    @{ registered = $true; dailyLocalTime = '03:00'; requiresWindowsLogon = $true } | ConvertTo-Json -Compress
}
