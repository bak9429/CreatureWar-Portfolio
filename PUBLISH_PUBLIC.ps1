$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$repo = 'CreatureWar-Portfolio'
Write-Host "=================================================="
Write-Host "Creature War - GitHub PUBLIC portfolio publisher"
Write-Host "Only files in: $PSScriptRoot"
Write-Host "Will be uploaded as a PUBLIC GitHub repository."
Write-Host "=================================================="
$required = @('README.md','index.html','data/quadruped_nodes_sample.csv','tools/validate_public_data.py')
foreach ($p in $required) { if (-not (Test-Path $p)) { throw "Missing expected public file: $p" } }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is missing: https://git-scm.com/downloads/win' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is missing: https://cli.github.com/' }
& gh auth status
if ($LASTEXITCODE -ne 0) { throw 'Please run: gh auth login' }
& python tools/validate_public_data.py
if ($LASTEXITCODE -ne 0) { throw 'Public data validation failed.' }
$answer = Read-Host 'Type PUBLISH to create and upload this PUBLIC repository'
if ($answer -cne 'PUBLISH') { Write-Host 'Cancelled.'; exit 0 }
if (-not (Test-Path '.git')) {
    & git init -b main
    if ($LASTEXITCODE -ne 0) { throw 'git init failed' }
}
& git add .
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
& git status --short
$gitName = (& git config user.name)
$gitEmail = (& git config user.email)
if (-not $gitName -or -not $gitEmail) {
    throw 'Set your Git author identity first: git config --global user.name "Your Name" ; git config --global user.email "your@email"'
}
& git diff --cached --quiet
if ($LASTEXITCODE -eq 1) {
    & git commit -m 'docs: publish Creature War portfolio'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
}
$remotes = @(& git remote)
if ($remotes -contains 'origin') {
    Write-Host 'Existing origin remote detected.'
    throw 'For safety, inspect the existing remote and push manually.'
}
& gh repo create $repo --public --source . --remote origin --push
if ($LASTEXITCODE -ne 0) { throw 'Publishing failed. Verify repository state and GitHub login.' }
Write-Host 'Published. Review README and repository visibility in the browser.'
