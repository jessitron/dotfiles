# Write-Host "be: move to a project directory"

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

        # This returns a PathInfo if it returns anything
        $repopath = Get-ChildItem -Path $codepath | Get-ChildItem -Filter $Project

        if ($repopath.Length -gt 1) {
            Write-Host "I found multiple things!"
            Write-Output ($repopath | Format-List -Property FullName)
            return
        }

        if ($repopath) {
            Write-Host $repopath.GetType()
            Write-Host "Found something"
            Set-Location -Path $repopath.FullName # You have to pass a string
            # I could also do $repopath | Set-Location but that changes my prompt to something weird
            $host.ui.RawUI.WindowTitle = $Project
            return
        }
        
        
        "I don't know where $Project is. Try 'get $Project <github owner>'"       
    }
    
    end {
        
    }
}
Set-Alias -Name be -Value Set-Context