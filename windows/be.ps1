Write-Host "Setting up the 'be' operation"

function Set-Context {
    [CmdletBinding()]
    param (
        [Parameter(mandatory)]
        [string]
        $Project
    )
    
    begin {
        
    }
    
    process {
        $codepath = Join-Path $home "code"

        $repopath = Get-ChildItem -Path $codepath | Get-ChildItem -Filter $Project

        if ($repopath) {
            Write-Host "Found something"
            Set-Location $repopath.FullName
            return
        }
        
        
        "I don't know where $Project is. Try 'get $Project <github owner>'"       
    }
    
    end {
        
    }
}
Set-Alias -Name be -Value Set-Context