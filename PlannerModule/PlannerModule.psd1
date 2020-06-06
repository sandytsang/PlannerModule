<#	
	===========================================================================
	 Created on:   	2019-06-03 1:55 AM
     	 Updated on:    2020-06-06
	 Created by:   	Zeng Yinghua
	 Filename:     	PlannerModule.psd1
	 -------------------------------------------------------------------------
	 Module Manifest
	-------------------------------------------------------------------------
	 Module Name: PlannerModule
	===========================================================================
#>


@{
	
	# Script module or binary module file associated with this manifest
	RootModule			   = 'PlannerModule.psm1'
	
	# Version number of this module.
	ModuleVersion		   = '1.0.2.4'
	
	# ID used to uniquely identify this module
	GUID				   = 'f9dfe908-e078-42d3-9276-1bd1de619e58'
	
	# Author of this module
	Author				   = 'Zeng Yinghua'
	
	# Company or vendor of this module
	CompanyName		       = ''
	
	# Copyright statement for this module
	Copyright			   = '(c) 2019. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description		       = 'PowerShell Module for Microsoft Planner'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion	   = '5.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName	   = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion  = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '2.0'
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion			   = '2.0.50727'
	
	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture  = 'None'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules	       = @()
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies	   = @()
	
	# Script files (.ps1) that are run in the caller's environment prior to
	# importing this module
	ScriptsToProcess	   = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess		   = @()
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess	   = @()
	
	# Modules to import as nested modules of the module specified in
	# ModuleToProcess
	NestedModules		   = @()
	
	# Functions to export from this module
	FunctionsToExport	   = @(
		'Get-PlannerAuthToken',
		'Update-PlannerModuleEnvironment',
		'Get-UnifiedGroupsList',
		'New-AADUnifiedGroup',
		'Add-AADUnifiedGroupMember',
		'Get-PlannerPlanGroup',
		'Invoke-ListPlannerPlans',
		'Get-PlannerPlansList',
		'Get-PlannerPlan',
		'Invoke-ListPlannerPlanTasks',
		'Get-PlannerPlanTasks',
		'Invoke-ListPlannerPlanBuckets',
		'Get-PlannerPlanBuckets',
		'Get-PlannerTask',
		'Get-PlannerTaskDetails',
		'Get-PlannerPlanDetails',
		'Get-PlannerBucket',
		'Invoke-ListPlannerBucketTasks',
		'Get-PlannerBucketTasksList',
		'Get-PlannerAssignedToTaskBoardTaskFormat',
		'Get-PlannerBucketTaskBoardTaskFormat',
		'Get-PlannerProgressTaskBoardTaskFormat',
		'New-PlannerPlan',
		'New-PlannerPlanToGroup',
		'New-PlannerBucket',
		'New-PlannerTask',
		'Get-AADUserDetails',
		'Invoke-AssignPlannerTask',
		'Update-PlannerPlanCategories',
		'Invoke-AssignPlannerTaskCategories',
		'Add-PlannerTaskDescription',
		'Add-PlannerTaskChecklist',
		'Connect-Planner'
	) #For performance, list functions explicitly
	
	# Cmdlets to export from this module
	CmdletsToExport	       = @()
	
	# Variables to export from this module
	VariablesToExport	   = @()
	
	# Aliases to export from this module
	AliasesToExport	       = @() #For performance, list alias explicitly
	
	# DSC class resources to export from this module.
	#DSCResourcesToExport = ''
	
	# List of all modules packaged with this module
	ModuleList			   = @()
	
	# List of all files packaged with this module
	FileList			   = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData		       = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = 'PSModule', 'Planner', 'MSGraph'
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/sandytsang/PlannerModule/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/sandytsang/PlannerModule'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			# ReleaseNotes = ''
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}
