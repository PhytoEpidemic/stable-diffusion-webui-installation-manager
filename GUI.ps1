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


function Get-FilesByPattern {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,

        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )

    $matchingFiles = Get-ChildItem $FolderPath | Where-Object { $_.Name -like "$Pattern*" }

    return $matchingFiles
}

function Get-TargetPath {
    param (
        [string]$SymbolicLinkPath
    )

    $link = Get-Item $SymbolicLinkPath
    if ($link -is [System.IO.FileInfo]) {
        $target = $link.FullName
    } else {
        if ($link.Target) {
			$target = (Get-Item $link.Target).FullName
		} else {
			$target = $SymbolicLinkPath
		}
    }
    return $target
}

$ModelFoldersToRemove = @()
$ReopenModelFolderList = $false

function ModelDirListGUI {
	param (
		[string[]]$FileNames,
		[string]$FolderPath
	)
	$global:ReopenModelFolderList = $false
	$global:ModelFoldersToRemove = @()
	$form = New-Object System.Windows.Forms.Form
	$form.Text = "Extra Model Folders"
	$form.StartPosition = "CenterScreen"
	$form.Topmost = $true
	SetColors($form)
	$form.MaximizeBox = $false
	$form.MinimizeBox = $false
	$form.AutoSize = $true
	
	$form.Icon = "logo2.ico"
	$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
	
	$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
	$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
	$flowLayoutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
	$flowLayoutPanel.AutoSize = $true
	$form.Controls.Add($flowLayoutPanel)

	$textBoxes = New-Object System.Collections.Generic.List[System.Windows.Forms.TextBox]
	$deleteButtons = New-Object System.Collections.Generic.List[System.Windows.Forms.Button]


	foreach ($fileName in $FileNames) {
		
		$label = New-Object System.Windows.Forms.Label
		$label.AutoSize = $true
		$label.Text = Get-TargetPath -SymbolicLinkPath (Join-Path $FolderPath $fileName)
		(MakeToolTip).SetToolTip($label,"The folder location.")
		$flowLayoutPanel.Controls.Add($label)
		$ModelDirLabelTextBox = New-Object System.Windows.Forms.TextBox
		if ($fileName.Contains(".")) {
			$ModelDirLabelTextBox.Text = $fileName.Substring($fileName.IndexOf(".") + 1)
		} else {
			$ModelDirLabelTextBox.Text = $fileName
		}
		$ModelDirLabelTextBox.Width = 300
		(MakeToolTip).SetToolTip($ModelDirLabelTextBox,"Change the label for this folder in the webui.")
		$flowLayoutPanel.Controls.Add($ModelDirLabelTextBox)
		$textBoxes.Add($ModelDirLabelTextBox)
	
		$deleteButton = New-Object System.Windows.Forms.Button
		$deleteButton.Text = "Remove"
		(MakeToolTip).SetToolTip($deleteButton,"Select this folder for removal (Press OK to save the changes)")
		$deleteButton.Width = 75
		$deleteButton.Add_Click({
			$index = $deleteButtons.IndexOf($this)
			$fullPath = Join-Path $FolderPath $FileNames[$index]
			$global:ModelFoldersToRemove += $fullPath
			$textBoxes[$index].ReadOnly = $true
			$textBoxes[$index].ForeColor = [System.Drawing.Color]::FromArgb(169, 169, 169)
			$textBoxes[$index].BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
			$deleteButtons[$index].Enabled = $false
		})
		$flowLayoutPanel.Controls.Add($deleteButton)
		
		$deleteButtons.Add($deleteButton)
		
	}


	Function RemoveModelFolders(){
		for ($j = 0; $j -lt $global:ModelFoldersToRemove.Count; $j++) {
			Remove-SymbolicLink -LinkName $global:ModelFoldersToRemove[$j]
		}
	}
	
	function RenameModelFolders(){
		$i = 0
		foreach ($ModelDirLabelTextBox in $flowLayoutPanel.Controls | Where-Object {$_.GetType().Name -eq "TextBox"}) {
			if ($ModelDirLabelTextBox.Text -ne "") {
				$oldFileName = $FileNames[$i]
				$oldFullPath = Join-Path $FolderPath $oldFileName
				if ($oldFileName.Contains(".")) {
					$Prefix = $oldFileName.Substring(0,$oldFileName.IndexOf(".") + 1)
					$newFileName = $Prefix + $ModelDirLabelTextBox.Text
				} else {
					$newFileName = $ModelDirLabelTextBox.Text
				}
				$newFullPath = Join-Path $FolderPath $newFileName
				if ((Test-Path $oldFullPath) -and ($oldFullPath -ne $newFullPath) -and (-Not (Test-Path $newFullPath))) {
					Rename-Item $oldFullPath $newFullPath
				}
				$FileNames[$i] = $newFileName
			}
			$i++
		}
	}
	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Text = "OK"
	$okButton.Width = 75
	$okButton.Location = New-Object System.Drawing.Point(300,370)
	$okButton.Add_Click({
		RemoveModelFolders
		RenameModelFolders
		
		$form.Close()
	})
	(MakeToolTip).SetToolTip($okButton,"Save new labels and remove selected folders.")
	$AddButton = New-Object System.Windows.Forms.Button
	$AddButton.Text = "Add Folder"
	$AddButton.Width = 75
	$AddButton.Location = New-Object System.Drawing.Point(300,370)
	(MakeToolTip).SetToolTip($AddButton, "Add a folder.")
	$AddButton.Add_Click({
		$ModelDir, $LinkLabel = AddModelFolderInputBox
		if ($LinkLabel -eq "") {$LinkLabel = "extra"}
		if ($ModelDir -and (Test-Path $ModelDir)) {
			$Linkpath = Join-Path -Path $FolderPath -ChildPath "\Stable-diffusion.$LinkLabel"
			$newPath = $false
			$k = 0
			if (Test-Path $Linkpath) {
				
				do {
					$k++
					$newPath = $Linkpath + "_($k)"
				} while (Test-Path $newPath)
			}
			if ($newPath) { $LinkLabel = $LinkLabel + "_($k)" }
			New-SymbolicLink -LinkName "Stable-diffusion.$LinkLabel" -TargetDirectory "$ModelDir" -OutputDirectory "$FolderPath"
			$global:ReopenModelFolderList = $true
			RemoveModelFolders
			RenameModelFolders
			$form.Close()
		}
		
	})
	
	$flowLayoutPanel.Controls.Add($AddButton)
	$flowLayoutPanel.Controls.Add($okButton)
	
	[void]$form.ShowDialog()
	return $global:ReopenModelFolderList
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

function Remove-SymbolicLink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LinkName
    )

    $batFilePath = [System.IO.Path]::GetTempFileName() + ".bat"
    $batContent = "rmdir `"$LinkName`""

    try {
        Set-Content -Path $batFilePath -Value $batContent -Encoding ASCII
        Start-Process -FilePath $batFilePath -Wait -WindowStyle Hidden
    } finally {
        Remove-Item -Path $batFilePath -Force
    }
}


function New-SymbolicLink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LinkName,

        [Parameter(Mandatory=$true)]
        [string]$TargetDirectory,

        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory
    )

    $linkPath = Join-Path -Path $OutputDirectory -ChildPath $LinkName
    $batFilePath = [System.IO.Path]::GetTempFileName() + ".bat"
    $batContent = "mklink /d `"$linkPath`" `"$TargetDirectory`""

    try {
        Set-Content -Path $batFilePath -Value $batContent -Encoding ASCII
        Start-Process -FilePath $batFilePath -Wait -WindowStyle Hidden
        if (-Not (Test-Path $linkPath)) {
			Start-Process -FilePath $batFilePath -Wait -WindowStyle Hidden -Verb RunAs
		}
    } finally {
        Remove-Item -Path $batFilePath -Force
    }
}

