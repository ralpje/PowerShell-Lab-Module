# Release notes New Lab Environment Module

<<<<<<< HEAD
=======
## v2.0 (08-02-2017)
**Changed _$url_ to _$unattendloc_**  
`[string]`  
`Mandatory = $false`  
`Default value = https://raw.githubusercontent.com/svenvanrijen/linkedmodulefiles/master/unattend.xml`  
Since the `unattend.xml` file can be picked up from both an internet or a local file storage location, _$unattendloc_ is a better representation.

**Added _$DSC_**   
`[boolean]`  
`Mandatory = $false`  
`Default value = $false`  
To make it possible to add the newly created server directly to an Azure DSC Pull server (support of a local https pull server will be added in a later version), _$DSC_ is added. When this parameter is set to _$true_, also a value for _$DSCPullConfig_ has to be supplied.

**Added _$DSCPullConfig_**   
`[string]`  
`Mandatory = $false`  
When _$DSC_ is used, a location for the DSC Pull configuration has to be supplied.  
An example of such a config file can be found at ... 

**Added _$NestedVirt_**   
`[boolean]`  
`Mandatory = $false`  
`Default value = $false`  
Nested virtualization is a feature that allows you to run Hyper-V inside of a Hyper-V virtual machine. In other words, with nested virtualization, a Hyper-V host itself can be virtualized. With this parameter, this feature will be enabled for the lab VM.

**Minor changes**
Furthermore some minor changes to the verbose output.

**For more information, please read the blogpost regarding this release of the module on [www.svenvanrijen.nl](http://www.svenvanrijen.nl).**

## v1.1 (18-01-2017)
Added the URL-parameter. In the initial release, this was a static link to a central unattend.xml file on GitHub. By default, it still is. But with this URL parameter, users have the possibility to link to their own edited or personalized unattend.xml.

## v1.0 (31-12-2016)
Initial release, reformated the script(s) to a PowerShell module.
>>>>>>> origin/master
