
#requires -version 3

#####################
# Declare functions #
#####################

function New-BAMInstance(){
    [CmdletBinding()]
    Param(
        [string]$User,
        [string]$Password,
        [string]$BAMHost
        )
    
    $wsdl = "http://$($BAMHost)/Services/API?wsdl"
    $cookie = New-Object System.Net.CookieContainer
    $webService = New-WebServiceProxy -Uri $wsdl
    $webService.CookieContainer = $cookie

    Write-Verbose -Message "Attempting login operation against $($wsdl)"

    try{
        $webService.login($User,$Password)
        Write-Verbose -Message "Success!"
        }
    catch [Exception] {
        throw $_.Exception.Message
        }

    return $webService
}

function Get-BAMConfigurationId(){
    [CmdletBinding()]
    Param(
        [object]$BAMInstance,
        [string]$ConfigurationName,
        [int]$Start = 0,
        [int]$Count = 10
        )

    $configuration = $BAMInstance.getEntitiesByName(0, $ConfigurationName, "Configuration",$Start,$Count)

    if (!$configuration){
        throw "Could not find configuration!"
        }

    Write-Verbose -Message "Configuration Id: $($configuration.id)"
    Write-Verbose -Message "Configuration Name: $($configuration.name)"

    $configurationId = $configuration.id
    return $configurationId

}

function Get-BAMViewId(){
    [CmdletBinding()]
    Param(
        [object]$BAMInstance,
        [long]$ConfigurationId,
        [string]$ViewName,
        [int]$Start = 0,
        [int]$Count = 10
        )

    $view = $BAMInstance.getEntitiesByName($ConfigurationId, $ViewName, "View",$Start,$Count)

    if (!$view){
        throw "Could not find View!"
        }

    Write-Verbose -Message "View Id: $($View.id)"
    Write-Verbose -Message "View Name: $($view.name)"

    $viewId = $view.id
    return $viewId

}

function Add-BAMDeviceInstance(){
    [CmdletBinding()]
    Param(
        [object]$BAMInstance,
        [string]$ConfigurationName,
        [string]$IPAddressMode = "REQUEST_STATIC",
        [string]$IPAddressEntity,
        [string]$ViewName,
        [string]$DomainName,
        [string]$RecordName,
        [string]$MacAddressMode = "PASS_VALUE",
        [string]$MacAddressEntity = "00:00:00:00:00:00",
        [string]$Options
        )

    Write-Verbose -Message "Attempting to add $($IPAddressMode) entry"

    try{
        $Response = $BAMInstance.addDeviceInstance(
            $configName, 
            "", 
            $IPAddressMode, 
            $IPAddressEntity,
            $ViewName, 
            $DomainName, 
            $RecordName, 
            $MacAddressMode, 
            $MacAddressEntity,
            $Options 
        )

    Write-Verbose -Message "Success!"

    }
    catch [Exception] {
        throw $_.Exception.Message
    }

    $Properties = Get-BamProperties -InputString $Response
    
    Write-Verbose -Message "IPAddress: $($Properties.ip)"
    Write-Verbose -Message "Netmask: $($Properties.netmask)"
    Write-Verbose -Message "Gateway: $($Properties.gateway)"

    return $Properties

}

function Remove-BAMDeviceInstance(){
    [CmdletBinding()]
    Param(
        [object]$BAMInstance,
        [string]$ConfigurationName,
        [string]$IPorMACAddress
        )

    Write-Verbose -Message "Attempting to remove $($IPorMACAddress) and associated config"

    try{
        $BAMInstance.deleteDeviceInstance($ConfigurationName, $IPorMACAddress, "")
        Write-Verbose -Message "Success!"
    }
    catch [Exception]{
        throw $_.Exception.Message
    }
}

function Get-BamProperties(){
    [CmdletBinding()]
    Param(
        [string]$InputString
        )

    $inputArray = $InputString.Split("|")
    $PSObject = New-Object PSObject  
    $inputArray | % {
        
        if ($_){ 
            Add-Member -InputObject $PSObject -Name $_.Split("=")[0] -Value $_.Split("=")[1] -MemberType NoteProperty
        }
    }

   return $PSObject
}      
                
#############
# Variables #
#############

#Get script directory and load Settings.xml
$scriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
[xml]$configFile = Get-Content $scriptPath"\Settings.xml"

#Constants from Settings.xml
#Moved these out for privacy reasons
$user = $configFile.Settings.BAMUser
$password = $configFile.Settings.BAMPassword
$bamhost = $configFile.Settings.BAMHost
$configName = $configFile.Settings.BAMConfigurationName
$viewName = $configFile.Settings.BAMViewName
$domainName = $configFile.Settings.BAMDomainName

#Script defined variables
$hostname = "test-ptr6"
$network = "10.69.255.0/25"

###############
# Main Script #
###############

$IPAM = New-BAMInstance -User $user -Password $password -BAMHost $bamhost -Verbose
$IPAddressEntity = Add-BAMDeviceInstance -BAMInstance $IPAM -ConfigurationName $configName -IPAddressEntity $Network -ViewName $viewName -DomainName $domainName -RecordName $hostname -Options "AllowDuplicateHosts=false|" -Verbose
$IPAddressEntity

#Remove-BAMDeviceInstance Example:
#Remove-BAMDeviceInstance -BAMInstance $IPAM -ConfigurationName $configName -IPorMACAddress "10.69.255.28" -Verbose

#Get Config & View Id Example:
#$configurationId = Get-BAMConfigurationId -BAMInstance $IPAM -ConfigurationName $configName -Verbose
#$viewId = Get-BAMViewId -BAMInstance $IPAM -ConfigurationId $configurationId -ViewName $viewName -Verbose

#Get-BAMProperties Example:
#Get-BAMProperties -InputString $IPAM.getSystemInfo()

$IPAM.logout()