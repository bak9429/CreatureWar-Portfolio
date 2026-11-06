param(
    [string]$RepositoryUrl = '',
    [string]$CloneDir = ''
)

$ErrorActionPreference = 'Stop'
$SourceDir = $PSScriptRoot
$ExpectedRepo = 'CreatureWar-Portfolio'
Write-Host 'Creature War | PUBLIC portfolio auto updater' -ForegroundColor Cyan
Write-Host 'Source files (NO git clone required):' $SourceDir
Write-Host ''

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($gitCommand) {
    $gitExe = $gitCommand.Source
} elseif (Test-Path 'C:\Program Files\Git\cmd\git.exe') {
    $gitExe = 'C:\Program Files\Git\cmd\git.exe'
} else {
    throw 'Git executable is missing. Install Git for Windows and reopen this window: https://git-scm.com/downloads/win'
}

if (-not $RepositoryUrl) {
    $RepositoryUrl = Read-Host 'Paste your EXISTING PUBLIC repository URL, for example https://github.com/YOURNAME/CreatureWar-Portfolio'
}
$RepositoryUrl = $RepositoryUrl.Trim().TrimEnd('/')
if ($RepositoryUrl -notmatch '^https://github\.com/([A-Za-z0-9-]+)/CreatureWar-Portfolio(?:\.git)?$') {
    throw 'Expected an EXISTING HTTPS GitHub repo URL ending in /CreatureWar-Portfolio. Create the PUBLIC repo first at https://github.com/new if it does not exist.'
}
if ($RepositoryUrl -notmatch '\.git$') { $RepositoryUrl += '.git' }
$repoPage = $RepositoryUrl.Substring(0, $RepositoryUrl.Length - 4)
if (-not $CloneDir) { $CloneDir = Join-Path $env:USERPROFILE 'CreatureWar-Portfolio-Git' }

# The source ZIP is NOT a git repository. Clone and update a separate, persistent folder.
if (-not (Test-Path (Join-Path $CloneDir '.git'))) {
    if (Test-Path $CloneDir) {
        $children = @(Get-ChildItem -LiteralPath $CloneDir -Force)
        if ($children.Count -gt 0) {
            throw "The destination exists and is not a git clone: $CloneDir. Nothing was changed. Rename or move that directory, or select a different -CloneDir."
        }
    }
    Write-Host 'Cloning PUBLIC repository to:' $CloneDir
    & $gitExe clone -- $RepositoryUrl $CloneDir
    if ($LASTEXITCODE -ne 0) {
        throw 'git clone failed. Check the URL, repo existence, GitHub permissions and network connection.'
    }
}

$origin = (& $gitExe -C $CloneDir remote get-url origin)
if ($LASTEXITCODE -ne 0) { throw 'Existing clone does not contain origin.' }
$origin = ($origin | Out-String).Trim().TrimEnd('/')
if ($origin -ne $RepositoryUrl) {
    throw "The existing clone points to a different remote ($origin). Expected $RepositoryUrl. Nothing was updated."
}

$remoteMain = @(& $gitExe ls-remote --heads $RepositoryUrl 'refs/heads/main')
if ($LASTEXITCODE -ne 0) { throw 'Unable to check the remote main branch. Check Git authentication or repository URL.' }
$hasRemoteMain = ($remoteMain.Count -gt 0)
$branch = (& $gitExe -C $CloneDir symbolic-ref --quiet --short HEAD)
if ($LASTEXITCODE -ne 0) { throw 'Cannot identify the current branch.' }
$branch = ($branch | Out-String).Trim()
if ($branch -ne 'main') {
    if (-not $hasRemoteMain) {
        & $gitExe -C $CloneDir symbolic-ref HEAD refs/heads/main
        if ($LASTEXITCODE -ne 0) { throw 'Could not set main on an empty repository.' }
    } else {
        throw "The clone branch is '$branch', not main. Check the GitHub default branch before updating."
    }
}

$dirty = @(& $gitExe -C $CloneDir status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Could not read local git status.' }
if ($dirty.Count -gt 0) {
    throw "The existing clone at $CloneDir has local changes. Commit or discard them manually before retrying. No source files were copied."
}

if ($hasRemoteMain) {
    Write-Host 'Pulling remote changes (fast-forward only)...'
    & $gitExe -C $CloneDir pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw 'git pull --ff-only failed. Remote changes may conflict, or authentication is needed. No source files were copied.'
    }
} else {
    Write-Host 'The GitHub repo is empty. Preparing its initial commit.'
    if (-not (Test-Path (Join-Path $SourceDir 'data/species_summary.csv'))) {
        throw 'An empty GitHub repo needs the FULL portfolio ZIP, not UPDATE PATCH. Extract the FULL ZIP and run this script from it.'
    }
}