function AddModelFolderInputBox {
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	
	$form = New-Object System.Windows.Forms.Form
	$form.Text = "Add Model Folder"
	$form.StartPosition = "CenterScreen"
	$form.Topmost = $true
	SetColors($form)
	$form.MaximizeBox = $false
	$form.MinimizeBox = $false
	$form.AutoSize = $true
	$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
	$iconPath = "logo2.ico"
	$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
	$label = New-Object System.Windows.Forms.Label
	$label.Location = New-Object System.Drawing.Point(10,30)
	$label.AutoSize = $true
	$label.Text = "Location:"
	$form.Controls.Add($label)
	$NewModelDirTextBox = New-Object System.Windows.Forms.TextBox
	$NewModelDirTextBox.Location = New-Object System.Drawing.Point(10,60)
	$NewModelDirTextBox.Size = New-Object System.Drawing.Size(260,20)
	$NewModelDirTextBox.AllowDrop = $true
	(MakeToolTip).SetToolTip($NewModelDirTextBox,"This folder must contain .ckpt files and/or .safetensors files (You can drag and drop the folder into the text box)")
	$NewModelDirTextBox.Add_DragEnter({
		if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
			$files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
			if (Test-Path -Path $files[0] -PathType Container) {
				$_.Effect = [System.Windows.Forms.DragDropEffects]::All
			}
		}
		
	})
	$NewModelDirTextBox.Add_DragDrop({
		if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
			$files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
			if (Test-Path -Path $files[0] -PathType Container) {
				$NewModelDirTextBox.Text = $files[0]
			}
		}
		
	})
	$browseButton = New-Object System.Windows.Forms.Button
	$browseButton.AutoSize = $true
	$browseButton.Location = New-Object System.Drawing.Point(80,30)
	$browseButton.Text = "Browse"
	$browseButton.Add_Click({
		$chosen_folder = ChooseFolder -Message "Add this folder"
		
		if ($chosen_folder -ne ""){
			$NewModelDirTextBox.Text = $chosen_folder
		}

	})
	
	$form.Controls.Add($browseButton)
	
	$form.Controls.Add($NewModelDirTextBox)
	$label = New-Object System.Windows.Forms.Label
	$label.Location = New-Object System.Drawing.Point(10,120)
	$label.AutoSize = $true
	$label.Text = "Custom Label:"
	$form.Controls.Add($label)
	$textBoxLab = New-Object System.Windows.Forms.TextBox
	$textBoxLab.Location = New-Object System.Drawing.Point(10,150)
	$textBoxLab.Size = New-Object System.Drawing.Size(260,20)
	(MakeToolTip).SetToolTip($textBoxLab,"Set a custom label that will show up in the model list in the webui. (Default is 'extra' if left blank)")
	$form.Controls.Add($textBoxLab)
	
	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Point(180,180)
	$okButton.AutoSize = $true
	$okButton.Text = "OK"
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$form.Controls.Add($okButton)
	(MakeToolTip).SetToolTip($okButton,"Add this folder with this label (This will also save new labels and remove selected folders)")
	$form.AcceptButton = $okButton
	
	$result = $form.ShowDialog()
	
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		return $NewModelDirTextBox.Text, $textBoxLab.Text
	}
	
	return $null
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


