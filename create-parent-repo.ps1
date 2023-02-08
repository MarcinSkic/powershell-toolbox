param(
    [Parameter(Mandatory=$True)]
    [String] $parentRepoName,
    [switch] $massRename,
    [switch] $addAllRepos,
    [switch] $editChildDates,
    [switch] $editParentDates
)

Write-Host "-----------------------SETUP---------------------------"
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
. "libraries.ps1"

if($editChildDates -or $editParentDates){
    $beginningDate = GetDateUsingCalendar "Start date"
    $endDate = GetDateUsingCalendar "End date"

    if(-not $beginningDate -or -not $endDate){
        Write-Error "Dates wheren't selected but flags for date edition where set"
        exit
    }

    if($beginningDate -gt $endDate){
        Write-Error "Start date is after end date!"
        exit
    }
}
$protectChildrenDates = -not $editChildDates #Protection against destructive repo history edition.

if(Test-Path -Path $parentRepoName){
    Remove-Item $parentRepoName -Recurse -Force
}
Write-Host "-----------------------SUBREPOSITORIES HISTORY REWRITING---------------------------"

$confirmation = Read-Host "Do you want to change names or dates of imported repositories?"
if ($confirmation -eq 'y') {
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
        if(not b'[$($_.Name)]' in message):
            print(b'[$($_.Name)] ' + message)
            return b'[$($_.Name)] ' + message
        else:
            print(b'|NO CHANGE| ' + message)
            return message
        "

        if(-not $massRename){
            $confirmation = Read-Host "Do you want to apply this change to [$($_.Name)] repo?"
        }
        if ($confirmation -eq 'y' -or $massRename) {
            git filter-repo --force --message-callback "
            if(not b'[$($_.Name)]' in message):
                return b'[$($_.Name)] ' + message
            else:
                return message
            "
        }
        
        if(-not $protectChildrenDates){
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
        } else {
            Write-Warning 'Child repo date edition blocked. Unlock by setting editChildDates flag'
        }

        Write-Host "`n`n"
        Pop-Location
    }
}

Write-Host "--------------------------CREATION OF PARENT REPOSITORY------------------------------"
New-Item $parentRepoName -ItemType Directory | Out-Null

Push-Location

Set-Location $parentRepoName
git init

New-Item README.md | Out-Null

git add .
if($editParentDates){
    $env:GIT_COMMITTER_DATE= "$beginningDate +0100"
    git commit -m "First commit" --date "$beginningDate +0100"
} else {
    git commit -m "First commit"
}

if(Test-Path -Path ../README.md){
    Get-Content ../README.md | Set-Content .\README.md 
} else {
    Write-Warning "There is no README file to copy content"
}


git add .
if($editParentDates){
    $env:GIT_COMMITTER_DATE= "$endDate +0100"
    git commit -m "Update README" --date "$endDate +0100"
} else {
    git commit -m "Update README"
}

if($editParentDates){
    $endDate = Get-Date $endDate -Day 30
}

Get-ChildItem ../ -Directory |
ForEach-Object {
    if($parentRepoName -eq $_.Name) {return} #Skip repo of parentRepoName that is worked on

    git --git-dir=$($_.FullName)/.git --work-tree=$($_.FullName) status *>$null #Check if this folder is repository
    if(-Not $?){
        Write-Warning "$($_.FullName) is not a repo, skipping"
        return
    }

    if(-not $addAllRepos){
        $confirmation = Read-Host "Do you wish to add $($_.Name) as subdirectory of $parentRepoName repository"
        if ($confirmation -ne 'y') {
            return
        }
    }

    git remote add -f $_.Name $_.FullName
    git merge -s ours --no-commit --allow-unrelated-histories "$($_.Name)/main"
    git read-tree --prefix="$($_.Name)/" -u "$($_.Name)/main"
    if($editParentDates){
        $env:GIT_COMMITTER_DATE= "$endDate +0100"
        git commit -m "Merge $($_.Name) into $parentRepoName" --date "$endDate +0100"
    } else {
        git commit -m "Merge $($_.Name) into $parentRepoName"
    }    
}

git log --oneline --graph --all
Pop-Location
