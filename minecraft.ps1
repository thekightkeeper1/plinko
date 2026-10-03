# Minecraft Server Setup Script

# 1. Configuration Variables
$UserName = "MinecraftService"
$Password = ConvertTo-SecureString "ChangeThisPassword123!" -AsPlainText -Force
$DirectoryPath = "C:\MinecraftServer"
$BatchPath = Join-Path -Path$DirectoryPath -ChildPath "start_server.bat"
$TaskName = "MinecraftServerService"

# 2. Create Service User Account
if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $UserName -Password$Password -FullName "Minecraft Service" -Description "Service account for Minecraft Server"
    Write-Host "Created local user '$UserName'."
} else {
    Write-Host "Local user '$UserName' already exists."
}

# 3. Create Directory and Configure Permissions
if (-not (Test-Path -Path $DirectoryPath)) {
    New-Item -ItemType Directory -Path $DirectoryPath | Out-Null
}

$Acl = Get-Acl -Path$DirectoryPath
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($UserName, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl -Path $DirectoryPath -AclObject$Acl

# 4. Create Launch Script
$BatchContent = @"
@echo off
cd /d "$DirectoryPath"
java -Xmx2G -Xms1G -jar server.jar nogui
"@

Set-Content -Path $BatchPath -Value$BatchContent
Write-Host "Created startup script at '$BatchPath'."

# 5. Create and Register Scheduled Task
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatchPath`""
$Principal = New-ScheduledTaskPrincipal -UserId $UserName -LogonType ServiceAccount$Trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask -TaskName $TaskName -Action$Action -Trigger $Trigger -Principal$Principal -Force

Write-Host "Scheduled Task '$TaskName' registered successfully under user '$UserName'."