function SetColors($form){
	$isLightMode = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"
	$form.BackColor = if (-Not $isLightMode) {[System.Drawing.Color]::FromArgb(33, 33, 33)} else {[System.Drawing.SystemColors]::Control}
	$form.ForeColor = if (-Not $isLightMode) {[System.Drawing.SystemColors]::Control} else {[System.Drawing.SystemColors]::WindowText}
}




$InstallLocation = Get-Settings("installLocation")


$form = New-Object System.Windows.Forms.Form
$form.AutoSize = $true
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.Icon = "logo2.ico"
$form.Text = "Stable Diffusion Webui Launcher"
$form.StartPosition = 'CenterScreen'
SetColors($form)
$GUILayout = New-Object System.Windows.Forms.FlowLayoutPanel
$GUILayout.Location = New-Object System.Drawing.Point(5,30)
	$GUILayout.Dock = [System.Windows.Forms.DockStyle]::None
	$GUILayout.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
	$GUILayout.AutoSize = $true
$OutputPathTextBoxLabel = New-Object System.Windows.Forms.Label
$OutputPathTextBoxLabel.AutoSize = $true
$OutputPathTextBoxLabel.Text = 'Location:'


$CMDARGSTextBoxLabel = New-Object System.Windows.Forms.Label
$CMDARGSTextBoxLabel.AutoSize = $true
$CMDARGSTextBoxLabel.Text = 'Set command line arguments:'

