<#	
	===========================================================================
	 Created on:   	6/3/2019 1:55 AM
	 Created by:   	Zeng Yinghua
	 Organization: 	
	 Filename:     	PlannerModule.psm1
	-------------------------------------------------------------------------
	 Module Name: PlannerModule

	Histrory: 
	Sep.27 				Fixed a bug
	July.25,2019 		Added $Credential parameter for authdentication
	Jun.03.2019 		First version
	===========================================================================

#>

function Get-PlannerAuthToken
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	Param
	(
		[parameter(Mandatory = $false, HelpMessage = "Specify a PSCredential object containing username and password.")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential
	)
	
	Write-Host "Checking for AzureAD module..."
	$AadModule = Get-Module -Name "AzureAD" -ListAvailable
	if ($AadModule -eq $null)
	{
		Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
		$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
	}
	if ($AadModule -eq $null)
	{
		Write-Error "AzureAD Powershell module not installed..."
		Write-Error "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt"
		return
	}
	
	# Getting path to ActiveDirectory Assemblies
	# If the module count is greater than 1 find the latest version
	
	if ($AadModule.count -gt 1)
	{
		$Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
		$aadModule = $AadModule | ForEach-Object { $_.version -eq $Latest_Version.version }
		
		# Checking if there are multiple versions of the same module found        
		if ($AadModule.count -gt 1)
		{
			$aadModule = $AadModule | Select-Object -Unique
		}
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
	}
	else
	{
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
	}
	
	[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
	[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
	
	if ($PlannerEnvUpdated -ne $true)
	{
		$clientId = "3556cd23-09eb-42b3-a3b9-72cba5c7926e"
	}
	$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
	$resourceAppIdURI = "https://graph.microsoft.com"
	$authority = "https://login.microsoftonline.com/common"
	
	try
	{
		$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
		
		# https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
		# Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
		
		$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Always"
		
		if (!$Credential)
		{
			$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).Result
		}
		else
		{
			# Construct required identity model credential
			$UserPasswordCredential = New-Object -TypeName "Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential" -ArgumentList ($Credential.UserName, $Credential.Password) -ErrorAction Stop
			
			# Acquire access token
			$authResult = ([Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $clientId, $UserPasswordCredential)).Result
		}
		
		# If the accesstoken is valid then create the authentication header        
		if ($authResult.AccessToken)
		{
			# Creating header for Authorization token            
			$authHeader = @{
				'Content-Type'  = 'application/json'
				'Authorization' = "Bearer " + $authResult.AccessToken
				'ExpiresOn'	    = $authResult.ExpiresOn
			}
			return $authHeader
		}
		else
		{
			Write-Error "Authorization Access Token is null, please re-run authentication..."
			break
		}
	}
	catch
	{
		Write-Error $_.Exception.Message
		Write-Error $_.Exception.ItemName
		break
	}
}

function Update-PlannerModuleEnvironment
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[cmdletbinding()]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$ClientId
	)
	
	Write-Warning "WARNING: Call the 'Connect-Planner' cmdlet to use the updated environment parameters."
	
	Write-Host "
	AuthUrl          : https://login.microsoftonline.com/common
	ResourceId       : https://graph.microsoft.com
	GraphBaseAddress : https://graph.microsoft.com
	AppId            : $ClientId
	RedirectLink     : urn:ietf:wg:oauth:2.0:oob
	SchemaVersion    : beta

" -ForegroundColor Cyan
	
	$Script:ClientId = $($ClientId)
	$Script:PlannerEnvUpdated = $true
}

function Update-PlannerModuelEnvironment
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[cmdletbinding()]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$ClientId
	)
	
	Write-Warning "This function has typo, please use 'Update-PlannerModuleEnvironment' instead"
	Write-Warning "WARNING: Call the 'Connect-Planner' cmdlet to use the updated environment parameters."
	
	Write-Host "
	AuthUrl          : https://login.microsoftonline.com/common
	ResourceId       : https://graph.microsoft.com
	GraphBaseAddress : https://graph.microsoft.com
	AppId            : $ClientId
	RedirectLink     : urn:ietf:wg:oauth:2.0:oob
	SchemaVersion    : beta

" -ForegroundColor Cyan
	
	$Script:ClientId = $($ClientId)
	$Script:PlannerEnvUpdated = $true
}

