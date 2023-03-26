# Set the required paths and icon
$scriptPath = $PSScriptRoot + "\GUI.ps1"
$shortcutPath = $PSScriptRoot + "\shortcut.lnk"
$iconPath = $PSScriptRoot + "\logo2.ico"

# Create a new WScript Shell object
$shell = New-Object -ComObject WScript.Shell

# Create the shortcut object
$shortcut = $shell.CreateShortcut($shortcutPath)

# Set shortcut properties
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$shortcut.IconLocation = $iconPath
$shortcut.WorkingDirectory = (Split-Path $scriptPath)

# Save the shortcut
$shortcut.Save()
