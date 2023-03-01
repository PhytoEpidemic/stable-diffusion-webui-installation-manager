Add-Type -AssemblyName System.Windows.Forms

function Get-GraphicsCardVendor {
    $gpuInfo = Get-CimInstance Win32_VideoController
    $vendorId = $gpuInfo.VideoProcessor | Select-String -Pattern "^\w{3}"

    switch ($vendorId.Matches.Value) {
        "ATI" { return "AMD" }
        "NVI" { return "NVIDIA" }
        "Int" { return "Intel" }
        Default { return "Unknown" }
    }
}

Function ChooseFolder($Message) {
    $FolderBrowse = New-Object System.Windows.Forms.OpenFileDialog -Property @{ValidateNames = $false;CheckFileExists = $false;RestoreDirectory = $true;FileName = $Message;}
    $null = $FolderBrowse.ShowDialog()
    $FolderName = Split-Path -Path $FolderBrowse.FileName
    
	return $FolderName
}

Function MakeToolTip ()
{	
	$toolTip = New-Object System.Windows.Forms.ToolTip
	$toolTip.InitialDelay = 10
	$toolTip.AutoPopDelay = 10000
	
	Return $toolTip
}

function Get-Settings {
	[CmdletBinding()]
	param (
	[Parameter(Mandatory = $true)]
	[string] $Argument
	)
	
	$script = (Get-Location).ToString() + "\settingsget.lua"
	$executable = $(Split-Path $script)+"\SDlocalserver.exe"
	$output = & $executable "$script" "$Argument"
	
	if ($output -eq "true") {
		$result = $true
	}
	elseif ($output -eq "false") {
		$result = $false
	}
	else {
		$result = $output
	}
	
	return $result
}

function Remove-NonMatchingCharacter {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FirstString,

        [Parameter(Mandatory=$true)]
        [string]$SecondString
    )

    $minLength = [Math]::Min($FirstString.Length, $SecondString.Length)

    for ($i=0; $i -lt $minLength; $i++) {
        if ($FirstString[$i] -ne $SecondString[$i]) {
            return $FirstString.Substring(0, $i) + $FirstString.Substring($i+1)
        }
    }

    return $FirstString
}

$InstallLocation = Get-Settings("installLocation")
$isLightMode = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"

$form = New-Object System.Windows.Forms.Form
$form.AutoSize = $true
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.Icon = "logo2.ico"
$form.Text = "Stable Diffusion Webui Launcher"
$form.StartPosition = 'CenterScreen'
$form.BackColor = if (-Not $isLightMode) {[System.Drawing.Color]::FromArgb(33, 33, 33)} else {[System.Drawing.SystemColors]::Control}
$form.ForeColor = if (-Not $isLightMode) {[System.Drawing.SystemColors]::Control} else {[System.Drawing.SystemColors]::WindowText}

$OutputPathTextBoxLabel = New-Object System.Windows.Forms.Label
$OutputPathTextBoxLabel.Location = New-Object System.Drawing.Point(10,10)
$OutputPathTextBoxLabel.AutoSize = $true
$OutputPathTextBoxLabel.Text = 'Location:'
$form.Controls.Add($OutputPathTextBoxLabel)

$CMDARGSTextBoxLabel = New-Object System.Windows.Forms.Label
$CMDARGSTextBoxLabel.Location = New-Object System.Drawing.Point(10,60)
$CMDARGSTextBoxLabel.AutoSize = $true
$CMDARGSTextBoxLabel.Text = 'Set command line arguments:'
$form.Controls.Add($CMDARGSTextBoxLabel)

$linkLabel = New-Object System.Windows.Forms.LinkLabel
$linkLabel.Location = New-Object System.Drawing.Point(170,60)
$linkLabel.AutoSize = $true
$linkLabel.BackColor = [System.Drawing.SystemColors]::Control
$linkLabel.Text = " wiki/Command-Line-Arguments-and-Settings"
$linkLabel.Add_Click({
  Start-Process "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Command-Line-Arguments-and-Settings"
})
(MakeToolTip).SetToolTip($linkLabel,"Visit the wiki to see more info about the available command line arguments and settings")
$form.Controls.Add($linkLabel)

