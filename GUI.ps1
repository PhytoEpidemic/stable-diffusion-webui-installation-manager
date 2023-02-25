Add-Type -AssemblyName System.Windows.Forms

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
# Set the text of the tooltip
	
Return $toolTip
}

function Run-LuaScript {
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



$InstallLocation = Run-LuaScript("installLocation")

$form = New-Object System.Windows.Forms.Form
$form.AutoSize = $true
$form.Text = "File Browser"
 $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
 $form.MaximizeBox = $false
 $form.Icon = "logo2.ico"
 $form.Text = "SDlocalserver"
 $form.StartPosition = 'CenterScreen'

$OutputPathTextBoxLabel = New-Object System.Windows.Forms.Label
$OutputPathTextBoxLabel.Location = New-Object System.Drawing.Point(10,10)
$OutputPathTextBoxLabel.AutoSize = $true
$OutputPathTextBoxLabel.Text = 'Choose the installation location:'
$form.Controls.Add($OutputPathTextBoxLabel)

$GitPullCheckbox = New-Object System.Windows.Forms.CheckBox
$GitPullCheckbox.Location = New-Object System.Drawing.Point(180,10)
$GitPullCheckbox.Text = "Update to latest"
$GitPullCheckbox.AutoSize = $true
(MakeToolTip).SetToolTip($GitPullCheckbox,"Perform a git pull to get the latest code from AUTOMATIC1111/stable-diffusion-webui (extensions will be updated as well)")
$GitPullCheckbox.Checked = Run-LuaScript "GIT_PULL"
$form.Controls.Add($GitPullCheckbox)

$CMDARGSTextBoxLabel = New-Object System.Windows.Forms.Label
$CMDARGSTextBoxLabel.Location = New-Object System.Drawing.Point(10,60)
$CMDARGSTextBoxLabel.AutoSize = $true
$CMDARGSTextBoxLabel.Text = 'Set command line arguments:'
$form.Controls.Add($CMDARGSTextBoxLabel)

$linkLabel = New-Object System.Windows.Forms.LinkLabel
$linkLabel.Location = New-Object System.Drawing.Point(10,170)
$linkLabel.AutoSize = $true
$linkLabel.Text = "wiki/Command-Line-Arguments-and-Settings"
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

$modelGB = 0

$DownloadModelLabel = New-Object System.Windows.Forms.Label
$DownloadModelLabel.Location = New-Object System.Drawing.Point(10,215)
$DownloadModelLabel.AutoSize = $true
$DownloadModelLabel.Text = 'Download Models: ' +$modelGB.ToString()+"GB"
(MakeToolTip).SetToolTip($DownloadModelLabel,"Models will be downloaded before the server starts. Right click the model name to see more info about that model.")
$form.Controls.Add($DownloadModelLabel)


# Define the empty arrays
$labels = @()
$modelInfo = @()
$modelSizes = @()
$modelPages = @()

function AddItemToTables($newLabel, $newModelInfo, $newModelSize, $newModelPage) {
    $global:labels += $newLabel
    $global:modelInfo += $newModelInfo
    $global:modelSizes += $newModelSize
    $global:modelPages += $newModelPage
}


# Add each item to the arrays
AddItemToTables "sd-v1-4" "stable diffusion v1.4 base model" 4.27 "https://huggingface.co/CompVis/stable-diffusion-v-1-4-original"
AddItemToTables "v1-5-pruned-emaonly" "stable diffusion v1.5 base model" 4.27 "https://huggingface.co/runwayml/stable-diffusion-v1-5"
AddItemToTables "wd-v1-3-full" "Waifu Diffusion v1.3 by hakurei" 7.7 "https://huggingface.co/hakurei/waifu-diffusion-v1-3"
AddItemToTables "protogenX53Photorealism_10" "Protogen x5.3 (Photorealism) Official Release by darkstorm2150" 3.97 "https://civitai.com/models/3816/protogen-x53-photorealism-official-release"
AddItemToTables "protogenV22Anime_22" "Protogen v2.2 (Anime) Official Release by darkstorm2150" 3.97 "https://civitai.com/models/3627/protogen-v22-anime-official-release"
AddItemToTables "v2-1_768-nonema-pruned" "stable diffusion v2.1 base model" 5.21 "https://huggingface.co/stabilityai/stable-diffusion-2-1"
AddItemToTables "ControlNet" "A bunch of controlnet models" 5.5 "https://huggingface.co/webui/ControlNet-modules-safetensors"
AddItemToTables "instruct-pix2pix" "instruct-pix2pix by timbrooks" 7.7 "https://huggingface.co/timbrooks/instruct-pix2pix"





$gridWidth = 2
$gridHeight = [Math]::Ceiling($labels.Count / $gridWidth)

$checkboxes = New-Object System.Windows.Forms.CheckBox[] $labels.Count

$grid = New-Object System.Windows.Forms.TableLayoutPanel
$grid.RowCount = $gridHeight
$grid.ColumnCount = $gridWidth
$grid.AutoSize = $true
$xCheckboxOffset = 10  # Horizontal offset in pixels
$yCheckboxOffset = 230  # Vertical offset in pixels
Function changeGB() {
	$modelGB = 0
	for ($i = 0; $i -lt $labels.Count; $i++) {
		if ($checkboxes[$i].Checked) {
			$modelGB += $modelSizes[$i]
		}
	}
	
	$DownloadModelLabel.Text = 'Download Models: ' +$modelGB.ToString()+"GB"
	
}

for ($i = 0; $i -lt $labels.Count; $i++) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $labels[$i]
    $checkbox.AutoSize = $true
	(MakeToolTip).SetToolTip($checkbox,$modelInfo[$i])
	$checkbox.Add_Click({changeGB})
    $checkboxes[$i] = $checkbox
    $grid.Controls.Add($checkbox, $i % $gridWidth, [Math]::Floor($i / $gridWidth))
}

