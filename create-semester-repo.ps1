#----------------------SETUP-------------------------
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$semester = "third-semester"
$beginningDate = Get-Date -Date "01/10/2021"
$endDate = Get-Date -Date "01/01/2022"
$failSafe = $True  #Protection against destructive repo history edition. Check this False if you are certain you now what you are doing

Write-Host "-----------------------SUBREPOSITORIES HISTORY REWRITING---------------------------"
if(-not $failSafe){
    $confirmation = Read-Host "Do you want to change names or dates of imported repositories?"
} else {
    Write-Warning 'History rewriting is blocked by variable "$failSafe", change it if you wish to unlock this functionality'
}

if ($confirmation -eq 'y' -and -not $failSafe) {
    Get-ChildItem -Directory |
    ForEach-Object {
        git --git-dir=$($_.FullName)/.git --work-tree=$($_.FullName) status *>$null #Check if this folder is repository
        if(-Not $?){
            Write-Warning "$($_.FullName) is not a repo, skipping"
            return
        }

        Push-Location
        Set-Location $_.FullName

        git filter-repo --dry-run --force --message-callback "
        print(b'[$($_.Name)] ' + message)
        return b'[$($_.Name)] ' + message"

        $confirmation = Read-Host "Do you want to apply this change?"
        if ($confirmation -eq 'y') {
            git filter-repo --force --message-callback "return b'[$($_.Name)] ' + message"
        }

        $epoch = [Math]::Floor($(Get-Date $endDate -UFormat %s))

        Write-Host "New date: $($endDate) +0100"
        Write-Host "In unix time: $epoch"
        
        $confirmation = Read-Host "Do you want to apply this change?"
        if ($confirmation -eq 'y') {
            git filter-repo --force --commit-callback "
            commit.committer_date = b'$($epoch) +0100'
            commit.author_date = b'$($epoch) +0100'
            "

            $endDate = $endDate.AddDays(1)
        }

        Write-Host "`n`n"
        Pop-Location
    }
}

Write-Host "--------------------------CREATION OF PARENT REPOSITORY------------------------------"
if(Test-Path -Path $semester){
    Remove-Item $semester -Recurse -Force
}

New-Item $semester -ItemType Directory | Out-Null

Push-Location

Set-Location $semester
git init

New-Item README.md | Out-Null

git add .
$env:GIT_COMMITTER_DATE= "$beginningDate +0100"
git commit -m "First commit" --date "$beginningDate +0100"

Get-Content ../README.md | Set-Content .\README.md 

git add .
$env:GIT_COMMITTER_DATE= "$endDate +0100"
git commit -m "Update README" --date "$endDate +0100"

$endDate = Get-Date $endDate -Day 30
Get-ChildItem ../ -Directory |
ForEach-Object {
    if($semester -eq $_.Name) {return} #Skip repo of semester that is worked on

    git --git-dir=$($_.FullName)/.git --work-tree=$($_.FullName) status *>$null #Check if this folder is repository
    if(-Not $?){
        Write-Warning "$($_.FullName) is not a repo, skipping"
        return
    }

    git remote add -f $_.Name $_.FullName
    git merge -s ours --no-commit --allow-unrelated-histories "$($_.Name)/main"
    Read-Host "WAIT------------------------------------------------------------------------------"
    git read-tree --prefix="$($_.Name)/" -u "$($_.Name)/main"
    $env:GIT_COMMITTER_DATE= "$endDate +0100"
    git commit -m "Merge $($_.Name) into $semester" --date "$endDate +0100"
}

git log --oneline --graph --all
Pop-Location
