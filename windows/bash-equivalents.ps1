
# do I need to check whether there's already one defined?
function TeachAbout-Touch {
    Write-Host "hey, the Powershell command is New-Item"
    new-item $args
}
Set-Alias -name touch -Value TeachAbout-Touch