$grid.Left = $xCheckboxOffset  # Set the left offset of the grid
$grid.Top = $yCheckboxOffset  # Set the top offset of the grid





$checkboxes[0].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[0]}})
$checkboxes[1].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[1]}})
$checkboxes[2].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[2]}})
$checkboxes[3].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[3]}})
$checkboxes[4].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[4]}})
$checkboxes[5].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[5]}})
$checkboxes[6].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[6]}})
$checkboxes[7].Add_MouseDown({if ($_.Button -eq 'Right') {Start-Process $modelPages[7]}})


if (-Not (Test-Path "$InstallLocation\webui\models\Stable-diffusion"))  {
	$checkboxes[1].Checked = $true
	
} else {
	$ckptFiles = Get-ChildItem -Path "$InstallLocation\webui\models\Stable-diffusion\*.ckpt"
	$safetensorsFiles = Get-ChildItem -Path "$InstallLocation\webui\models\Stable-diffusion\*.safetensors"
	if (($safetensorsFiles.Count -eq 0) -and ($ckptFiles.Count -eq 0)) {
		$checkboxes[1].Checked = $true
		
	}
}




function SaveOptions {
    param(
        [System.Windows.Forms.CheckBox[]]$CheckBoxes,
        [string]$FilePath
    )

    $output = ""

    foreach ($checkbox in $checkboxes) {
        $output += $checkbox.Text + "=" + $checkbox.Checked.ToString() + "`n"
    }

    $output | Out-File -FilePath $FilePath -Encoding utf8
}





$form.Controls.Add($grid)







$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(450,20)
$textBox.Location = New-Object System.Drawing.Point(10,30)
$textBox.Text = $InstallLocation
$form.Controls.Add($textBox)

$CMDARGS = New-Object System.Windows.Forms.TextBox
$CMDARGS.Size = New-Object System.Drawing.Size(450,80)
$CMDARGS.Location = New-Object System.Drawing.Point(10,80)
$CMDARGS.Text = (Run-LuaScript("COMMANDLINE_ARGS"))
if ($CMDARGS.Text -eq "False") {$CMDARGS.Text = ""}
$CMDARGS.Multiline = $true
$CMDARGS.ScrollBars = "Vertical"
$CMDARGS.WordWrap = $true
$CMDARGS.Add_TextChanged({
$CMDARGS.Text = $CMDARGS.Text -replace "`n", " "
})
#(MakeToolTip).SetToolTip($CMDARGS,"")