$OverwriteModelCheckbox = New-Object System.Windows.Forms.CheckBox
$OverwriteModelCheckbox.Location = New-Object System.Drawing.Point(10,190)
$OverwriteModelCheckbox.Text = "Overwrite models"
$OverwriteModelCheckbox.AutoSize = $true
(MakeToolTip).SetToolTip($OverwriteModelCheckbox,"Overwrite model files if you try to download the same model again.")
$form.Controls.Add($OverwriteModelCheckbox)

$DownloadModelLabel = New-Object System.Windows.Forms.Label
$DownloadModelLabel.Location = New-Object System.Drawing.Point(10,215)
$DownloadModelLabel.AutoSize = $true
$DownloadModelLabel.Text = 'Models to Download: 0GB'
(MakeToolTip).SetToolTip($DownloadModelLabel,"Models will be downloaded before the server starts. Right click the model name to see more info about that model.")
$form.Controls.Add($DownloadModelLabel)

$ModelLabels = @()
$modelInfo = @()
$modelSizes = @()
$modelPages = @()

function AddItemToTables($newLabel, $newModelInfo, $newModelSize, $newModelPage) {
    $global:ModelLabels += $newLabel
    $global:modelInfo += $newModelInfo
    $global:modelSizes += $newModelSize
    $global:modelPages += $newModelPage
}

AddItemToTables "sd-v1-4" "stable diffusion v1.4 base model by CompVis" 4.27 "https://huggingface.co/CompVis/stable-diffusion-v-1-4-original"
AddItemToTables "v1-5-pruned-emaonly" "stable diffusion v1.5 base model by runwayml" 4.27 "https://huggingface.co/runwayml/stable-diffusion-v1-5"
AddItemToTables "sd-vae-ft-mse" "An improved autoencoder by stabilityai" 0.3 "https://huggingface.co/stabilityai/sd-vae-ft-mse"
AddItemToTables "sd-v1-5-inpainting" "Inpainting model by runwayml" 4.27 "https://huggingface.co/runwayml/stable-diffusion-inpainting"
AddItemToTables "512-inpainting-ema" "Inpainting 2 by stabilityai" 5.21 "https://huggingface.co/stabilityai/stable-diffusion-2-inpainting"
AddItemToTables "v2-1_768-nonema-pruned" "stable diffusion v2.1 base model by stabilityai" 5.21 "https://huggingface.co/stabilityai/stable-diffusion-2-1"
AddItemToTables "v2-1_768-ema-pruned" "stable diffusion v2.1 base model by stabilityai" 5.21 "https://huggingface.co/stabilityai/stable-diffusion-2-1"
AddItemToTables "ControlNet" "A bunch of controlnet models" 5.5 "https://huggingface.co/webui/ControlNet-modules-safetensors"
AddItemToTables "instruct-pix2pix" "instruct-pix2pix by timbrooks" 7.7 "https://huggingface.co/timbrooks/instruct-pix2pix"

$gridWidth = 2
$gridHeight = [Math]::Ceiling($ModelLabels.Count / $gridWidth)

$ModelDownloadCheckBoxes = New-Object System.Windows.Forms.CheckBox[] $ModelLabels.Count

$ModelDownloadCheckBoxGrid = New-Object System.Windows.Forms.TableLayoutPanel
$ModelDownloadCheckBoxGrid.RowCount = $gridHeight
$ModelDownloadCheckBoxGrid.ColumnCount = $gridWidth
$ModelDownloadCheckBoxGrid.AutoSize = $true

Function changeGB() {
	$modelGB = 0
	
	for ($i = 0; $i -lt $ModelLabels.Count; $i++) {
		if ($ModelDownloadCheckBoxes[$i].Checked) {
			$modelGB += $modelSizes[$i]
		}
	}
	
	$DownloadModelLabel.Text = 'Models to Download: ' +$modelGB.ToString()+"GB"
}

for ($i = 0; $i -lt $ModelLabels.Count; $i++) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $ModelLabels[$i]
    $checkbox.AutoSize = $true
	(MakeToolTip).SetToolTip($checkbox,$modelInfo[$i])
	$checkbox.Add_Click({changeGB})
    
	$ModelDownloadCheckBoxes[$i] = $checkbox
    $ModelDownloadCheckBoxGrid.Controls.Add($checkbox, $i % $gridWidth, [Math]::Floor($i / $gridWidth))
}

$ModelDownloadCheckBoxGrid.Left = 10
$ModelDownloadCheckBoxGrid.Top = 230

