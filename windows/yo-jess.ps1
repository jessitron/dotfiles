Add-Type -AssemblyName System.Windows.Forms 

# there are probably better ways
$MyScriptsLocation = "$home\dotfiles\windows"
function NotifyJess {
  [CmdletBinding()]
  param (
    [Parameter(mandatory)]
    [string]
    $Message,

    [Parameter()]
    [string]
    $Title = "Yo Jess!"
  )
  

  $global:balloon = New-Object System.Windows.Forms.NotifyIcon
  $balloon.Icon = [System.Drawing.Icon]::new("$MyScriptsLocation\cat-yo.ico")
  $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::None 
  $balloon.BalloonTipText = $Message
  $balloon.BalloonTipTitle = $Title
  $balloon.Visible = $true 
  $balloon.ShowBalloonTip(8000)
}

