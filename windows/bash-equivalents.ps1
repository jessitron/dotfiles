
# do I need to check whether there's already one defined?
function TeachAbout-Touch {
    Write-Host "hey, the Powershell command is New-Item"
    new-item $args
}
Set-Alias -name touch -Value TeachAbout-Touch

function Print-FirstLines { 
    Write-Host "hey, the powershell is cat <file> | select -first 10"
    cat $args | select -first 10
}
Set-Alias -name head -Value Print-FirstLines