$ModelDownloadCheckBoxes[0].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[0]}})
$ModelDownloadCheckBoxes[1].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[1]}})
$ModelDownloadCheckBoxes[2].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[2]}})
$ModelDownloadCheckBoxes[3].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[3]}})
$ModelDownloadCheckBoxes[4].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[4]}})
$ModelDownloadCheckBoxes[5].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[5]}})
$ModelDownloadCheckBoxes[6].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[6]}})
$ModelDownloadCheckBoxes[7].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[7]}})
$ModelDownloadCheckBoxes[8].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[8]}})

if ((-Not (Test-Path "$InstallLocation\webui\models\Stable-diffusion")) -and (-Not (Test-Path "$InstallLocation\models\Stable-diffusion")))  {
	$ModelDownloadCheckBoxes[1].Checked = $true
} else {
	if (Test-Path "$InstallLocation\webui\models\Stable-diffusion") {
		$ckptFiles = Get-ChildItem -Path "$InstallLocation\webui\models\Stable-diffusion\*.ckpt"
		$safetensorsFiles = Get-ChildItem -Path "$InstallLocation\webui\models\Stable-diffusion\*.safetensors"
		
		if (($safetensorsFiles.Count -eq 0) -and ($ckptFiles.Count -eq 0)) {
			$ModelDownloadCheckBoxes[1].Checked = $true
		}
	} elseif (Test-Path "$InstallLocation\models\Stable-diffusion") {
		$ckptFiles = Get-ChildItem -Path "$InstallLocation\models\Stable-diffusion\*.ckpt"
		$safetensorsFiles = Get-ChildItem -Path "$InstallLocation\models\Stable-diffusion\*.safetensors"
		
		if (($safetensorsFiles.Count -eq 0) -and ($ckptFiles.Count -eq 0)) {
			$ModelDownloadCheckBoxes[1].Checked = $true
		}
	}
}


function Remove-SubstringIfFound {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MainString,

        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )

    if ($MainString.Contains($Pattern)) {
        $MainString = $MainString.Replace($Pattern, "")
        
		return $true, $MainString
    }

    return $false
}


function SaveOptions {
    param(
        [System.Windows.Forms.CheckBox[]]$CheckBoxes,
        [string]$FilePath
    )

    $output = ""

    foreach ($checkbox in $Checkboxes) {
        $output += $checkbox.Text + "=" + $checkbox.Checked.ToString() + "`n"
    }

    $output | Out-File -FilePath $FilePath -Encoding utf8
}

$form.Controls.Add($ModelDownloadCheckBoxGrid)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(450,20)
$textBox.Location = New-Object System.Drawing.Point(10,30)
$textBox.Text = $InstallLocation
(MakeToolTip).SetToolTip($textBox,"If you don't have the webui installed it will be automatically installed in this folder.")
$form.Controls.Add($textBox)

$CMDARGS = New-Object System.Windows.Forms.TextBox
$CMDARGS.Size = New-Object System.Drawing.Size(450,80)
$CMDARGS.Location = New-Object System.Drawing.Point(10,80)
$CMDARGS.Text = (Get-Settings("COMMANDLINE_ARGS"))
if ($CMDARGS.Text -eq "False") {$CMDARGS.Text = ""}
$CMDARGS.Multiline = $true
$CMDARGS.ScrollBars = "Vertical"
$CMDARGS.WordWrap = $true
$CMDARGS.Add_TextChanged({
$CMDARGS.Text = $CMDARGS.Text -replace "`n", " "
})

$form.Controls.Add($CMDARGS)

if (-Not $CMDARGS.Text) {
	$CMDARGS.Text = ("")
}

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.AutoSize = $true
$browseButton.Location = New-Object System.Drawing.Point(100,5)
$browseButton.Text = "Browse"
$browseButton.Add_Click({
    $chosen_folder = ChooseFolder -Message "Install Here"
	
	if (-Not ($chosen_folder -eq "")){
		$textBox.Text = $chosen_folder
		
		Get-Settings("installLocation="+$textBox.Text)
		
		$global:InstallLocation = Get-Settings("installLocation")
		$CMDARGS.Text = (Get-Settings("COMMANDLINE_ARGS"))
		
		if ($CMDARGS.Text -eq "False") {$CMDARGS.Text = ""}
	}
	
	
	for ($i = 0; $i -lt $CMDARGlabels.Count; $i++) {
		$checkbox = $CMDARGSCheckBoxes[$i]
		$FoundInArgs = $false
		
		if ($CMDARGS.Text -ne "") {
			$FoundInArgs, $NewText = Remove-SubstringIfFound -MainString $CMDARGS.Text -Pattern $CMDARGCom[$i]
		}
		
		if ($FoundInArgs) {
			$CMDARGS.Text = $NewText
			$checkbox.Checked = $true
		}
	}
})

