<#
.Synopsis

   STDERR strings get wrapped in an ErrorRecord. Unwrap those back into strings.

#>
function Convert-StderrString {
    # Why can this not be an advanced function with [CmdletBinding()] ?
    # Somehow it doesn't work if I put that in.
    
    begin {
    }
    
    process {
        if ($PSItem -is [System.Management.Automation.ErrorRecord]) {
            # yeah OK I haven't figured out how to say 'and' yet
            if ($PSItem.FullyQualifiedErrorId -eq "NativeCommandError") {
                if ($PSItem.TargetObject -is [string]) {
                    $PSItem.TargetObject
                    return;
                }
            }
        }
        $PSItem
    }
    
    end {
    }
}
Set-Alias -Name fix-stderr -Value Convert-StderrString