$linkLabel = New-Object System.Windows.Forms.LinkLabel
$linkLabel.AutoSize = $true
$linkLabel.Dock = [System.Windows.Forms.DockStyle]::Right
$linkLabel.BackColor = [System.Drawing.SystemColors]::Control
$linkLabel.Text = " wiki/Command-Line-Arguments-and-Settings"
$linkLabel.Add_Click({
  Start-Process "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Command-Line-Arguments-and-Settings"
})
(MakeToolTip).SetToolTip($linkLabel,"Visit the wiki to see more info about the available command line arguments and settings")

$OverwriteModelCheckbox = New-Object System.Windows.Forms.CheckBox
$OverwriteModelCheckbox.Text = "Overwrite models"
$OverwriteModelCheckbox.AutoSize = $true
(MakeToolTip).SetToolTip($OverwriteModelCheckbox,"Overwrite model files if you try to download the same model again.")

$DownloadModelLabel = New-Object System.Windows.Forms.Label
$DownloadModelLabel.AutoSize = $true
$DownloadModelLabel.Text = 'Models to Download: 0GB'
(MakeToolTip).SetToolTip($DownloadModelLabel,"Models will be downloaded before the server starts. Right click the model name to see more info about that model.")

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
AddItemToTables "ControlNet" "A bunch of controlnet models and the webui extension by Mikubill" 5.5 "https://huggingface.co/webui/ControlNet-modules-safetensors"
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


$InstallDirTextBox = New-Object System.Windows.Forms.TextBox
$InstallDirTextBox.Size = New-Object System.Drawing.Size(450,20)
$InstallDirTextBox.AllowDrop = $true
$InstallDirTextBox.Text = $InstallLocation
$InstallDirTextBox.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
        if (Test-Path -Path $files[0] -PathType Container) {
            $_.Effect = [System.Windows.Forms.DragDropEffects]::All
        }
    }
	
})
$InstallDirTextBox.Add_DragDrop({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
        if (Test-Path -Path $files[0] -PathType Container) {
			setInstallLocation $files[0]
        }
    }
	
})
(MakeToolTip).SetToolTip($InstallDirTextBox,"If you don't have the webui installed it will be automatically installed in this folder.")


$CMDARGS = New-Object System.Windows.Forms.TextBox
$CMDARGS.Size = New-Object System.Drawing.Size(450,80)
$CMDARGS.Text = (Get-Settings("COMMANDLINE_ARGS"))
if ($CMDARGS.Text -eq "False") {$CMDARGS.Text = ""}
$CMDARGS.Multiline = $true
$CMDARGS.ScrollBars = "Vertical"
$CMDARGS.WordWrap = $true
$CMDARGS.Add_TextChanged({
$CMDARGS.Text = $CMDARGS.Text -replace "`n", " "
$CMDARGS.Text = $CMDARGS.Text -replace "  ", " "
})



