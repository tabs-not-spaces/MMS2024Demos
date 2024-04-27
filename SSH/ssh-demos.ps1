#region install, enable and configure ssh server

# is it already installed?
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# install required components
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# set up service auto start and start service, configure firewall
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service sshd

# default firewall policy doesn't play nicely, or is scoped for domains (not demo friendly)
Get-NetFirewallRule -Name "Open-SSH-Server-In-TCP" | Remove-NetFirewallRule
$fwParams = @{
    
}
New-NetFirewallRule -Name "Open-SSH-Server-In-TCP" -DisplayName "OpenSSH Server" -Enabled true -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4

# configure ssh system-wide configuration
notepad "$($env:programdata)\ssh\ssh_config"

#endregion