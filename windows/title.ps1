<#
.Synopsis
  Set the title of the terminal tab.
#>
Function Set-Title {
    param(
        [Parameter(Mandatory)]
        [string]
        $NewTitle
    )
    $host.ui.RawUI.WindowTitle = $NewTitle
}
Set-Alias -Name title -Value Set-Title