$form.Controls.Add($browseButton)

$settingsButtonX = 480
$settingsButtonY = 55

$cpuOnlySettingsButton = New-Object System.Windows.Forms.Button
$cpuOnlySettingsButton.AutoSize = $true
$cpuOnlySettingsButton.Location = New-Object System.Drawing.Point(($settingsButtonX),($settingsButtonY))
$cpuOnlySettingsButton.Text = "CPU settings"
$cpuOnlySettingsButton.Add_Click({
	$CMDARGSCheckBoxes[0].Checked = $false
	$CMDARGSCheckBoxes[1].Checked = $false
	$CMDARGSCheckBoxes[2].Checked = $true
	$CMDARGSCheckBoxes[3].Checked = $true
	$CMDARGSCheckBoxes[4].Checked = $true
})

(MakeToolTip).SetToolTip($cpuOnlySettingsButton,"Add recommended settings for running on a CPU: --skip-torch-cuda-test --use-cpu all --precision full --no-half")
$form.Controls.Add($cpuOnlySettingsButton)

$gpuSettingsButton = New-Object System.Windows.Forms.Button
$gpuSettingsButton.AutoSize = $true
$gpuSettingsButton.Location = New-Object System.Drawing.Point(($settingsButtonX+80),($settingsButtonY))
$gpuSettingsButton.Text = "GPU Settings"
$gpuSettingsButton.Add_Click({
	$CMDARGSCheckBoxes[0].Checked = $true
	$CMDARGSCheckBoxes[1].Checked = $false
	$CMDARGSCheckBoxes[2].Checked = $false
	$CMDARGSCheckBoxes[3].Checked = $false
	$CMDARGSCheckBoxes[4].Checked = $false
})

(MakeToolTip).SetToolTip($gpuSettingsButton,"Add recommended settings for running on a GPU: --xformers --no-half")
$form.Controls.Add($gpuSettingsButton)

$CMDARGlabels = @()
$CMDARGInfo = @()
$CMDARGCom = @()

function AddItemToArgTables($newLabel, $newCMDARGInfo, $newCMDARGCom) {
    $global:CMDARGlabels += $newLabel
    $global:CMDARGInfo += $newCMDARGInfo
    $global:CMDARGCom += $newCMDARGCom
}

AddItemToArgTables "Enable xformers" "Enable xformers for cross attention layers, this reduces vram usage and can have great speed increases" "--xformers"
AddItemToArgTables "Low vram (<8GB)" "Enable stable diffusion model optimizations for sacrificing a little speed for lower vram usage" "--medvram"
AddItemToArgTables "No Half" "Do not switch the model to 16-bit floats (necessary for training but will slow down generations)" "--no-half"
AddItemToArgTables "CPU Only" "Use CPU as torch device for all modules" "--use-cpu all"
AddItemToArgTables "Full precision" "Evaluate at full precision (Needed for CPU only processing)" "--precision full"
AddItemToArgTables "Open in browser" "Open the webui URL in the system's default browser upon launch" "--autolaunch"
AddItemToArgTables "Enable API" "launch webui with API" "--api"
AddItemToArgTables "API logging" "Enable logging of all API requests" "--api-log"
AddItemToArgTables "No Webui" "Only launch the API, without the UI" "--nowebui"

$gridWidth = 2
$gridHeight = [Math]::Ceiling($CMDARGlabels.Count / $gridWidth)

$CMDARGSCheckBoxes = New-Object System.Windows.Forms.CheckBox[] $CMDARGlabels.Count

$CMDARGSCheckBoxGrid = New-Object System.Windows.Forms.TableLayoutPanel
$CMDARGSCheckBoxGrid.RowCount = $gridHeight
$CMDARGSCheckBoxGrid.ColumnCount = $gridWidth
$CMDARGSCheckBoxGrid.AutoSize = $true

