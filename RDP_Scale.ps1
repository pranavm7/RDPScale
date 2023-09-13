#Requires -RunAsAdministrator

# Change powershell terminal color from blue-yellow
$Host.UI.RawUI.BackgroundColor = 'black'
$Host.UI.RawUI.ForegroundColor = 'white'

$script:executionPolicy = Get-ExecutionPolicy
$script:tailscaleIP_Range= "100.64.0.0/10"

# Checks for successful install of tailscale
$script:tailscaleInstall = $False

# Checks if tailscale CLI is available
$script:tailscaleAvailable = $False


if ($executionPolicy -eq "Restricted") {
	Write-Host "Current execution policy is set to Restricted, recommended to change to AllSigned`nType: Set-ExecutionPolicy Bypass -Scope Process"
	exit
}

# Check and install chocolatey package manager
function Install-Chocolatey {
	# Check if Chocolatey is installed
	if (-not (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
	    
	    # Chocolatey is not installed, so we go ahead and install it.
	    # One liner from https://chocolatey.org/install#individual 
	    Write-Host "Chocolatey is not installed.`n`nInstalling Chocolatey..."
	    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	
	    # Check if Chocolatey installation was successful
	    if (-not (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
	        Write-Host "`n[!]`tChocolatey installation failed. Exiting."
	        exit 1
	    }
	    else {
	        Write-Host "`n[+]`tChocolatey installed successfully.`n"
	    }
	}
	else{ Write-Host "`n[.]`tChocolatey is installed! Proceeding to install TailScale...`n" }
}

# Install and check Tailscale installation
function Install-Tailscale {
	# Checks if tailscale is installed, if not, then installs tailscale using chocolatey.
	if (-not(Test-Path -Path "$env:ProgramData\chocolatey\lib\tailscale")) {
		choco install tailscale -y
		# Check for successful install
		if (-not(Test-Path -Path "$env:ProgramData\chocolatey\lib\tailscale")) {
			Write-Host "`n[+]`tTailscale successfully installed!`n"
			$tailscaleInstall=$True
			}
		else { 
			Write-Host "`n`n[!]`tTailscale install failed.`nPlease try again using the following command:`n`t choco install tailscale -y`nAlternatively, install tailscale from https://tailscale.com/download/"
			Write-Host "Exiting...`n"	
				exit 1

		     }
	}
	else {
	    Write-Host "`n[+]`tTailscale is installed!"
	}
}

# Check if the tailscale command exists

function Check-TailscaleCli {
	if (-not(Test-Path -Path (Get-Command tailscale -ErrorAction SilentlyContinue))){
		$tailscaleAvailable=$True
	}
	else {
		if($tailscaleInstall){
			Write-Host "`n`n[!]`tThe tailscale command is not available but the application is installed.`n Please open the application and finish the setup, and run this script again!`n`nIf this error shows repeatedly, then a reboot is recommended.`n"
			# exiting as 0 since it is not a script error, but pending configuration changes.
			exit 0
		}
	}
}

Install-Chocolatey
Install-Tailscale
Check-TailscaleCli

# Starts Tailscale
if($(tailscale status) -like "*stop*") {
	Write-Host "`n[+]`tRunning TailScale..."
	tailscale up
}

# Prompt the user for client device alias
Write-Host "`n[Action Required]"
$remoteClientName = Read-Host "`nPlease enter the name of the client device"
$deviceInfo = $(tailscale status | Select-String $remoteClientName) -split ' '
$deviceIP = $deviceInfo[0]

# Enable RDP
# ⚠️ Caution this is editing a registry value
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# Edit firewall to accept connections only from the client device IP
Set-NetFirewallRule -Name "RemoteDesktop-UserMode-In-UDP" -Enabled True -RemoteAddress $deviceIP
Set-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" -Enabled True -RemoteAddress $deviceIP

# Restart RDP service to set changes
Restart-Service TermService -ErrorAction SilentlyContinue

Write-Host "`n[+]`tConfiguration Completed! You can now login as $env:USERDOMAIN\$env:USERNAME"
