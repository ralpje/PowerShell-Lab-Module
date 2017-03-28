#requires -Version 3.0 -Modules Hyper-V, NetAdapter, NetNat, NetTCPIP, Storage

# Version 2.0 (12-02-2017)

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
  [CmdletBinding(
    SupportsShouldProcess = $true)]
  [OutputType([String])]
  Param
  ( 
    [Parameter(Mandatory = $true)]
    [string]$Name,
        
    [Parameter(Mandatory = $false)]
    [string]$IPAddress = '172.16.10.1',
        
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
