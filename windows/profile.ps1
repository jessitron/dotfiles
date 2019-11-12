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

$MyScriptsLocation="$home\dotfiles\windows"

. $MyScriptsLocation\get.ps1