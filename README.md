# BAM-API-PowerShell
Bluecat Address Manager API PowerShell Functions

There are currently 6 functions

- New-BAMInstance
	- Creates a new instance of the SOAP API
- Get-BAMConfigurationId
	- Gets the Id of the given configuration
- Get-BAMViewId
	- Gets the Id of the given View
	- Requires a configurationId
- Add-BAMDeviceInstance
	- Wrapper for the addDeviceInstance method
- Remove-BAMDeviceInstance
	- Wrapper for the deleteDeviceInstance method
- Get-BamProperties
	- Takes a string of properties and returns a PowerShell Object

#Notes
This example relies on Settings.xml. This doesn't have to be used.. 
Globals can be hardcoded as seen in script defined variables.
	
#TODO
- Properly format functions
- Move functions out to a module or separate file for dot sourcing
- Add more functions
- Better error handling