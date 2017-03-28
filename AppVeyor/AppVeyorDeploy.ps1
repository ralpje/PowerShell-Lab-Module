#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor deploy script' -ForegroundColor Yellow

#---------------------------------# 
# Update module manifest          # 
#---------------------------------# 
if ($env:APPVEYOR_REPO_BRANCH -notmatch 'master')
{
    Write-Host "Finished testing of branch: $env:APPVEYOR_REPO_BRANCH - Exiting"
    exit;
}
Write-Host 'Creating new module manifest'
$ModuleManifestPath = Join-Path -path "$pwd" -ChildPath ("$env:ModuleName"+'.psd1')
$ModuleManifest     = Get-Content $ModuleManifestPath -Raw
$a = $ModuleManifest.Split("'",[StringSplitOptions]'RemoveEmptyEntries')

$b = $a[1]

$c = $b.Split(".",[StringSplitOptions]'RemoveEmptyEntries')

[int]$d = $c[1]

$d

$e = $d + 1
[regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'2.$e'") | Out-File -LiteralPath $ModuleManifestPath

$date = get-date -Format dd-MM-yyy

[regex]::replace($ModuleManifest,'(Generated on:)(.*)',"`$1 $date") | Out-File -LiteralPath $ModuleManifestPath

#---------------------------------# 
# Publish to PS Gallery           # 
#---------------------------------# 
$ModulePath = Split-Path $pwd
Write-Host "Adding $ModulePath to 'psmodulepath' PATH variable"
$env:psmodulepath = $env:psmodulepath + ';' + $ModulePath

Write-Host 'Publishing module to Powershell Gallery'
#Uncomment the below line, make sure you set the variables in appveyor.yml
Publish-Module -Name $env:ModuleName -NuGetApiKey $env:NuGetApiKey