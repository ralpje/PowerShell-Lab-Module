# PowerShell-Lab-Module
A Powershell module for (re)building your (home) lab environment on Hyper-V

This module is extending the script I first used for my Experts Live 2016 session about this topic.

## Functions

* **New-NATSwitch** creates a Internal Virtual Switch within Hyper-V and gives the switch an IP-address & subnet. Creates a NAT network for the IP-range of the Internal Virtual Switch.

* **New-LabVM** creates a new (Hyper-V) VM, within the NAT-network created by the New-NATSwitch resources. If desired, the VM can be directly coupled with (Azure) DSC and Nested Virtualization can be enabled.

### New-NATSwitch

* **Name:** (Mandatory, String) Specifies the name of the new NAT switch.
* **IPAddress:** (String, default value: 172.16.10.1) Specifies the IP address of the new NAT switch. This address will be used as default gateway within the NAT network.
* **PrefixLength:** (Integer, default value: 24) Specifies the subnet mask of the new NAT network in bit-length. 24 = 255.255.255.0.
* **NATName:** (String, default value: LabNAT): Specifies the name of the NAT network.

### New-LabVM

* **VMName:** (Mandatory, String) Specifies the name of the new VM. 
* **MemoryStartupBytes:** (String, default value: 2048MB) Specifies the amount of internal memory of the new VM.  
* **VMIP:** (Mandatory, String) Specifies the IP Address of the new VM.
* **GWIP:** (String, default value 172.16.10.1) Specifies the default gateway IP address of the new VM. Default value matches the default value of the IP address of the New-NATSwitch resource.
* **Diskpath:** (Mandatory, String) Specifies the path where the differencing vhdx-file for the new Lab VM should be created. Points to a directory path.
* **ParentDisk:** (Mandatory, String) Specifies the path where the 'Main' OS Disk, source for the differencing disk, can be found. Points to an existing .vhdx-file.
* **VMSwitch:** (Mandatory, String) Specifies the name of the Virtual Switch where the new VM will be connected with.
* **DNSIP:** (String, default value = 8.8.8.8) Specifies the IP address of the DNS server the VM will be configured with.
* **Unattendloc:** (String, default value: https://raw.githubusercontent.com/ralpje/PowerShell-Lab-Module/master/Templates/unattend.xml) Specifies the location where the unattend.xml-file can be found which will be used during the creation of the new VM.
* **DSC:** (Boolean, default value: $false) Setting DSC to true, the new VM will try to register itself at the in the specified URL within the DSCPullConfig-file.
* **DSCPullConfig:** (Mandatory when DSC = $true, String) Specifies the settings for the local DSC Manager config of the new VM, so it can connect to the right (Azure) DSC Pull Server.
* **NestedVirt:** (Boolean, default value: $false) Nested virtualization is a feature that allows you to run Hyper-V inside of a Hyper-V virtual machine. In other words, with nested virtualization, a Hyper-V host itself can be virtualized. Setting NestedVirt to true, this feature will be enabled for the lab VM.

## Templates

* **Templates\unattend.xml** Specifies the values used during creation of the new VM, like the name of the VM, IP address, default gateway, etc..

* **Templates\AzureDSCPullConfig.ps1** Example file to be used to create a personalized version, so the VM('s) will register itself with your own Azure subscription.

### Templates\unattend.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="windowsPE">
<component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SetupUILanguage>
<UILanguage>en-US</UILanguage>
</SetupUILanguage>
<InputLocale>0409:00000409</InputLocale>
<SystemLocale>en-US</SystemLocale>
<UILanguage>en-US</UILanguage>
<UILanguageFallback>en-US</UILanguageFallback>
<UserLocale>en-US</UserLocale>
</component>
<component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<UserData>
<AcceptEula>true</AcceptEula>
<FullName>User Name</FullName>
<Organization>Organisation Name</Organization>
</UserData>
</component>
</settings>
<settings pass="specialize">
<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<InputLocale>0409:00000409</InputLocale>
<SystemLocale>en-US</SystemLocale>
<UILanguage>en-US</UILanguage>
<UILanguageFallback>en-US</UILanguageFallback>
<UserLocale>en-US</UserLocale>
</component>
<component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SkipAutoActivation>true</SkipAutoActivation>
</component>
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<ComputerName>HOSTNAME1</ComputerName>
</component>
	<component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
       <Interfaces>
         <Interface wcm:action="add">
           <Ipv4Settings>
             <DhcpEnabled>False</DhcpEnabled>
           </Ipv4Settings>
           <UnicastIpAddresses>
             <IpAddress wcm:action="add" wcm:keyValue="1">172.16.0.1/24</IpAddress>
           </UnicastIpAddresses>
           <Identifier>Ethernet</Identifier>
           <Routes>
             <Route wcm:action="add">
               <Identifier>0</Identifier>
               <Prefix>0.0.0.0/0</Prefix>
               <NextHopAddress>172.16.0.1</NextHopAddress>
             </Route>
           </Routes>
         </Interface>
       </Interfaces>
     </component>
	<component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <Interfaces>
                <Interface wcm:action="add">
                    <DNSServerSearchOrder>
                        <IpAddress wcm:action="add" wcm:keyValue="1">8.8.8.8</IpAddress>
                    </DNSServerSearchOrder>
                    <Identifier>Ethernet</Identifier>
                </Interface>
            </Interfaces>
	</component>
</settings>
<settings pass="oobeSystem">
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<OOBE>
<HideEULAPage>true</HideEULAPage>
<HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
<HideOnlineAccountScreens>true</HideOnlineAccountScreens>
<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
<SkipUserOOBE>true</SkipUserOOBE>
<SkipMachineOOBE>true</SkipMachineOOBE>
</OOBE>
<UserAccounts>
<AdministratorPassword>
              <Value>P@ssW0rd</Value>
              <PlainText>true</PlainText>
           </AdministratorPassword>
</UserAccounts>
<RegisteredOrganization>3rganisation Name</RegisteredOrganization>
<RegisteredOwner>User Name</RegisteredOwner>
<DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
<TimeZone>W. Europe Standard Time</TimeZone>
<VisualEffects>
<SystemDefaultBackgroundColor>7</SystemDefaultBackgroundColor>
</VisualEffects>
</component>
</settings>
</unattend>
```

### Templates\AzureDSCPullConfig.ps1

```PowerShell
 # The DSC configuration that will generate metaconfigurations
 [DscLocalConfigurationManager()]
 Configuration DscMetaConfigs
 {

     param
     (
         [Parameter(Mandatory=$True)]
         [String]$RegistrationUrl,

         [Parameter(Mandatory=$True)]
         [String]$RegistrationKey,

         [Parameter(Mandatory=$True)]
         [String[]]$ComputerName,

         [Int]$RefreshFrequencyMins = 30,

         [Int]$ConfigurationModeFrequencyMins = 15,

         [String]$ConfigurationMode = "ApplyAndMonitor",

         [String]$NodeConfigurationName,

         [Boolean]$RebootNodeIfNeeded= $False,

         [String]$ActionAfterReboot = "ContinueConfiguration",

         [Boolean]$AllowModuleOverwrite = $False,

         [Boolean]$ReportOnly
     )

     if(!$NodeConfigurationName -or $NodeConfigurationName -eq "")
     {
         $ConfigurationNames = $null
     }
     else
     {
         $ConfigurationNames = @($NodeConfigurationName)
     }

     if($ReportOnly)
     {
     $RefreshMode = "PUSH"
     }
     else
     {
     $RefreshMode = "PULL"
     }

     Node $ComputerName
     {

         Settings
         {
             RefreshFrequencyMins = $RefreshFrequencyMins
             RefreshMode = $RefreshMode
             ConfigurationMode = $ConfigurationMode
             AllowModuleOverwrite = $AllowModuleOverwrite
             RebootNodeIfNeeded = $RebootNodeIfNeeded
             ActionAfterReboot = $ActionAfterReboot
             ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
         }

         if(!$ReportOnly)
         {
         ConfigurationRepositoryWeb AzureAutomationDSC
             {
                 ServerUrl = $RegistrationUrl
                 RegistrationKey = $RegistrationKey
                 ConfigurationNames = $ConfigurationNames
             }

             ResourceRepositoryWeb AzureAutomationDSC
             {
             ServerUrl = $RegistrationUrl
             RegistrationKey = $RegistrationKey
             }
         }

         ReportServerWeb AzureAutomationDSC
         {
             ServerUrl = $RegistrationUrl
             RegistrationKey = $RegistrationKey
         }
     }
 }

 # Create the metaconfigurations
 # TODO: edit the below as needed for your use case
 $Params = @{
     RegistrationUrl = '<your-registration-url-here>';
     RegistrationKey = '<your-registration-key-here>';
     ComputerName = "replace";
     NodeConfigurationName = "<your-node-config-name-here>";
     RefreshFrequencyMins = 30;
     ConfigurationModeFrequencyMins = 15;
     RebootNodeIfNeeded = $True;
     AllowModuleOverwrite = $False;
     ConfigurationMode = 'ApplyAndAutoCorrect';
     ActionAfterReboot = 'ContinueConfiguration';
     ReportOnly = $False;  # Set to $True to have machines only report to AA DSC but not pull from it
 }

 # Use PowerShell splatting to pass parameters to the DSC configuration being invoked
 # For more info about splatting, run: Get-Help -Name about_Splatting
 
 DscMetaConfigs @Params
 ```
 
## Versions

### v2.1 (13-02-2017)

* New-LabVM
    * Fixed a bug regarding the default unattend.xml location on GitHub.

### v2.0 (12-02-2017)

Split up NewLabEnvironment into New-NATSwitch and New-LabVM.

* New-NATSwitch
    * New file, separated from New-LabVM.
    * No further changes.

* New-LabVM
    * Removed the NATName-parameter. Parameter is not being used within the script.
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

## Issues / Feedback
For any issues or feedback related to this module, please register for GitHub, and post your inquiry to this project's issue tracker.