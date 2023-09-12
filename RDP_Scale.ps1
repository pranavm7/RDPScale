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
	else{ Write-Host "Chocolatey is installed! Proceeding to install TailScale..." }
}

function Install-Tailscale {
	# Checks if tailscale is installed, if not, then installs tailscale using chocolatey.
	if (-not(Test-Path -Path "$env:ProgramData\chocolatey\lib\tailscale")) {
		choco install tailscale -y
	}
	else {
	    Write-Host "Tailscale is installed!"
	}
}

Install-Chocolatey
Install-Tailscale

