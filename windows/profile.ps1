echo "Good morning!"

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

Function GitPush {
    $PushOutput = "";
    git push 2>&1 | Tee-Object -Variable PushOutput
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