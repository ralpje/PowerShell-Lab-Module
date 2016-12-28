<#
    .Synopsis
    This module lets you roll out your lab environment automatically. This is the first step: creating a NATSwitch.

    .DESCRIPTION
    This module lets you roll out your lab environment automatically as described in our blogs (www.365dude.nl and www.svenvanrijen.nl).
    This is the first step: creating a NATSwitch.

    .EXAMPLE
    You first have to create a NATSwitch, before creating any VM's in your lab.

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
        
    [Parameter(Mandatory = $true)]
    [string]$IPAddress,
        
    [Parameter(Mandatory = $true)]
    [int]$PrefixLength,
        
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

    New-LabVM generates a new VM in the lab environment. Both IPAddress and Gateway IP Address are mandatory parameters. 
    IP-address must be in the "192.168.0.1/24" notation. 
    Please use the same address space as used when creating the NATSwitch.
    The specification of a DNS-server is optional. If DNS-server is not specified, the default will be used. (8.8.8.8)

    .EXAMPLE
    New-LabVM -VMName HOSTNAME -VMIP 10.0.0.18/29 -GWIP 10.0.0.1

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
    
    [Parameter(Mandatory = $true)]
    [string]$GWIP,

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
    [string]$SourceXML = 'https://raw.githubusercontent.com/svenvanrijen/linkedmodulefiles/master/unattend.xml',

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
    New-VHD -ParentPath $ParentDisk -Path $diskpath -Differencing
    #endregion
  
    #region copy adjusted answer file
    # mount VHD
    $VHD = (Mount-VHD -Path $diskpath -Passthru |
      Get-Disk |
      Get-Partition |
      Where-Object -FilterScript {
        $_.Type -eq 'Basic'
    }).DriveLetter
    # add XML Content
    [xml]$Unattend = Get-Content $SourceXML
    $Unattend.unattend.settings[1].component[2].ComputerName = $VMName
    $Unattend.unattend.settings[1].component[3].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $VMIP
    $Unattend.unattend.settings[1].component[4].Interfaces.Interface.DNSServerSearchOrder.IpAddress.'#Text' = $DNSIP
    $Unattend.unattend.settings[1].component[3].Interfaces.Interface.Routes.Route.NextHopAddress = $GWIP
    $Unattend.Save("${VHD}:\\Unattend.xml")
    # dismount VHD
    Dismount-VHD $diskpath
    #endregion
  
    #region create new vm
    # Create VM with new VHD
    New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -SwitchName $VMSwitch -VHDPath $diskpath -Generation 2 -BootDevice VHD
    #endregion
  
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
