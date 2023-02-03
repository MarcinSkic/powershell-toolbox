# Script for mass operations on all repositories in given directory
param ($path)
Push-Location

$gitOperation = Read-Host "Git operation to perform (default: pull)"
$gitOperation = if ($gitOperation -eq "") {"pull"} else {$gitOperation}
Get-ChildItem -Path $path -Directory | 
ForEach-Object {
    Set-Location $_.FullName 

    git status *>$null

    if($?){
        "`nProcessing $($_.FullName)"
        git switch main *>$null
        git $gitOperation
    }

    Set-Location ../
}

Pop-Location