Function Invoke-ListUnifiedGroups
{
	# .ExternalHelp PlannerModule.psm1-Help.xml	
	Write-Warning "This is an old function, please use 'Get-UnifiedGroupsList' instead"
	try
	{
		$uri = "https://graph.microsoft.com/beta/Groups?`$filter=groupTypes/any(c:c+eq+'Unified')"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Get-UnifiedGroupsList
{
	# .ExternalHelp PlannerModule.psm1-Help.xml	
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/Groups?`$filter=groupTypes/any(c:c+eq+'Unified')"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function New-AADUnifiedGroup
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[cmdletbinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[string]$GroupName,
		[Parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Public", "Private")]
		$visibility = "Private"
	)
	
	$randomNum = (Get-Random -Maximum 1000).tostring()
	$mailNickname = $GroupName.Replace(" ", "") + $randomNum
	
	try
	{
		$Body = @"
{
  "description": "$($GroupName)",
  "displayName": "$($GroupName)",
  "groupTypes": [
    "Unified"
  ],
  "mailEnabled": true,
  "mailNickname": "$($mailNickname)",
  "securityEnabled": false,
  "visibility": "Private"
}
"@
		
		$uri = "https://graph.microsoft.com/beta/groups"
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
		Write-Host "$($GroupName) is created, Group visibility type is $($visibility)" -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Add-AADUnifiedGroupMember
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[cmdletbinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[string]$GroupID,
		[Parameter(Mandatory = $True)]
		[array]$UserPrincipalNames
	)
	
	foreach ($UserPrincipalName in $UserPrincipalNames)
	{
		try
		{
			
			#Get users id
			$userID = (Get-AADUserDetails -UserPrincipalName $UserPrincipalName).id
			
			$Body = @"
{
  "@odata.id": "https://graph.microsoft.com/beta/directoryObjects/$($userID)"
}
"@
			$uri = "https://graph.microsoft.com/beta/groups/$GroupID/members/`$ref"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
			Write-Host "$($UserPrincipalNames) is added to GroupID: $($GroupID)" -ForegroundColor Cyan
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
	
}

Function Get-PlannerPlanGroup
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[cmdletbinding()]
	param
	(
		[string]$GroupName
	)
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/Groups?`$filter=groupTypes/any(c:c+eq+'Unified')+and+displayName+eq+`'$Groupname`'"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Invoke-ListPlannerPlans
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'GroupID')]
		[Alias("id")]
		$GroupID,
		[Parameter(Mandatory = $True, ParameterSetName = 'GroupName')]
		$GroupName
	)
	
	Write-Warning "This is an old function, please use 'Get-PlannerPlansList' instead"
	
	Process
	{
		try
		{
			switch ($PsCmdlet.ParameterSetName)
			{
				'GroupName'
				{
					$GroupID = (Get-PlannerPlanGroup -GroupName $($GroupName)).id
				}
			}
			$Uri = "https://graph.microsoft.com/beta/groups/$GroupID/planner/plans"
			(Invoke-RestMethod -uri $Uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerPlansList
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'GroupID')]
		[Alias("id")]
		$GroupID,
		[Parameter(Mandatory = $True, ParameterSetName = 'GroupName')]
		$GroupName
	)
	
	Process
	{
		try
		{
			switch ($PsCmdlet.ParameterSetName)
			{
				'GroupName'
				{
					$GroupID = (Get-PlannerPlanGroup -GroupName $($GroupName)).id
				}
			}
			$Uri = "https://graph.microsoft.com/beta/groups/$GroupID/planner/plans"
			(Invoke-RestMethod -uri $Uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerPlan
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$PlanID
	)
	
	Process
	{
		try
		{
			$uri = "https://graph.microsoft.com/beta/planner/plans/$PlanID"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Invoke-ListPlannerPlanTasks
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$PlanID
	)
	
	Write-Host "This is an old function, please use 'Get-PlannerPlanTasks' instead"
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/plans/$PlanID/tasks"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
	
}

Function Get-PlannerPlanTasks
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$PlanID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/plans/$PlanID/tasks"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
	
}

Function Invoke-ListPlannerPlanBuckets
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$PlanID
	)
	
	Write-Warning "This is an old function, please use 'Get-PlannerPlanBuckets' instead"
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/plans/$PlanID/buckets"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerPlanBuckets
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$PlanID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/plans/$PlanID/buckets"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerTask
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$TaskID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/tasks/$TaskID"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerTaskDetails
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$TaskID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta//planner/tasks/$TaskID/details"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerPlanDetails
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$PlanID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/plans/$PlanID/details"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerBucket
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$BucketID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/buckets/$BucketID"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Invoke-ListPlannerBucketTasks
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$BucketID
	)
	
	Write-Warning "This is an old function, please use 'Get-PlannerBucketTasksList' instead"
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/buckets/$BucketID/tasks"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerBucketTasksList
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$BucketID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/buckets/$BucketID/tasks"
			(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerAssignedToTaskBoardTaskFormat
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$TaskID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/tasks/$TaskID/assignedToTaskBoardFormat"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerBucketTaskBoardTaskFormat
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$TaskID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/tasks/$TaskID/bucketTaskBoardFormat"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Get-PlannerProgressTaskBoardTaskFormat
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		[string[]]$TaskID
	)
	
	Process
	{
		try
		{
			
			$uri = "https://graph.microsoft.com/beta/planner/tasks/$TaskID/progressTaskBoardFormat"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function New-PlannerPlan
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		
		[Parameter(Mandatory = $true)]
		$PlanName,
		[Parameter(Mandatory = $True)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet("Public", "Private")]
		$visibility = "Private"
	)
	
	
	$GroupInfo = Get-PlannerPlanGroup -GroupName $($PlanName) -ErrorAction SilentlyContinue
	if ($GroupInfo)
	{
		Write-Warning "Same Group name $($PlanName) is found, please use 'New-PlannerPlanToGroup' to create add plan to Group, or change plan name"
		break
	}
	else
	{
		$results = New-AADUnifiedGroup -GroupName $($PlanName) -visibility $($visibility)
		$GroupID = $results.id
		Start-Sleep 10
		#Get current user
		$uri = "https://graph.microsoft.com/beta/me"
		$UserPrincipalName = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method GET).UserPrincipalName
		Add-AADUnifiedGroupMember -GroupID $GroupID -UserPrincipalName $UserPrincipalName
		Start-Sleep 10
	}
	
	
	$Body = @"
{
  "owner": "$($GroupID)",
  "title": "$($PlanName)"
}
"@
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/plans"
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
		Write-Host "$($PlanName) is created. Group visibility is $($visibility)" -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
}

