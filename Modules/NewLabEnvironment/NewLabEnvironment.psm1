#requires -Version 3.0 -Modules Hyper-V, NetAdapter, NetNat, NetTCPIP, Storage

<#
    .Synopsis
    This module lets you roll out your lab environment automatically. This is the first step: creating a NATSwitch.

    .DESCRIPTION
    This module lets you roll out your lab environment automatically as described in our blogs (www.365dude.nl and www.svenvanrijen.nl).
    This is the first step: creating a NATSwitch.

    The Name parameter is mandatory.
    IP Address is optional, "172.16.10.1" is the default value.
    Prefix Length is optional, "24" is the default value.
    NAT name is optional, "LABnat" is the default value.

    .EXAMPLE
    You first have to create a NATSwitch, before creating any VM's in your lab.

    New-NATswitch -Name NATswitch creates a NATswitch with the default IP Address (172.16.10.1), Prefix Length (24)
    and NAT name (LABnat)

    .EXAMPLE
    New-NATSwitch -Name Test -IPAddress 10.0.1.1 -PrefixLength 24 -NATName TestNAT

    With this line of code you create a new VMSwitch within HyperV with the name Test. 
    Also an IP Address (10.0.1.1) is assigned to this switch and a NAT network with address space 10.0.1.0/24 
    is created.
#>
function New-NATSwitch
{
  [CmdletBinding()]
  [OutputType([String])]
  Param
  ( 
    [Parameter(Mandatory = $true)]
    [string]$Name,
        
    [Parameter(Mandatory = $false)]
    [string]$IPAddress = 172.16.10.1,
        
    [Parameter(Mandatory = $false)]
    [int]$PrefixLength = 24,
        
    [Parameter(Mandatory = $false)]
    [string]$NATName = 'LabNAT'
  )

  Begin
  {
  }
  Process
  {
        
    New-VMSwitch -SwitchName $Name -SwitchType Internal

    $NetAdapter = Get-NetAdapter -Name "vEthernet ($Name)"
    $InterfaceIndex = $NetAdapter.ifIndex
          
    New-NetIPAddress -IPAddress $IPAddress -PrefixLength $PrefixLength -InterfaceIndex $InterfaceIndex
          
    $ip2 = $IPAddress.Split('.')
    $ip2[-1] = "0/$PrefixLength"
    $InternalIPInterfaceAddressPrefix = $ip2 -join '.'

    New-NetNat -Name $NATName -InternalIPInterfaceAddressPrefix $InternalIPInterfaceAddressPrefix 
                  
  }
  End
  {
  }
}

<#
    .Synopsis
    This module lets you roll out your lab environment automatically. This is the second step: creating a Lab VM's.

    .DESCRIPTION
    This module lets you roll out your lab environment automatically as described in our blogs (www.365dude.nl and www.svenvanrijen.nl).
    This is the second step: creating a Lab VM's.
    First step: creating a NATSwitch (New-NATSwitch).

    New-LabVM generates a new VM in the lab environment. 
    IPAddress is a mandatory parameter and must be in the "172.16.10.10/24" notation. 
    Please use the same address space as used when creating the NATSwitch.
    The specification of a Gateway is optional. If DNS-server is not specified, the default will be used. (172.16.10.1)
    The specification of a DNS-server is optional. If DNS-server is not specified, the default will be used. (8.8.8.8)

    .EXAMPLE
    New-LabVM -VMName Test -VMIP 10.0.0.18/29 -GWIP 10.0.0.1

    .EXAMPLE
    New-LabVM -VMName Hostname -VMIP 192.168.123.20/24 -DNSIP 192.168.123.5 -GWIP 192.168.123.1
#>
function New-LabVM
{
  [CmdletBinding()]
  [OutputType([String])]
  Param
  ( 
    [Parameter(Mandatory = $true)]
    [string]$VMName,
        
    [Parameter(Mandatory = $true)]
    [string]$VMIP,
    
    [Parameter(Mandatory = $false)]
    [string]$GWIP = '172.16.10.1',

    [Parameter(Mandatory = $true)]
    [string]$diskpath,

    [Parameter(Mandatory = $true)]
    [string]$ParentDisk,

    [Parameter(Mandatory = $true)]
    [string]$VMSwitch,
        
    [Parameter(Mandatory = $false)]
    [string]$DNSIP = '8.8.8.8',
        
    [Parameter(Mandatory = $false)]
    [string]$NATName = 'LabNAT',

    [Parameter(Mandatory = $false)]
    [string]$SourceXML = "$PSScriptRoot\temp\unattended.xml",
    
    [Parameter(Mandatory = $false)]
    [string]$url = 'https://raw.githubusercontent.com/svenvanrijen/linkedmodulefiles/master/unattend.xml',

    [Parameter(Mandatory = $false)]
    [string]$MemoryStartupBytes = 2048MB
  )

  Begin
  {
  }
  Process
  {
    #region create diff disk
    # Create new differencing disk
    
    $maindiskpath = "$diskpath\$VMName.vhdx"
    
    New-VHD -ParentPath $ParentDisk -Path $maindiskpath -Differencing
    
    Write-Verbose -Message "Created a differencing disk $maindiskpath."
    
    Start-Sleep -Seconds 2
    #endregion
  
    #region copy adjusted answer file
    # mount VHD
    $VHD = (Mount-VHD -Path $maindiskpath -Passthru |
      Get-Disk |
      Get-Partition |
      Where-Object -FilterScript {
        $_.Type -eq 'Basic'
    }).DriveLetter
    
    Write-Verbose -Message 'Differencing disk mounted'
    
    Start-Sleep -Seconds 2
    
    # Copy xml from github to local temp dir    
    New-Item -ItemType Directory -Path "$PSScriptRoot\Temp" -Force
    $output = "$PSScriptRoot\temp\unattended.xml"
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Verbose -Message "Unattended.xml copied from GitHub to $PSScriptRoot\Temp."
    
    Start-Sleep -Seconds 2
    
    
    # add XML Content
    [xml]$Unattend = Get-Content $SourceXML
    $Unattend.unattend.settings[1].component[2].ComputerName = $VMName
    $Unattend.unattend.settings[1].component[3].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $VMIP
    $Unattend.unattend.settings[1].component[4].Interfaces.Interface.DNSServerSearchOrder.IpAddress.'#Text' = $DNSIP
    $Unattend.unattend.settings[1].component[3].Interfaces.Interface.Routes.Route.NextHopAddress = $GWIP
    $Unattend.Save("${VHD}:\\Unattend.xml")
    
    Write-Verbose -Message "Set VM name to $VMName, IP Address to $VMIP, DNS IP to $DNSIP and GW IP to $GWIP"    
    
    Start-Sleep -Seconds 2
    
    # dismount VHD
    Dismount-VHD $maindiskpath
    #endregion
  
    #region create new vm
    # Create VM with new VHD
    New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -SwitchName $VMSwitch -VHDPath $maindiskpath -Generation 2 -BootDevice VHD
    #endregion
    
    Write-Verbose -Message "Created new lab VM with name $VMName, $MemoryStartupBytes memory. The VM is connected to $NATName with IP address $VMIP."
    
    Start-Sleep -Seconds 2
  
    #region start new vm and connect to console
    # Start VM
    Start-VM $VMName
    Start-Process -FilePath vmconnect -ArgumentList localhost, $VMName
    #endregion                  
  }
  End
  {
  }
}
