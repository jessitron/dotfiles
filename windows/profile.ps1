Write-Output "Good morning!"

# Do Things Right
Set-Alias -Name which -Value get-command # there is a 'which' in git bash which is full of shit
$PSDefaultParameterValues['Out-File:Encoding'] = "utf8"

<#
# Open the directory where I edit this configuration
#>
function Open-Dotfiles {
    code $HOME/dotfiles
}
Set-Alias bp Open-Dotfiles

function Prompt {
    # Am I in a git repo?
    $gitpath = git rev-parse --show-toplevel
    if ($LastExitCode -ne 0) {
        # Not a git repo. use the current directory as the prompt
        return (get-location).path + " > ";
    }
    # In a git repo.
    $project = (get-item -path $gitpath).name
    $branch = git rev-parse --abbrev-ref HEAD
    $subdir = (get-location).path.replace(($gitpath | convert-path), "")
    "$project@$branch$subdir > "
}

# ...
Function GitStatus { git status }
Set-Alias gs GitStatus

Function CommitDangit { 
    git add .
    git commit -m "commit, dangit" 
}
Set-Alias c CommitDangit

Function GitPush {
    git push
}
Set-Alias p GitPush

Function ListFilesWithMostRecentAtBottom {
    Get-ChildItem | Sort-Object -Property LastWriteTime
}
Set-Alias ll ListFilesWithMostRecentAtBottom

$MyScriptsLocation = "$home\dotfiles\windows"

. $MyScriptsLocation\get.ps1
. $MyScriptsLocation\be.ps1
. $MyScriptsLocation\fix-stderr.ps1
. $MyScriptsLocation\title.ps1
. $MyScriptsLocation\bash-equivalents.ps1
Function GitPush {
    $PushOutput = "";
    git push 2>&1 | fix-stderr | Tee-Object -Variable PushOutput
    if ($LastExitCode -ne 0) {
        $pwd = (Get-Location).toString()
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("Your push failed in ${pwd}:`n$PushOutput", 0, "Ratfish", 0x1)
    }
    else {
        Write-Host "Good job."
    }
}
Set-Alias push GitPush

<#
Load this file again
#>
Function Load-Profile {
    Write-Output 'Try: . $profile'
}
Set-Alias -Name reload -Value Load-Profile

Function Open-RepositoryOrigin {
    start (git remote get-url origin)
}
Set-Alias -Name gh -Value Open-RepositoryOrigin

. $MyScriptsLocation/renumber-tapas-shots.ps1
Set-Alias -Name number -Value Update-ShotNumbers

Function List-GreedyProcesses {
    (Get-Counter '\Process(*)\% Processor Time').CounterSamples | Where-Object { $_.CookedValue -gt 1 } | sort-object -Property CookedValue
}
Set-Alias -Name top -Value List-GreedyProcesses