Function New-PlannerPlanToGroup
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		
		[Parameter(Mandatory = $true)]
		$PlanName,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $True)]
		[Alias("id")]
		$GroupID
	)
	
	#Add current user to group
	#Get current user
	$uri = "https://graph.microsoft.com/beta/me"
	$UserID = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method GET).id
	$uri = "https://graph.microsoft.com/beta/Groups/$GroupID/members?`$filter=id eq '$UserID'"
	
	try
	{
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method GET
	}
	catch
	{
		$AddUser = $true
	}
	if ($AddUser -eq $true)
	{
		try
		{
			$Body = @"
{
  "@odata.id": "https://graph.microsoft.com/beta/directoryObjects/$($userID)"
}
"@
			
			$uri = "https://graph.microsoft.com/beta/groups/$GroupID/members/`$ref"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
			Start-Sleep 10
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "$($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
	
	$Body = @"
{
  "owner": "$($GroupID)",
  "title": "$($PlanName)"
}
"@
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/plans"
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
		Write-Host "$($PlanName) is created." -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
}

Function New-PlannerBucket
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'PlanID')]
		[Alias("id")]
		$PlanID,
		[Parameter(Mandatory = $True)]
		$BucketName
	)
	
	Process
	{
		$Body = @"
{
  "name": "$($BucketName)",
  "planId": "$($PlanID)",
  "orderHint": " !"
}
"@
		
		try
		{
			$uri = "https://graph.microsoft.com/beta/planner/buckets"
			Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
			Write-Host "$($BucketName) is created." -ForegroundColor Cyan
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function New-PlannerTask
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'PlanID')]
		[Alias("id")]
		$PlanID,
		[Parameter(Mandatory = $True)]
		$TaskName,
		[Parameter(Mandatory = $False)]
		$BucketID,
		[Parameter(Mandatory = $False, HelpMessage = "DateTime format needs to be YYYY-MM-DD, example 2019-06-30")]
		[DateTime]$startDate,
		[Parameter(Mandatory = $False, HelpMessage = "DateTime format needs to be YYYY-MM-DD, example 2019-06-30")]
		[DateTime]$dueDate
	)
	
	#user defualt bucket name To do
	If (!$BucketID)
	{
		$BucketID = (Get-PlannerPlanBuckets -PlanID $($PlanID) | Where-Object { $_.name -like 'To do' }).id
	}
	
	#if start date and due date is not definde
	if (!$startDate -and !$dueDate)
	{
		$Body = @"
{
  "planId": "$($PlanID)",
  "bucketId": "$($BucketID)",
  "title": "$($TaskName)",
}
"@
	}
	
	#if start date is due date are definded
	if ($startDate -and $dueDate)
	{
		$startDateformat = $startDate.ToString("yyyy-MM-ddT10:00:00Z")
		$dueDateformat = $dueDate.ToString("yyyy-MM-ddT10:00:00Z")
		
		$Body = @"
{
    "planId": "$($PlanID)",
    "bucketId": "$($BucketID)",
    "title": "$($TaskName)",
    "startDateTime": "$($startDateformat)",
    "dueDateTime": "$($dueDateformat)"
}
"@
	}
	
	#if no start date, but has duedate
	if (!$startDate -and $dueDate)
	{
		$dueDateformat = $dueDate.ToString("yyyy-MM-ddT10:00:00Z")
		
		$Body = @"
{
  "planId": "$($PlanID)",
  "bucketId": "$($BucketID)",
  "title": "$($TaskName)",
  "dueDateTime": "$($dueDateformat)"
}
"@
	}
	
	#if has start date, but no due date
	if ($startDate -and !$dueDate)
	{
		$startDateformat = $startDate.ToString("yyyy-MM-ddT10:00:00Z")
		
		$Body = @"
{
  "planId": "$($PlanID)",
  "bucketId": "$($BucketID)",
  "title": "$($TaskName)",
  "startDateTime": "$($startDateformat)"
}
"@
	}
	
	#Make graph call
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/tasks"
		Invoke-RestMethod -Uri $uri -Headers $authToken -Method POST -Body $Body
		Write-Host "$($TaskName) is created." -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
}

