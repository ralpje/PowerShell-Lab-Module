#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor install script' -ForegroundColor Yellow

Write-Host "'$($psversiontable.psversion)' installed." -ForegroundColor Yellow

#---------------------------------# 
# Install NuGet                   # 
#---------------------------------# 
Write-Host 'Installing NuGet PackageProvide'
$pkg = Install-PackageProvider -Name NuGet -Force
Write-Host "Installed NuGet version '$($pkg.version)'" 
#---------------------------------# 
# Install Pester                  # 
#---------------------------------# 
Write-Host 'Installing Pester'
Install-Module -Name Pester -Repository PSGallery -Force

#---------------------------------# 
# Install PSScriptAnalyzer        # 
#---------------------------------# 
Write-Host 'Installing PSScriptAnalyzer'
Install-Module PSScriptAnalyzer -Repository PSGallery -Force

#---------------------------------# 
# Install Hyper-V & PoSH Mods     # 
#---------------------------------# 
Write-Host 'Installing Hyper-V and PowerShell modules'
Install-WindowsFeature –Name Hyper-V -IncludeManagementTools