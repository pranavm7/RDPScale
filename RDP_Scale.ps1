#Requires -RunAsAdministrator
if ($executionPolicy -eq "Restricted") {
	Write-Host "Current execution policy is set to Restricted, recommended to change to AllSigned`nType: Set-ExecutionPolicy Bypass -Scope Process" -ForegroundColor Yellow
	exit
}
# Script to install and configure RDP over Tailscale


$script:executionPolicy = Get-ExecutionPolicy

# Checks for successful install of tailscale
$script:tailscaleInstall = $False

# Checks if tailscale CLI is available
$script:tailscaleAvailable = $False


# Check and install chocolatey package manager
function Install-Chocolatey {
	# Check if Chocolatey is installed
	if (-not (Test-Path "$env:ProgramData\chocolatey")) {
	    
		# Chocolatey is not installed, so we go ahead and install it.
		# One liner from https://chocolatey.org/install#individual 
		Write-Host "Chocolatey is not installed.`n`nInstalling Chocolatey..."
		Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	
		# Check if Chocolatey installation was successful
		if (-not (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
			Write-Host "`n[!]`tChocolatey installation failed. Exiting." -ForegroundColor Red
			exit 1
		}
		else {
			Write-Host "`n[+]`tChocolatey installed successfully.`n" -ForegroundColor Green
		}
	}
	else { Write-Host "`n[+]`tChocolatey is installed! Proceeding to install TailScale...`n" -ForegroundColor Green }
}

# Install and check Tailscale installation
function Install-Tailscale {
	# Checks if tailscale is installed, if not, then installs tailscale using chocolatey.
	$script:tailscaleInstallCheck = $(Get-Package -Name tailscale -ErrorAction SilentlyContinue)
	if ($tailscaleInstallCheck.Name -ne "Tailscale") {
		choco install tailscale -y
		# Check for successful install
		if ($LASTEXITCODE -eq 0) {
			Write-Host "`n[+]`tTailscale successfully installed!`n" -ForegroundColor Green
		}
		else { 
			Write-Host "`n`n[!]`tTailscale install failed.`nPlease try again using the following command:`n`t choco install tailscale -y`nAlternatively, install tailscale from https://tailscale.com/download/" -ForegroundColor Red
			Write-Host "Exiting...`n"	-ForegroundColor Yellow
			exit 1

		}
	}
	else {
		Write-Host "`n[+]`tTailscale is installed!" -ForegroundColor Green
		Write-Host "`n[+]`tRefreshing powershell..." -ForegroundColor Green
	}
	$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
	if (Test-Path($ChocolateyProfile)) {
		Import-Module "$ChocolateyProfile"
	}
	refreshenv
}

# Check if the tailscale command exists

function Get-TailscaleCli {
	if (-not(Test-Path -Path (Get-Command tailscale -ErrorAction SilentlyContinue))) {
		$script:tailscaleAvailable = $True
	}
	else {
		if ($tailscaleInstall) {
			Write-Host "`n`n[!]`tThe tailscale command is not available but the application is installed.`n Please open the application, finish the setup, and run this script again!`n`nIf this error shows repeatedly, then a reboot is recommended.`n" -ForegroundColor Red
			# exiting as 0 since it is not a script error, but pending configuration changes.
			exit 0
		}
	}
}


function Set-AllowLogin {
	Write-Host "`nTailscale installed! Please start the Tailscale App.`nPress Enter to continue when login is completed on client and this computer"
	$script:temp = Read-Host
	while ($temp -ne "") {
		Write-Host "`nInvalid input. Please press Enter to continue..."
		$script:inp = Read-Host # $inp is a dummy variable to store the input
	}
}

function Set-RDP_Rules {
	if ($tailscaleAvailable) {
	
		# Connect tailscale in case not connected
		if ( -not ($(tailscale status) -like "*NoState*")) {
			tailscale up
		}
		# Prompt the user for client device alias
		Write-Host "`n[Action Required]`n"
		tailscale status
		Write-Host "`nPlease enter the name of the client device" -ForegroundColor Yellow

		Get-ClientIP($remoteClientName)

		# Enable RDP
		# Caution!! this is editing a registry value
		Write-Host "`n[+]`tEnabling RDP...`n" -ForegroundColor Green
		Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

		# Edit firewall to accept connections only from the client device IP
		Write-Host "`n[+]`tConfiguring firewall...`n" -ForegroundColor Green
		Set-NetFirewallRule -Name "RemoteDesktop-UserMode-In-UDP" -Enabled True -RemoteAddress $clientIP
		Set-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" -Enabled True -RemoteAddress $clientIP

		# Getting the rules for additional security settings
		$script:rdp_TCP = Get-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" | Get-NetFirewallSecurityFilter
		$script:rdp_UDP = Get-NetFirewallRule -Name "RemoteDesktop-UserMode-In-UDP" | Get-NetFirewallSecurityFilter

		# Additional security settings
		Write-Host "`n[+]`Configuring additional security settings...`n" -ForegroundColor Green
		Set-NetFirewallSecurityFilter -Authentication Required -Encryption Required -InputObject $rdp_TCP
		Set-NetFirewallSecurityFilter -Authentication Required -Encryption Required -InputObject $rdp_UDP

		# Restart RDP service to set changes
		Restart-Service TermService -ErrorAction SilentlyContinue

		Write-Host "`n[+]`tConfiguration Completed! You can now login as $env:USERDOMAIN\$env:USERNAME"
		Write-Host "`n`nIn case of any difficulties, please consult the README.md file at github.com/pranav-m7/RDPScale"

		exit 0
	}
	else {
		Get-TailscaleCli
	}
}

# Get IP of client
function Get-ClientIP {
	$script:remoteClientName = Read-Host
	$script:deviceInfo = tailscale status | Select-String $remoteClientName
	while ($deviceInfo.length -eq 0 ) {
		Write-Host "`n[!]`tClient device not found. Please check if the client device is connected or name is correctly spelled.`n"
		$script:remoteClientName = Read-Host "Please enter the name of the client device"
		$script:deviceInfo = tailscale status | Select-String $remoteClientName
	}
	$script:deviceInfo = $(tailscale status | Select-String $remoteClientName) -split ' '
	$script:clientIP = $deviceInfo[0]
	Write-Host "`n[+]`tAdding $deviceInfo!`n"
}

# "<Main>" process
Install-Chocolatey
Install-Tailscale
Get-TailscaleCli
Set-AllowLogin
Set-RDP_Rules