function setInstallLocation($chosen_folder){
	if (-Not ($chosen_folder -eq "")){
		$InstallDirTextBox.Text = $chosen_folder
		
		Get-Settings("installLocation="+$InstallDirTextBox.Text)
		
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
	CleanInstallAvalible
	ModelDirsAvalible
}

function openInExplorer($pathtoopen, $selected) {
	$openFolderLocation = $pathtoopen

	while (!(Test-Path $openFolderLocation)) {
		$openFolderLocation = Split-Path $openFolderLocation -Parent
		if ($openFolderLocation -eq "") {
			Write-Host "No valid path found. Exiting."
			exit
		}
	}
	if ($selected) {
		explorer.exe "/select,`"$openFolderLocation`""
	} else {
		explorer.exe "`"$openFolderLocation`""
	}
	
}


$openInstallFolderButton = New-Object System.Windows.Forms.PictureBox
$openInstallFolderButton.Image = [System.Drawing.Image]::FromFile("folder.png")
$openInstallFolderButton.SizeMode = 'Zoom'
$openInstallFolderButton.Size = New-Object System.Drawing.Size(16, 16)
$openInstallFolderButton.Location = New-Object System.Drawing.Point(60, 30)
$form.Controls.Add($openInstallFolderButton)
(MakeToolTip).SetToolTip($openInstallFolderButton, "Open in explorer.")
$openInstallFolderButton.Add_Click({
	openInExplorer -pathtoopen $InstallLocation -selected $false
})

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.AutoSize = $true
$browseButton.Location = New-Object System.Drawing.Point(100,5)
$browseButton.Text = "Browse"
$browseButton.Add_Click({
    $chosen_folder = ChooseFolder -Message "Install Here"
	setInstallLocation $chosen_folder
	
})

$form.Controls.Add($browseButton)

$CleanInstallOptionLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$CleanInstallOptionLayout.Location = New-Object System.Drawing.Point(200,5)
	$CleanInstallOptionLayout.Dock = [System.Windows.Forms.DockStyle]::None
	$CleanInstallOptionLayout.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
	$CleanInstallOptionLayout.AutoSize = $true
	
$CleanInstallCheckbox = New-Object System.Windows.Forms.CheckBox
$CleanInstallCheckbox.Location = New-Object System.Drawing.Point(200,5)
$CleanInstallCheckbox.Text = "Clean Install"
$CleanInstallCheckbox.AutoSize = $true
$CleanInstallCheckbox.Add_Click({
	if ($CleanInstallCheckbox.Checked) {
		$CleanInstallOptionLayout.Controls.Add($KeepModelsCheckbox)
		$CleanInstallOptionLayout.Controls.Add($KeepOutputsCheckbox)
		$CleanInstallOptionLayout.Controls.Add($KeepExtensionsCheckbox)
		$CleanInstallOptionLayout.Controls.Add($KeepSettingsCheckbox)
		$CleanInstallOptionLayout.Controls.Add($KeepScriptsCheckbox)
		
	} else {
		$CleanInstallOptionLayout.Controls.Remove($KeepModelsCheckbox)
		$CleanInstallOptionLayout.Controls.Remove($KeepOutputsCheckbox)
		$CleanInstallOptionLayout.Controls.Remove($KeepExtensionsCheckbox)
		$CleanInstallOptionLayout.Controls.Remove($KeepSettingsCheckbox)
		$CleanInstallOptionLayout.Controls.Remove($KeepScriptsCheckbox)
	}
	
})
(MakeToolTip).SetToolTip($CleanInstallCheckbox,"Perform a clean install by removing all dependencies and reinstalling them (localizations and textual_inversion_templates will be kept)")
$CleanInstallCheckbox.Checked = $false




$KeepModelsCheckbox = New-Object System.Windows.Forms.CheckBox
$KeepModelsCheckbox.Location = New-Object System.Drawing.Point(290,5)
$KeepModelsCheckbox.Text = "Keep Model Folder"
$KeepModelsCheckbox.AutoSize = $true
$KeepModelsCheckbox.Checked = $true
(MakeToolTip).SetToolTip($KeepModelsCheckbox,"Keep folders with any models intact so you don't lose any of your models (models, embeddings, textual_inversion, textual_inversion_templates).")

$KeepOutputsCheckbox = New-Object System.Windows.Forms.CheckBox
$KeepOutputsCheckbox.Location = New-Object System.Drawing.Point(410,5)
$KeepOutputsCheckbox.Text = "Keep Outputs Folder"
$KeepOutputsCheckbox.AutoSize = $true
$KeepOutputsCheckbox.Checked = $true
(MakeToolTip).SetToolTip($KeepOutputsCheckbox,"Keep the outputs folder so you don't lose images you have generated.")

$KeepExtensionsCheckbox = New-Object System.Windows.Forms.CheckBox
$KeepExtensionsCheckbox.Location = New-Object System.Drawing.Point(410,5)
$KeepExtensionsCheckbox.Text = "Keep Extensions"
$KeepExtensionsCheckbox.AutoSize = $true
$KeepExtensionsCheckbox.Checked = $true
(MakeToolTip).SetToolTip($KeepExtensionsCheckbox,"Keep any extensions you have installed.")

$KeepSettingsCheckbox = New-Object System.Windows.Forms.CheckBox
$KeepSettingsCheckbox.Location = New-Object System.Drawing.Point(410,5)
$KeepSettingsCheckbox.Text = "Keep Settings"
$KeepSettingsCheckbox.AutoSize = $true
$KeepSettingsCheckbox.Checked = $true
(MakeToolTip).SetToolTip($KeepSettingsCheckbox,"Keep all of your settings.")

$KeepScriptsCheckbox = New-Object System.Windows.Forms.CheckBox
$KeepScriptsCheckbox.Location = New-Object System.Drawing.Point(410,5)
$KeepScriptsCheckbox.Text = "Keep Scripts"
$KeepScriptsCheckbox.AutoSize = $true
$KeepScriptsCheckbox.Checked = $true
(MakeToolTip).SetToolTip($KeepScriptsCheckbox,"Keep any custom scripts.")



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
	$GraphicsVender = Get-GraphicsCardVendor
	
	if ($GraphicsVender -eq "NVIDIA") {
		$CMDARGSCheckBoxes[0].Checked = $true
	} else {
		$CMDARGSCheckBoxes[0].Checked = $false
	}
	$CMDARGSCheckBoxes[1].Checked = $false
	if ($GraphicsVender -eq "AMD") {
		$CMDARGSCheckBoxes[2].Checked = $true
	} else {
		$CMDARGSCheckBoxes[2].Checked = $false
	}
	$CMDARGSCheckBoxes[3].Checked = $false
	$CMDARGSCheckBoxes[4].Checked = $false
})

