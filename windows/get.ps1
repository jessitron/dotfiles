# Does this work?

Write-Host "Hello, World"

<#
.Synopsis

   Clone a repository from GitHub, in the right place, and go there.

.DESCRIPTION

   This function adds two numbers together and returns the sum

.EXAMPLE

   Add-TwoNumbers -a 2 -b 3

   Returns the number 5

.EXAMPLE

   Add-TwoNumbers 2 4

   Returns the number 6

#>
Function GetRepoFromGitHub {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]
        $Repo,

        [Parameter(Mandatory)]
        [string]
        $Owner
    )
    $codepath = "$home\code"

    $ownerpath = Join-Path -Path $codepath -ChildPath $Owner

    $repopath = Join-Path -Path $ownerpath -ChildPath $Repo

    if (!$PSCmdlet.ShouldProcess($repopath)) {
        return
    }

    if (!(Get-Item -Path $ownerpath -ErrorAction SilentlyContinue)) {
        New-Item -Path $codepath -Name $owner -ItemType "directory"
    }

    Set-Location -Path $ownerpath
    Get-Location | Out-Null  
    "okay"
}
Set-Alias get GetRepoFromGitHub