for ($i = 0; $i -lt $CMDARGlabels.Count; $i++) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $CMDARGlabels[$i]
    $checkbox.AutoSize = $true
    $FoundInArgs, $NewText = Remove-SubstringIfFound -MainString $CMDARGS.Text -Pattern $CMDARGCom[$i]
	$checkbox.Checked = $FoundInArgs
	
	if ($FoundInArgs) {
		$CMDARGS.Text = $NewText
	}
	
	(MakeToolTip).SetToolTip($checkbox,$CMDARGInfo[$i])
    $CMDARGSCheckBoxes[$i] = $checkbox
    $CMDARGSCheckBoxGrid.Controls.Add($checkbox, $i % $gridWidth, [Math]::Floor($i / $gridWidth))
}

$CMDARGSCheckBoxGrid.Left = 460
$CMDARGSCheckBoxGrid.Top = 80

$form.Controls.Add($CMDARGSCheckBoxGrid)

$ButtonX = 500
$ButtonY = 180

$startServerButton = New-Object System.Windows.Forms.Button
$startServerButton.Size = New-Object System.Drawing.Size(140,60)
$startServerButton.Location = New-Object System.Drawing.Point(($ButtonX),($ButtonY+40))
$startServerButton.Text = "Start Server"
(MakeToolTip).SetToolTip($startServerButton,"Installation and updates will happen before the server starts. First launch of the server will download and install additional dependencies (~7GB)")
$startServerButton.Add_Click({
	
	for ($i = 0; $i -lt $CMDARGlabels.Count; $i++) {
		$checkbox = $CMDARGSCheckBoxes[$i]
		$FoundInArgs = $false
		if ($CMDARGS.Text -ne "") {
			$FoundInArgs, $NewText = Remove-SubstringIfFound -MainString $CMDARGS.Text -Pattern $CMDARGCom[$i]
		}
		if ($checkbox.Checked -and (-Not $FoundInArgs)) {
			$CMDARGS.Text = $CMDARGS.Text+" "+$CMDARGCom[$i]
		}
	}
	
	if ((-Not (Get-GraphicsCardVendor -eq "NVIDIA")) -and ($CMDARGS.Text -notlike "*--skip-torch-cuda-test*")) {
        $CMDARGS.Text = $CMDARGS.Text + " --skip-torch-cuda-test"
    }
	
	Set-Content -Path "GUI_output.txt" -Value (
		"installLocation="+$textBox.Text+
		"`nCOMMANDLINE_ARGS="+$CMDARGS.Text+
		"`nOverwriteModels=" +$OverwriteModelCheckbox.Checked.ToString()+
		"`nGIT_PULL=" +$GitPullCheckbox.Checked.ToString()+
		"`nOpenWindow=" +$OpenWindowCheckbox.Checked.ToString()
	)
	
	SaveOptions -CheckBoxes $ModelDownloadCheckBoxes -FilePath "models_download.txt"
    
	$form.Close()
})

$form.Controls.Add($startServerButton)

$GitPullCheckbox = New-Object System.Windows.Forms.CheckBox
$GitPullCheckbox.Location = New-Object System.Drawing.Point(($ButtonX),($ButtonY+110))
$GitPullCheckbox.Text = "Update to latest"
$GitPullCheckbox.AutoSize = $true
(MakeToolTip).SetToolTip($GitPullCheckbox,"Perform a git pull to get the latest code from AUTOMATIC1111/stable-diffusion-webui (extensions will be updated as well)")
$GitPullCheckbox.Checked = Get-Settings "GIT_PULL"
$form.Controls.Add($GitPullCheckbox)

$OpenWindowCheckbox = New-Object System.Windows.Forms.CheckBox
$OpenWindowCheckbox.Location = New-Object System.Drawing.Point(($ButtonX),($ButtonY+130))
$OpenWindowCheckbox.Text = "Open app window"
$OpenWindowCheckbox.AutoSize = $true
(MakeToolTip).SetToolTip($OpenWindowCheckbox,"Open a separate dedicated window for the webui.")
$OpenWindowCheckbox.Checked = Get-Settings "OpenWindow"
$form.Controls.Add($OpenWindowCheckbox)

$form.Topmost = $true
$form.ShowDialog()