(MakeToolTip).SetToolTip($gpuSettingsButton,"Add recommended settings for running on a GPU: --xformers (NVIDIA) --no-half (AMD)")
$form.Controls.Add($gpuSettingsButton)

$CMDARGlabels = @()
$CMDARGInfo = @()
$CMDARGCom = @()

function AddItemToArgTables($newLabel, $newCMDARGInfo, $newCMDARGCom) {
    $global:CMDARGlabels += $newLabel
    $global:CMDARGInfo += $newCMDARGInfo
    $global:CMDARGCom += $newCMDARGCom
}

AddItemToArgTables "Enable xformers" "Enable xformers for cross attention layers, this reduces vram usage and can have great speed increases (Only work for NVIDIA)" "--xformers"
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
    $FoundInArgs = $false
	if ($CMDARGS.Text -ne "") {
		$FoundInArgs, $NewText = Remove-SubstringIfFound -MainString $CMDARGS.Text -Pattern $CMDARGCom[$i]
	}
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
	
	$GraphicsVender = Get-GraphicsCardVendor
	
	if (($GraphicsVender -ne "NVIDIA") -and ($CMDARGS.Text -notlike "*--skip-torch-cuda-test*")) {
        $CMDARGS.Text = $CMDARGS.Text + " --skip-torch-cuda-test"
    }
	
	Set-Content -Path "GUI_output.txt" -Value (
		"installLocation="+$InstallDirTextBox.Text+
		"`nCOMMANDLINE_ARGS="+$CMDARGS.Text+
		"`nOverwriteModels=" +$OverwriteModelCheckbox.Checked.ToString()+
		"`nGIT_PULL=" +$GitPullCheckbox.Checked.ToString()+
		"`nOpenWindow=" +$OpenWindowCheckbox.Checked.ToString()+
		"`nCLEAN_INSTALL=" +$CleanInstallCheckbox.Checked.ToString()+
		"`nKEEP_MODELS=" +$KeepModelsCheckbox.Checked.ToString()+
		"`nKEEP_OUTPUTS=" +$KeepOutputsCheckbox.Checked.ToString()+
		"`nKEEP_EXTENSIONS=" +$KeepExtensionsCheckbox.Checked.ToString()+
		"`nKEEP_SETTINGS=" +$KeepSettingsCheckbox.Checked.ToString()+
		"`nKEEP_SCRIPTS=" +$KeepScriptsCheckbox.Checked.ToString()
	)
	
	if ($OpenWindowCheckbox.Checked) {
		open_browser_window -browserName $DropDownBox.SelectedItem
	}
	
	SaveOptions -CheckBoxes $ModelDownloadCheckBoxes -FilePath "models_download.txt"
    
	$form.Close()
})

$form.Controls.Add($startServerButton)

