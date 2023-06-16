# Powershell Toolbox

Powershell scripts developed for automating monotonous and/or complicated work.

## Contents

### **libraries.ps1**

Helper script with useful methods.

#### _Contents_

> GetDateUsingCalendar <br>
> Generates calendar form allowing user to easily select date. Based on [Microsoft docs](https://learn.microsoft.com/en-us/powershell/scripting/samples/creating-a-graphical-date-picker?view=powershell-7.3)

### **update-repos.ps1**

Perform one git operation on multiple repos

#### _Description_

Script finds every repository located in subdirectory of current directory (not recursive, one level deep) by checking if `git status` is working there. Omitting any input will default to `pull` operation.

### **create-parent-repo.ps1**

Merge multiple repos as subdirectories of new repo, git friendly way (keeping history)

#### _Synopsis_

```
create-parent-repo.ps1 [-parentRepoName] [-massRename] [-addAllRepos] [-editChildDates] [-editParentDates] [-PSCommonParameters]
```

#### _Description_

Script allows creation of hub repository that contains many smaller repositories while keeping history intact. Also it allows renaming commits of children repositories to make merged history more coherent and simple manipulation with dates of commits. However it is <ins>STRONGLY suggested to keep original history or at the very least leave disclaimer about editing history</ins> `-editChildDates` flag will <ins>change dates in EXISTING repos in subdirectories</ins>, make backup copy<br>
This script works in 3 stages. Assuming all flags are set, on _SETUP_ user is asked to pick start and end date with calendar form and if exists, folder with target repo name is DELETED. Second stage is _SUBREPOSITORIES HISTORY REWRITING_, user has to confirm to enter this section, due to danger of destructive git history rewritting. For each subdirectory of current directory (not recursive) is performed commits name change using `git filter-repo` with pattern: `commit message` -> `[folder-name-of-repo] commit message`. It skips commits with this pattern to avoid multiplying it. Next stage is date edition, also done with `git filter-repo`, where user is asked to confirm changing `author-date` and `commit-date` of all commits to `end-date` selected on _SETUP_. On confirmation it changes history and increments `end-date` by one day. Last stage is _CREATION OF PARENT REPOSITORY_ where final repository is created. First commited is empty README file, then commited are changes copied from current directory README file if it exists. Lastly every children repo is added as subdirectory using these set of commands:

```git
git remote add -f directory-name /directory-path <1>
git merge -s ours --no-commit --allow-unrelated-histories directory-name/main <2>
git read-tree --prefix=directory-name/ -u directory-name/main <3>
git commit -m "Merge directory-name into parent-repo-name" <4>
```

#### _Options_

> -parentRepoName

Name of created parent repository

> -massRename

Skip user confirmation of commits renaming in children repos

> -addAllRepos

Skip user confirmation of adding children repo to parent repo

> -editChildDates

Unlocks option to change dates of children repositories, after user confirmation. User has to make decision for every detected repository

> -editParentDates

Instead of real dates of creation (execution of script), parent repo will have faked dates

---

### Used technologies

[<img align="left" width="26px" alt= "MySQL" src="https://user-images.githubusercontent.com/33003089/214561002-1755201e-fc24-46cb-9463-d3704e1d52eb.svg" style="padding: 0 20px 20px 0"></img>][powershell]

[powershell]: https://en.wikipedia.org/wiki/PowerShell
