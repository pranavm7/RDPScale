# RDPScale :rocket:

Securely access your windows machines anywhere in the world over a VPN.

> [!NOTE]
> Compatible with Windows 10 or higher.

## Why? :bulb:

Windows RDP is a great tool to remotely access your Windows machines. However, it is not secure by default. This tool will help you to secure your RDP connections by:

:white_check_mark: Enabling Remote Desktop Protocol (RDP) on your Windows machine.  
:white_check_mark: Installing [TailScale VPN](https://tailscale.com/) on your Windows machine. (Installation via [chocolatey](https://chocolatey.org/) package manager).  
:white_check_mark: Enabling RDP access via the VPN to a single device (Additional devices can be added later)  
:white_check_mark:  Adding additional security settings to your RDP connection. 

## How? :wrench:

### Setting up the device to connect from

- Download the remote desktop connection client for your operating system.
  - [iOS](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
  - [Microsoft](https://apps.microsoft.com/detail/9WZDNCRFJ3PS)  
  - [Linux](https://remmina.org/how-to-install-remmina/)
  - [Android](https://play.google.com/store/apps/details?id=com.microsoft.rdc.android)  
- Download [Tailscale](https://tailscale.com/download) on the device you want to connect **from**.  
  - Sign up for a free account.  

### Setting up the Windows machine to connect to

- Download the [script](https://github.com/pranavm7/RDPScale/blob/main/RDP_Scale.ps1) and run it as an administrator on your windows pc you want to connect **to**. The script will guide you through the setup process.

> [!NOTE]
> Ensure to use the same login account on both the devices.  
---

> [!IMPORTANT]
> I would recommend you to go through the script before running it.