$form.Controls.Add($CMDARGS)

if (-Not $CMDARGS.Text) {
	$CMDARGS.Text = ("")
}

$ButtonX = 500
$ButtonY = 30

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Size = New-Object System.Drawing.Size(75,20)
$browseButton.Location = New-Object System.Drawing.Point(($ButtonX),($ButtonY))
$browseButton.Text = "Browse"
$browseButton.Add_Click({
    $chosen_folder = ChooseFolder -Message "Install Here"
	if (-Not ($chosen_folder -eq "")){
		$textBox.Text = $chosen_folder
		Run-LuaScript("installLocation="+$textBox.Text)
		$global:InstallLocation = Run-LuaScript("installLocation")
		$CMDARGS.Text = (Run-LuaScript("COMMANDLINE_ARGS"))
		if ($CMDARGS.Text -eq "False") {$CMDARGS.Text = ""}
	}
})
$form.Controls.Add($browseButton)

$settingsButtonX = 180
$settingsButtonY = 55

$cpuOnlySettingsButton = New-Object System.Windows.Forms.Button
$cpuOnlySettingsButton.AutoSize = $true
$cpuOnlySettingsButton.Location = New-Object System.Drawing.Point(($settingsButtonX),($settingsButtonY))
$cpuOnlySettingsButton.Text = "CPU settings"
$cpuOnlySettingsButton.Add_Click({
    if ($CMDARGS.Text -notlike "*--skip-torch-cuda-test*") {
        $CMDARGS.Text = $CMDARGS.Text + " --skip-torch-cuda-test"
    }
    if ($CMDARGS.Text -notlike "*--use-cpu*") {
        $CMDARGS.Text = $CMDARGS.Text + " --use-cpu all"
    }
    if ($CMDARGS.Text -notlike "*--precision*") {
        $CMDARGS.Text = $CMDARGS.Text + " --precision full"
    }
    if ($CMDARGS.Text -notlike "*--no-half*") {
        $CMDARGS.Text = $CMDARGS.Text + " --no-half"
    }
})
(MakeToolTip).SetToolTip($cpuOnlySettingsButton,"Add default settings for running on a CPU: --skip-torch-cuda-test --use-cpu all --precision full --no-half")
$form.Controls.Add($cpuOnlySettingsButton)


$gpuSettingsButton = New-Object System.Windows.Forms.Button
$gpuSettingsButton.AutoSize = $true
$gpuSettingsButton.Location = New-Object System.Drawing.Point(($settingsButtonX+80),($settingsButtonY))
$gpuSettingsButton.Text = "GPU Settings"
$gpuSettingsButton.Add_Click({
	 if ($CMDARGS.Text -notlike "*--xformers*") {
        $CMDARGS.Text = $CMDARGS.Text + " --xformers"
    }
    if ($CMDARGS.Text -notlike "*--no-half*") {
        $CMDARGS.Text = $CMDARGS.Text + " --no-half"
    }
})
(MakeToolTip).SetToolTip($gpuSettingsButton,"Add default settings for running on a GPU: --xformers --no-half")
$form.Controls.Add($gpuSettingsButton)


$startServerButton = New-Object System.Windows.Forms.Button
$startServerButton.AutoSize = $true
$startServerButton.Location = New-Object System.Drawing.Point(($ButtonX),($ButtonY+80))
$startServerButton.Text = "Start Server"
$startServerButton.Add_Click({
	Set-Content -Path "GUI_output.txt" -Value ("installLocation="+$textBox.Text+"`nCOMMANDLINE_ARGS="+$CMDARGS.Text+"`nOverwriteModels=" +$OverwriteModelCheckbox.Checked.ToString()+"`nGIT_PULL=" +$GitPullCheckbox.Checked.ToString())
	SaveOptions -CheckBoxes $checkboxes -FilePath "models_download.txt"
    $form.Close()
})
$form.Controls.Add($startServerButton)
$form.Topmost = $true
$form.ShowDialog()
