<#
===========================================================================
Hybrid AD Joined / Domain Joined -> Microsoft Entra ID Join Migration
===========================================================================

Flow:
1. Configure Local Administrator Auto Login
2. Remove Hybrid Entra Join (if present)
3. Create Scheduled Task
4. Unjoin On-Prem AD Domain
5. Reboot
6. Auto Login as Local Administrator
7. Open Entra Join Screen
8. User enters Entra Email + Password + MFA
9. Detect AzureAdJoined = YES
10. Disable Auto Login
11. Remove Scheduled Task
===========================================================================

UPDATE THE VARIABLES BELOW
#>

#-----------------------------
# VARIABLES
#-----------------------------
$DomainAdminUser = "CONTOSO\DomainAdmin"
$DomainAdminPass = "DomainPassword"

$LocalAdminUser  = "Administrator"
$LocalAdminPass  = "LocalAdminPassword"

$TaskName = "OpenEntraJoin"

#-----------------------------
# ENABLE AUTO LOGON
#-----------------------------
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty -Path $RegPath -Name AutoAdminLogon -Value "1"
Set-ItemProperty -Path $RegPath -Name DefaultUserName -Value $LocalAdminUser
Set-ItemProperty -Path $RegPath -Name DefaultPassword -Value $LocalAdminPass
Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $env:COMPUTERNAME

#-----------------------------
# CREATE LOGON SCRIPT
#-----------------------------
$JoinScript = @'
$TaskName = "OpenEntraJoin"

$status = dsregcmd /status | Out-String

if ($status -match "AzureAdJoined\s*:\s*YES")
{
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    try
    {
        Set-ItemProperty -Path $RegPath -Name AutoAdminLogon -Value "0"
        Remove-ItemProperty -Path $RegPath -Name DefaultPassword -ErrorAction SilentlyContinue
    }
    catch {}

    try
    {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    catch {}

    exit
}

Start-Process "ms-settings:workplace"
'@

$ScriptPath = "C:\Windows\Temp\OpenEntraJoin.ps1"

$JoinScript | Out-File `
    -FilePath $ScriptPath `
    -Encoding UTF8 `
    -Force

#-----------------------------
# CREATE SCHEDULED TASK
#-----------------------------
try
{
    Unregister-ScheduledTask `
        -TaskName "OpenEntraJoin" `
        -Confirm:$false `
        -ErrorAction SilentlyContinue
}
catch {}

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask `
    -TaskName "OpenEntraJoin" `
    -Action $Action `
    -Trigger $Trigger `
    -RunLevel Highest `
    -Force

#-----------------------------
# REMOVE HYBRID ENTRA JOIN
#-----------------------------
Write-Host "Checking Hybrid Join Status..."

$DsregStatus = dsregcmd /status | Out-String

if ($DsregStatus -match "AzureAdJoined\s*:\s*YES")
{
    Write-Host "Hybrid Entra Join detected."
    Write-Host "Executing dsregcmd /leave..."

    dsregcmd /leave

    Start-Sleep -Seconds 15
}

#-----------------------------
# DOMAIN UNJOIN
#-----------------------------
Write-Host "Removing computer from on-prem AD..."

$SecurePass = ConvertTo-SecureString `
    $DomainAdminPass `
    -AsPlainText `
    -Force

$Credential = New-Object `
    System.Management.Automation.PSCredential `
    ($DomainAdminUser,$SecurePass)

Remove-Computer `
    -UnjoinDomainCredential $Credential `
    -WorkgroupName "WORKGROUP" `
    -Force `
    -Restart