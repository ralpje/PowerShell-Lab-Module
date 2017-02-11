# PowerShell-Lab-Module
A Powershell module for (re)building your (home) lab environment on Hyper-V

This module is extending the script I first used for my Experts Live 2016 session about this topic.

## Resources

* **New-NATSwitch** creates a Internal Virtual Switch within Hyper-V and gives the switch an IP-address & subnet. Creates a NAT network for the IP-range of the Internal Virtual Switch.

* **New-LabVM** creates a new (Hyper-V) VM, within the NAT-network created by the New-NATSwitch resources. If desired, the VM can be directly coupled with (Azure) DSC and Nested Virtualization can be enabled.

### New-NATSwitch

* **Name:** (Mandatory, String) Specifies the name of the new NAT switch.
* **IPAddress:** (String, default value: 172.16.10.1) Specifies the IP address of the new NAT switch. This address will be used as default gateway within the NAT network.
* **PrefixLength:** (String, default value: 24) Specifies the subnet mask of the new NAT network in bit-length. 24 = 255.255.255.0.
* **NATName:** (String, default value: LabNAT): Specifies the name of the NAT network.

### New-LabVM

* **VMName:** (Mandatory, String) Specifies the name of the new VM. 

## Versions

### v2.0

Splitted up NewLabEnvironment into New-NATSwitch and New-LabVM.

* New-NATSwitch
    * New file, separated from New-LabVM.
    * No further changes.

* New-LabVM
    * Changed URL-parameter to unattendloc-parameter. Since the unattend.xml file can be found both local and on the internet, unattendloc is a better name.
    * Changed to default location of the unattend.xml file to a directory within the main GitHub module.
    * Added the DSC-parameter.
    * Added the DSCPullConfig-parameter.
    * Added the NestedVirt-parameter.
    * Removed the SourceXML-parameter, since it was intended for interal use within the module only.
    * Added and updated Verbose statements. 

### v1.1 (18-01-2017)
Added the URL-paramter. In the initial release, this was a static link to a central unattend.xml file on GitHub. By default, it still is. But with this URL parameter, users have the possibility to link to their own edited or personalized unattend.xml.

### v1.0 (31-12-2016)
Initial release, reformated the script(s) to a PowerShell module.
