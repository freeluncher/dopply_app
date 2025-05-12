# PowerShell script to organize Flutter project structure according to clean architecture
# Run this script from the root of your project (e.g., e:\Dopply\dopply_app)

# Helper function to create folder if not exists
function Ensure-Folder($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

# Move shared to core
if (Test-Path .\lib\shared) {
    Ensure-Folder .\lib\core
    Move-Item .\lib\shared\* .\lib\core\ -Force
    Remove-Item .\lib\shared -Recurse -Force
}

# Features list
$features = @('admin', 'auth', 'doctor', 'patient')
foreach ($feature in $features) {
    $base = ".\lib\features\$feature"
    if (Test-Path $base) {
        # Create clean arch folders
        Ensure-Folder "$base\data"
        Ensure-Folder "$base\domain"
        Ensure-Folder "$base\presentation"
        Ensure-Folder "$base\presentation\pages"
        Ensure-Folder "$base\presentation\widgets"
        Ensure-Folder "$base\presentation\viewmodels"
        Ensure-Folder "$base\domain\entities"
        Ensure-Folder "$base\domain\repositories"
        Ensure-Folder "$base\domain\usecases"
        Ensure-Folder "$base\data\datasources"
        Ensure-Folder "$base\data\repositories"
        
        # Move files based on name patterns
        Get-ChildItem $base -File | ForEach-Object {
            $name = $_.Name.ToLower()
            if ($name -like '*page*.dart') {
                Move-Item $_.FullName "$base\presentation\pages\$($_.Name)" -Force
            } elseif ($name -like '*widget*.dart') {
                Move-Item $_.FullName "$base\presentation\widgets\$($_.Name)" -Force
            } elseif ($name -like '*viewmodel*.dart' -or $name -like '*controller*.dart') {
                Move-Item $_.FullName "$base\presentation\viewmodels\$($_.Name)" -Force
            } elseif ($name -like '*model*.dart') {
                Move-Item $_.FullName "$base\domain\entities\$($_.Name)" -Force
            } elseif ($name -like '*usecase*.dart') {
                Move-Item $_.FullName "$base\domain\usecases\$($_.Name)" -Force
            } elseif ($name -like '*repository_impl*.dart') {
                Move-Item $_.FullName "$base\data\repositories\$($_.Name)" -Force
            } elseif ($name -like '*repository.dart') {
                Move-Item $_.FullName "$base\domain\repositories\$($_.Name)" -Force
            } elseif ($name -like '*datasource*.dart') {
                Move-Item $_.FullName "$base\data\datasources\$($_.Name)" -Force
            } elseif ($name -like '*service*.dart') {
                Move-Item $_.FullName "$base\data\datasources\$($_.Name)" -Force
            } elseif ($name -like '*.dart') {
                # Default: move to pages if not matched above
                Move-Item $_.FullName "$base\presentation\pages\$($_.Name)" -Force
            }
        }
        # Move folders if they exist
        $moveMap = @{
            'models' = 'domain\entities'
            'pages' = 'presentation\pages'
            'widgets' = 'presentation\widgets'
            'viewmodel' = 'presentation\viewmodels'
            'viewmodels' = 'presentation\viewmodels'
            'services' = 'data\datasources'
            'utils' = '..\core\utils'
        }
        foreach ($src in $moveMap.Keys) {
            $srcPath = "$base\$src"
            if (Test-Path $srcPath) {
                $dstPath = "$base\$($moveMap[$src])"
                Ensure-Folder $dstPath
                Move-Item "$srcPath\*" $dstPath -Force
                Remove-Item $srcPath -Recurse -Force
            }
        }
    }
}

# Move any remaining shared folders to core
$sharedFolders = @('services', 'utils', 'widgets')
foreach ($folder in $sharedFolders) {
    $src = ".\lib\$folder"
    if (Test-Path $src) {
        Ensure-Folder ".\lib\core\$folder"
        Move-Item "$src\*" ".\lib\core\$folder\" -Force
        Remove-Item $src -Recurse -Force
    }
}

Write-Host "Folder organization complete!" -ForegroundColor Green
