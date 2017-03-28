# Version 2.4 (27-03-2017)

<#
    .Synopsis
    This module lets you roll out your lab environment automatically. This is the second step: creating a Lab VM's.

    .DESCRIPTION
    This module lets you roll out your lab environment automatically as described in our blogs (www.365dude.nl and www.svenvanrijen.nl).
    This is the second step: creating Lab VM's.
    First step: creating a NATSwitch (New-NATSwitch).

    New-LabVM generates a new VM in the lab environment. 
    IPAddress is a mandatory parameter and must be in the "172.16.10.10/24" notation. 
    Please use the same address space as used when creating the NATSwitch.
    The specification of a Gateway is optional. If DNS-server is not specified, the default will be used. (172.16.10.1)
    The specification of a DNS-server is optional. If DNS-server is not specified, the default will be used. (8.8.8.8)

    For more information or help regarding this module, please visit the GitHub repo: https://github.com/ralpje/PowerShell-Lab-Module

    .EXAMPLE
    New-LabVM -VMName Test -VMIP 10.0.0.18/29 -GWIP 10.0.0.1

    .EXAMPLE
    New-LabVM -VMName Hostname -VMIP 192.168.123.20/24 -DNSIP 192.168.123.5 -GWIP 192.168.123.1
#>
function New-LabVM
{
  [CmdletBinding(
    SupportsShouldProcess = $true
  )]
  [OutputType([String])]
  Param
  ( 
    [Parameter(Mandatory = $true)]
    [string]$VMName,
    
    [Parameter(Mandatory = $false)]
    [int64]$MemoryStartupBytes = 2048MB,
        
    [Parameter(Mandatory = $true)]
    [string]$VMIP,
    
    [Parameter(Mandatory = $false)]
    [string]$GWIP = '172.16.10.1',

    [Parameter(Mandatory = $true)]
    [string]$Diskpath,

    [Parameter(Mandatory = $true)]
    [string]$ParentDisk,

    [Parameter(Mandatory = $true)]
    [string]$VMSwitch,
        
    [Parameter(Mandatory = $false)]
    [string]$DNSIP = '8.8.8.8',
             
    [Parameter(Mandatory = $false)]
    [string]$Unattendloc = 'https://raw.githubusercontent.com/ralpje/PowerShell-Lab-Module/master/Templates/unattend.xml',
    
    [Parameter(Mandatory = $false)]
    [boolean]$DSC = $false,

    [Parameter(Mandatory = $false)]
    [string]$DSCPullConfig,
    
    [Parameter(Mandatory = $false)]
    [boolean]$NestedVirt 
  )

  Begin
  {
  }
  Process
  {
    #region create diff disk
    # Create new differencing disk
    
    $maindiskpath = "$diskpath$VMName.vhdx"
    
    New-VHD -ParentPath $ParentDisk -Path $maindiskpath -Differencing
    
    Write-Verbose -Message "Created a differencing disk $maindiskpath."
    
    Start-Sleep -Seconds 2
    #endregion
  
    #region copy adjusted answer file
    # mount VHD
    $VHD = Mount-VHD -Path $maindiskpath -Passthru

    $x = Get-Disk $vhd.Number |
      Get-Partition |
      Where-Object -FilterScript {
        $_.Type -eq 'Basic'
    }

    Get-Disk $vhd.Number | Set-Disk -IsOffline $false

    Set-Partition -PartitionNumber $x.PartitionNumber -NewDriveLetter T -DiskNumber $x.DiskNumber -ErrorAction SilentlyContinue 

    New-PSDrive -Name T -Root t:\ -PSProvider FileSystem | Out-Null
    
    Write-Verbose -Message 'Differencing disk mounted'
    
    Start-Sleep -Seconds 2
    
    # Copy xml from source to local temp dir
    New-Item -ItemType Directory -Path "$PSScriptRoot\Temp" -Force
    $output = "$PSScriptRoot\temp\unattended.xml"
    Invoke-WebRequest -Uri $unattendloc -OutFile $output
    
    Write-Verbose -Message "Unattended.xml copied from $unattendloc to $PSScriptRoot\Temp."
    
    Start-Sleep -Seconds 2
    
    $SourceXML = "$PSScriptRoot\temp\unattended.xml"
    
    # add XML Content
    [xml]$Unattend = Get-Content $SourceXML
    $Unattend.unattend.settings[1].component[2].ComputerName = $VMName
    $Unattend.unattend.settings[1].component[3].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $VMIP
    $Unattend.unattend.settings[1].component[4].Interfaces.Interface.DNSServerSearchOrder.IpAddress.'#Text' = $DNSIP
    $Unattend.unattend.settings[1].component[3].Interfaces.Interface.Routes.Route.NextHopAddress = $GWIP
    $Unattend.Save("T:\\Unattend.xml")
    
    Write-Verbose -Message "Set VM name to $VMName, IP Address to $VMIP, DNS IP to $DNSIP and GW IP to $GWIP"    
    
    Start-Sleep -Seconds 2
    
    if ($DSC -eq $true)
    {
      # Copy DSC Pull Config to TEMP
      $destps1 = "$PSScriptRoot\temp\DSCPullConfig.ps1"
      Copy-Item -Path $DSCPullConfig -Destination $destps1
      Set-Location -Path "$PSScriptRoot\temp\"
        
      #Edit DSC Pull Config so it will contain the right node-name ($vmname)
      (Get-Content -Path '.\DSCPullConfig.ps1') -replace '\breplace\b', "$VMName" | Out-File -FilePath '.\DSCPullConfig.ps1'
        
      #Kick off DSC Pull Config to generate metamof
      . '.\DSCPullConfig.ps1'
      DscMetaConfigs @Params
             
      $sourcemof = "$PSScriptRoot\temp\DscMetaConfigs\$VMName.meta.mof"
      $destmof = "T:\Windows\system32\Configuration\MetaConfig.mof"
      Move-Item -Path $sourcemof -Destination $destmof -Force

      Write-Verbose -Message "Copied metaconfig.mof to T:\Windows\system32\Configuration\MetaConfig.mof"
      
      reg.exe load HKLM\Vhd T:\Windows\System32\Config\Software
      Set-Location -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies
      Set-ItemProperty -Path . -Name DSCAutomationHostEnabled -Value 2
      [gc]::Collect()
      reg.exe unload HKLM\Vhd
        
      Write-Verbose -Message "Enabled DSC Automation Host on $VMName."
    }
    
    # dismount VHD
    Dismount-VHD $maindiskpath

    Write-Verbose -Message 'Differencing disk dismounted'
    #endregion
  
    #region create new vm
    # Create VM with new VHD
    New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -SwitchName $VMSwitch -VHDPath $maindiskpath -Generation 2 -BootDevice VHD
    #endregion
    
    Write-Verbose -Message "Created new lab VM with name $VMName, $MemoryStartupBytes memory. The VM is connected to $VMSwitch with IP address $VMIP."
    
    Start-Sleep -Seconds 2
    
    if ($NestedVirt -eq $true)
    {
      Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true
    
      Write-Verbose -Message "Exposed Virtualization Extensions on $VMName."
    }
  
    #region start new vm and connect to console
    # Start VM
    Start-VM $VMName
    Start-Process -FilePath vmconnect -ArgumentList localhost, $VMName

    Write-Verbose -Message "Started $VMName."

    #endregion 
    
    Set-Location -Path c:\                
  }
  End
  {
  }
}
