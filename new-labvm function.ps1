function New-LabVM
{
  <#
      .SYNOPSIS
      Creates a new VM in the lab environment
      .DESCRIPTION
      Creates a new VM in the lab environment. Takes the name and IP-address of the VM as a parameter.
      IP-address must be in the 192.168.0.1/24 notation. The specification of a DNS-server is optional.
      If DNS-server is not specified, the default will be used. 
      .EXAMPLE
      New-LabVM -VMName HOSTNAME -VMIP 10.0.0.18/29
      .EXAMPLE
      New-LabVM -VMName Hostname -VMIP 192.168.123.20/24 -DNSIP 8.8.8.8 -GWIP 192.168.123.1
  #>
  param
  (
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    $VMName,
    
    [Parameter(Mandatory=$true, Position=1)]
    [string]
    $VMIP,
    
    [Parameter(Position=2)]
    [string]
    $DNSIP = '172.16.0.200',

    [Parameter(Position=3)]
    [string]
    $GWIP = '172.16.0.1'
  )
  
  #region define variables
    
    # Script Variables that are the same for each server
    # Adjust these variables according to your environment
    $diskpath = "D:\$VMName.vhdx"
    $ParentDisk = 'G:\SoftwareLib\VHD Templates\W2K16_Template.vhdx'
    $VMSwitch = 'NATnetwork'
    $SourceXML = 'G:\GitHub\private\unattend.xml'
  #endregion
  
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
    New-VM -Name $VMName -MemoryStartupBytes 2048MB -SwitchName $VMSwitch -VHDPath $diskpath -Generation 2 -BootDevice VHD
  #endregion
  
  #region start new vm and connect to console
    # Start VM
    Start-VM $VMName
    Start-Process vmconnect -ArgumentList localhost,$VMName
  #endregion
}

