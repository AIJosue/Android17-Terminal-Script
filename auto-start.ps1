# 1. Install ADB and platform tools
winget install --id Google.PlatformTools --source winget --accept-package-agreements --accept-source-agreements

# 2. ADB Port Forwarding
Write-Host "Configuring ADB port forwarding..."
# Use ping or adb commands to check if ADB is available and wait for device connection.
# Before executing ADB forwarding, make sure your Android device is connected to the PC via USB and USB debugging is enabled.
# This script assumes ADB is already working properly. If not, you may need to run `adb devices` once manually to authorize.
try {
    adb forward tcp:5901 tcp:5901
    Write-Host "Port forwarding successful: 5901 -> 5901"
} catch {
    Write-Error "ADB port forwarding failed. Please make sure ADB environment variables are configured, and the device is connected and authorized."
    # If port forwarding fails, you can choose to exit the script
    # exit
}

# 3. Install TigerVNC Viewer
winget install --id TigerVNC.TigerVNC --source winget --accept-package-agreements --accept-source-agreements

# 4. Add TigerVNC directory to PATH environment variable (effective for current session only)
$env:Path += ";C:\Program Files\TigerVNC\"

# 5. Run VNC Viewer
Write-Host "Launching VNC Viewer..."
# Before running, make sure the VNC server is running on your target device and listening on port 5901.
# The script will wait for the user to press any key before launching VNC Viewer, giving time to verify or prepare.
Read-Host "Please ensure the VNC server is running on your Android device, then press Enter to launch VNC Viewer..."
vncviewer.exe 127.0.0.1::5901

Write-Host "Script execution completed."
