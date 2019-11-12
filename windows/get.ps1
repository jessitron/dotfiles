# Does this work?

Write-Host "setting up 'get' operation"

<#
.Synopsis

   Clone a repository from GitHub, in the right place, and go there.

.DESCRIPTION

   This function clones a repository from GitHub in $home/code, in a directory named after the repository owner.
   Then it changes to that directory.

   If the repository already exists there, this function changes to that directory and runs 'git fetch'.

.EXAMPLE

    get -Repo org-visualizer -Owner atomist

    Clones github.com/atomist/org-visualizer to ~/code/atomist/org-visualizer, and changes to that directory.

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
        return;
    }

    if (Get-Item -Path $repopath -ErrorAction SilentlyContinue) {
        Write-Host "You already have $Owner/$Repo.`n"
        Set-Location -Path $repopath
        git fetch
        git status
        return;
    }

    if (!(Get-Item -Path $ownerpath -ErrorAction SilentlyContinue)) {
        New-Item -Path $codepath -Name $Owner -ItemType "directory" | Out-Null
    }
    else {
        Write-Host "Directory for $Owner exists";
    }
    Set-Location -Path $ownerpath

    if (git clone https://github.com/$Owner/$Repo) {
        Set-Location -Path $repopath
    }
    else {
        # TODO: delete newly created owner directory if the clone fails
    }

}
Set-Alias get GetRepoFromGitHub