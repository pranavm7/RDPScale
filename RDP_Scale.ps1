# Installing Chocolatey (To get the latest Tailscale version)

$script:executionPolicy = Get-ExecutionPolicy

if ($executionPolicy -eq "Restricted") {
	Write-Host "Current execution policy is set to Restricted, recommended to change to AllSigned\nType: Set-ExecutionPolicy Bypass -Scope Process"
	exit
}

function Install-Chocolatey {
	# Check if Chocolatey is installed
	if (-not (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
	    
	    # Chocolatey is not installed, so we go ahead and install it.
	    # One liner from https://chocolatey.org/install#individual 
	    Write-Host "Chocolatey is not installed. Installing Chocolatey..."
	    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	
	    # Check if Chocolatey installation was successful
	    if (-not (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
	        Write-Host "Chocolatey installation failed. Exiting."
	        exit 1
	    }
	    else {
	        Write-Host "Chocolatey installed successfully."
	    }
	}
}

Write-Host "Chocolatey already installed! Proceeding to install TailScale..."
choco install tailscale -y

# Check if Tailscale is now installed
$tailscaleVersion = (Get-Command "tailscale").FileVersionInfo.ProductVersion
Write-Host "Tailscale is installed. Version: $tailscaleVersion"