$files = @(
    'README.md',
    'index.html',
    '.gitignore',
    '.gitattributes',
    '.github/workflows/data-validation.yml',
    'assets/site.css',
    'assets/app.js',
    'assets/data.js',
    'assets/github-cover.svg',
    'data/README.md',
    'data/quadruped_nodes_sample.csv',
    'data/role_paths.csv',
    'data/species_summary.csv',
    'tools/validate_public_data.py',
    'PUBLISH_PUBLIC.bat',
    'PUBLISH_PUBLIC.ps1',
    'docs/architecture.md',
    'docs/design-decisions.md',
    'docs/development-status.md',
    'docs/game-loop.md',
    'docs/game-overview.md',
    'docs/network-architecture.md',
    'docs/one-page-summary.md',
    'docs/war-command-structure.md',
    'docs/publish-guide.md',
    'UPDATE_EXISTING_PUBLIC.ps1',
    'UPDATE_EXISTING_PUBLIC.bat'
)
$available = @()
foreach ($rel in $files) {
    if (Test-Path -LiteralPath (Join-Path $SourceDir $rel)) { $available += $rel }
}
if (-not ($available -contains 'README.md') -or -not ($available -contains 'docs/network-architecture.md')) {
    throw 'This does not look like the expanded PUBLIC portfolio package. Required source documents are missing.'
}

Write-Host ''
Write-Host 'GitHub PUBLIC repository:' $repoPage -ForegroundColor Yellow
Write-Host 'Local clone:' $CloneDir
Write-Host 'Only these portfolio files will be copied:'
foreach ($rel in $available) { Write-Host ('  ' + $rel) }
Write-Host 'Nothing from Unreal sources or other private folders will be uploaded.'
$confirm = Read-Host 'Type UPDATE to copy these files, commit and push to PUBLIC GitHub'
if ($confirm -cne 'UPDATE') { Write-Host 'Canceled. No portfolio files were changed.'; exit 0 }

foreach ($rel in $available) {
    $from = Join-Path $SourceDir $rel
    $to = Join-Path $CloneDir $rel
    $toDir = Split-Path -Path $to -Parent
    if (-not (Test-Path -LiteralPath $toDir)) { New-Item -Path $toDir -ItemType Directory -Force | Out-Null }
    Copy-Item -LiteralPath $from -Destination $to -Force
    & $gitExe -C $CloneDir add -- $rel
    if ($LASTEXITCODE -ne 0) { throw "Could not stage $rel" }
}

& $gitExe -C $CloneDir diff --cached --stat
& $gitExe -C $CloneDir diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host 'No new file changes to commit. Attempting to push any existing local commits.'
} elseif ($LASTEXITCODE -eq 1) {
    $authorName = (& $gitExe -C $CloneDir config user.name | Out-String).Trim()
    $authorEmail = (& $gitExe -C $CloneDir config user.email | Out-String).Trim()
    if (-not $authorName) {
        $authorName = Read-Host 'Git author name (public commit metadata)'
        if (-not $authorName) { throw 'Git author name is required.' }
        & $gitExe -C $CloneDir config user.name $authorName
    }
    if (-not $authorEmail) {
        $authorEmail = Read-Host 'Git author email (use GitHub noreply email if you prefer privacy)'
        if (-not $authorEmail) { throw 'Git author email is required.' }
        & $gitExe -C $CloneDir config user.email $authorEmail
    }
    & $gitExe -C $CloneDir commit -m 'docs: expand game overview gameplay loop and network architecture'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed. Check the local repository status.' }
} else {
    throw 'git diff failed.'
}

& $gitExe -C $CloneDir push origin main
if ($LASTEXITCODE -ne 0) {
    throw "git push failed. Your local commit is safe in $CloneDir; fix authentication and run this script again."
}
Write-Host ''
Write-Host 'SUCCESS: Public portfolio update pushed!' -ForegroundColor Green
Write-Host $repoPage
Write-Host 'Check README.md, docs/game-loop.md and docs/network-architecture.md on GitHub.'