$AddModelDirButton = New-Object System.Windows.Forms.Button
$AddModelDirButton.AutoSize = $true
$AddModelDirButton.Text = "Extra Model Folders"
(MakeToolTip).SetToolTip($AddModelDirButton,"Add any folders of models you have that you want to show up in the webui. (Available after first installation)")
$AddModelDirButton.Add_Click({
	$Reopen = $true
	while ($Reopen) {
		if (Test-Path "$InstallLocation\webui\models\Stable-diffusion") {
			$matchingFiles = Get-FilesByPattern -FolderPath "$InstallLocation\webui\models" -Pattern "Stable-diffusion."
			$Reopen = ModelDirListGUI -FileNames $matchingFiles -FolderPath "$InstallLocation\webui\models"
		
		} elseif (Test-Path "$InstallLocation\models\Stable-diffusion") {
			$matchingFiles = Get-FilesByPattern -FolderPath "$InstallLocation\models" -Pattern "Stable-diffusion."
			$Reopen = ModelDirListGUI -FileNames $matchingFiles -FolderPath "$InstallLocation\models"
		}
	}
})



function ModelDirsAvalible() {
	if ((Test-Path "$InstallLocation\webui\models\Stable-diffusion") -or (Test-Path "$InstallLocation\models\Stable-diffusion")) {
		$AddModelDirButton.Enabled = $true
	} else {
		$AddModelDirButton.Enabled = $false
	}
}


function CleanInstallAvalible() {
	if (Test-Path "$InstallLocation\system") {
		$CleanInstallOptionLayout.Controls.Add($CleanInstallCheckbox)
	} else {
		$CleanInstallOptionLayout.Controls.Remove($CleanInstallCheckbox)
	}
}

CleanInstallAvalible
ModelDirsAvalible
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
$GUILayout.Controls.Add($OutputPathTextBoxLabel)
$GUILayout.Controls.Add($InstallDirTextBox)
$GUILayout.Controls.Add($CMDARGSTextBoxLabel)

$GUILayout.Controls.Add($CMDARGS)
$GUILayout.Controls.Add($linkLabel)
$GUILayout.Controls.Add($OverwriteModelCheckbox)
$GUILayout.Controls.Add($DownloadModelLabel)
$GUILayout.Controls.Add($ModelDownloadCheckBoxGrid)




$DropDownBox = New-Object System.Windows.Forms.ComboBox
$DropDownBox.Location = New-Object System.Drawing.Point(($ButtonX),($ButtonY+160))
$DropDownBox.Size = New-Object System.Drawing.Size(150, 20)
$DropDownBox.add_SelectedValueChanged({
	Get-Settings ("BrowserApp="+$DropDownBox.SelectedItem.ToString())
})
$DropDownBox.Add_MouseWheel({
    [System.Windows.Forms.HandledMouseEventArgs]$e = $_
    $e.Handled = $true
})
$selectedBrowser = (Get-Settings "BrowserApp")

$browserPaths = @{
    "Google Chrome"   = @("C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
    "Microsoft Edge"  = @("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
    "Brave Browser"   = @("C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe")
}

function open_browser_window {
    param($browserName)

    $Wundowurl = "http://127.0.0.1:7860"

    foreach ($path in $browserPaths[$browserName]) {
        if (Test-Path $path) {
            Start-Process -FilePath $path -ArgumentList "--app=$Wundowurl"
            break
        }
    }
}



foreach ($browserName in $browserPaths.Keys) {
    foreach ($path in $browserPaths[$browserName]) {
        if (Test-Path $path) {
            $item = $DropDownBox.Items.Add($browserName)
            if ($selectedBrowser -eq $browserName) {
                $DropDownBox.SelectedIndex = $item
            }
            break
        }
    }
}

$OpenWindowCheckbox.Add_Click({
    if ($OpenWindowCheckbox.Checked) {
        $form.Controls.Add($DropDownBox)
    } else {
        $form.Controls.Remove($DropDownBox)
    }
})
if ($OpenWindowCheckbox.Checked) {
	$form.Controls.Add($DropDownBox)
}






$GUILayout.Controls.Add($AddModelDirButton)
$form.Controls.Add($GUILayout)
$form.Controls.Add($CleanInstallOptionLayout)
$form.Topmost = $false
$form.ShowDialog()
