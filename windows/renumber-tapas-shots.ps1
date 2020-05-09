function NumberShots {
    begin {
        $i = 0;
        $ShotPattern = "shot\(\d*\)";
    }
    process {
        if ($_ -match "<!-- ${ShotPattern}.*-->") {
            $i++;
            $_ -replace $ShotPattern, "shot(${i})"
        }
        else { $_ } 
    }
    end {
        Write-Information "Numbered ${i} shots";
    }
}

$InformationPreference = "Continue"

function Update-ShotNumbers {

    Param(
        $Path = ".\episode-script.md"
    )

    process {
        (Get-Content $Path) | NumberShots | Set-Content $Path
    }
}

Write-Host "Defined function Update-ShotNumbers"