Function Get-AADUserDetails
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$UserPrincipalName
	)
	
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/users?`$filter=userPrincipalName eq '$($UserPrincipalName)'"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method GET).value
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
}

Function Invoke-AssignPlannerTask
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'TaskID')]
		[Alias("id")]
		$TaskID,
		[Parameter(Mandatory = $True)]
		[array]$UserPrincipalNames
	)
	
	foreach ($UserPrincipalName in $UserPrincipalNames)
	{
		#Get users id
		$userID = (Get-AADUserDetails -UserPrincipalName $UserPrincipalName).id
		
		#Get Task details
		$respond = Get-PlannerTask -TaskID $TaskID
		$ETag = $respond.'@odata.etag'
		$TaskTile = $respond.title
		
		$Body = @"
{
  "assignments": {
    "$($userID)": {
        "@odata.type": "#microsoft.graph.plannerAssignment",
        "orderHint": " !"
    }
  }
}
"@
		#Add if-match to new tocket header
		$NewToken = $authToken.Clone()
		$NewToken.add("If-Match", $ETag)
		
		try
		{
			$uri = "https://graph.microsoft.com/beta/planner/tasks/$($TaskID)"
			Invoke-RestMethod -Uri $uri -Headers $NewToken -Method PATCH -Body $Body
			Write-Host "$($UserPrincipalNames) is assigned to Task: $($TaskTile)" -ForegroundColor Cyan
		}
		catch
		{
			$ex = $_.Exception
			if ($($ex.Response.StatusDescription) -match 'Unauthorized')
			{
				Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
			}
			Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
			break
		}
	}
}

Function Update-PlannerPlanCategories
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'PlanID')]
		[Alias("id")]
		$PlanID,
		[Parameter(Mandatory = $false)]
		$category1 = 'null',
		$category2 = 'null',
		$category3 = 'null',
		$category4 = 'null',
		$category5 = 'null',
		$category6 = 'null'
	)
	
	#Get Plan details
	$respond = Get-PlannerPlanDetails -PlanID $PlanID
	$ETag = $respond.'@odata.etag'
	
	$Body = @"
{
  "categoryDescriptions": {
    "category1": "$category1",
    "category2": "$category2",
    "category3": "$category3",
    "category4": "$category4",
    "category5": "$category5",
    "category6": "$category6"
  }
}
"@
	
	#Add if-match to new tocket header
	$NewToken = $authToken.Clone()
	$NewToken.add("If-Match", $ETag)
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/plans/$($PlanID)/details"
		Invoke-RestMethod -Uri $uri -Headers $NewToken -Method PATCH -Body $Body
		Write-Host "Categories/Lables are updated" -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Invoke-AssignPlannerTaskCategories
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'TaskID')]
		[Alias("id")]
		$TaskID,
		[Parameter(Mandatory = $True)]
		[bool]$category1 = $false,
		[bool]$category2 = $false,
		[bool]$category3 = $false,
		[bool]$category4 = $false,
		[bool]$category5 = $false,
		[bool]$category6 = $false
	)
	
	#Get Task details
	$respond = Get-PlannerTask -TaskID $TaskID
	$ETag = $respond.'@odata.etag'
	$TaskName = $respond.title
	
	$Body = @"
{
  "appliedCategories": {
    "category1": $($category1.tostring().ToLower()),
    "category2": $($category2.tostring().ToLower()),
    "category3": $($category3.tostring().ToLower()),
    "category4": $($category4.tostring().ToLower()),
    "category5": $($category5.tostring().ToLower()),
    "category6": $($category6.tostring().ToLower())
  }
}
"@
	
	#Add if-match to new tocket header
	$NewToken = $authToken.Clone()
	$NewToken.add("If-Match", $ETag)
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/tasks/$($TaskID)"
		Invoke-RestMethod -Uri $uri -Headers $NewToken -Method PATCH -Body $Body
		Write-Host "Categories are assigned to Task: $($TaskName)" -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Add-PlannerTaskDescription
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'TaskID')]
		[Alias("id")]
		$TaskID,
		[Parameter(Mandatory = $True)]
		[string[]]$Description
	)
	
	#Get Task details
	$respond = Get-PlannerTaskDetails -TaskID $TaskID
	$ETag = $respond.'@odata.etag'
	
	$Body = @"
{
    "description": "$($Description)"
}
"@
	
	#Add if-match to new tocket header
	$NewToken = $authToken.Clone()
	$NewToken.add("If-Match", $ETag)
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/tasks/$($TaskID)/Details"
		Invoke-RestMethod -Uri $uri -Headers $NewToken -Method PATCH -Body $Body
		Write-Host "Task Description is updated" -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Add-PlannerTaskChecklist
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'TaskID')]
		[Alias("id")]
		$TaskID,
		[Parameter(Mandatory = $True)]
		[string[]]$Title,
		[bool]$IsChecked = $false
	)
	
	#Get Task details
	$respond = Get-PlannerTaskDetails -TaskID $TaskID
	$ETag = $respond.'@odata.etag'
	
	$checklist = (New-Guid).Guid
	
	$Body = @"
{
    "checklist": {
        "$checklist": {
            "@odata.type": "#microsoft.graph.plannerChecklistItem",
            "isChecked": $($IsChecked.tostring().ToLower()),
            "title": "$($Title)"
        }
    }
}
"@
	
	#Add if-match to new tocket header
	$NewToken = $authToken.Clone()
	$NewToken.add("If-Match", $ETag)
	
	try
	{
		$uri = "https://graph.microsoft.com/beta/planner/tasks/$($TaskID)/Details"
		Invoke-RestMethod -Uri $uri -Headers $NewToken -Method PATCH -Body $Body
		Write-Host "CheckList is added" -ForegroundColor Cyan
	}
	catch
	{
		$ex = $_.Exception
		if ($($ex.Response.StatusDescription) -match 'Unauthorized')
		{
			Write-Error "Unauthorized, Please check your permissions and use the 'Connect-Planner' command to authenticate"
		}
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		break
	}
	
}

Function Connect-Planner
{
	# .ExternalHelp PlannerModule.psm1-Help.xml
	
	[CmdletBinding()]
	[OutputType([Bool])]
	Param
	(
		[Parameter(Mandatory = $false, Position = 0, ParameterSetName = "AuthPrompt")]
		[ValidateNotNullOrEmpty()]
		[ValidateSet($false, $true)]
		$ForceNonInteractive,
		[parameter(Mandatory = $false, ParameterSetName = "AuthCredential", HelpMessage = "Specify a PSCredential object containing username and password.")]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$Credential
	)
	
	
	#Authentication
	
	if ($ForceNonInteractive -eq $true)
	{
		# Getting the authorization token
		$Script:authToken = Get-PlannerAuthToken
		return $authToken
	}
	
	if ($ForceNonInteractive -eq $false)
	{
		
		# Checking if authToken exists before running authentication
		if ($Script:authToken)
		{
			# Setting DateTime to Universal time to work in all timezones
			$DateTime = (Get-Date).ToUniversalTime()
			# If the authToken exists checking when it expires
			$TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
			if ($TokenExpires -le 0)
			{
				Write-Host "Authentication Token expired" $TokenExpires "minutes ago"
				$Script:authToken = Get-PlannerAuthToken
			}
		}
		# Authentication doesn't exist, calling Get-AuthToken function
		else
		{
			# Getting the authorization token
			$Script:authToken = Get-PlannerAuthToken
		}
	}
	
	if ($Credential)
	{
		# Getting the authorization token
		$Script:authToken = Get-PlannerAuthToken -Credential $Credential
	}
	
}
