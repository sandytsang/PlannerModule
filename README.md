# PlannerModule
PowerShell module for Microsoft Planner

#Examples:

#Check Planner PowerShell module

$PlannerModule = Get-Module -Name "PlannerModule" -ListAvailable

if ($PlannerModule -eq $null)
{
	Write-host "Planner PowerShell module not found, Start install the module"
	Install-Module "PlannerModule" -AllowClobber -Force
}


#Connect to Microsoft Planner
Connect-Planner -ForceNonInteractive True

#Definde variables
$GroupName = "A NewPlan 01"
$PlanName = "PowerShell Test Plan 03"
$BucketName = "PowerShell bucket"
$TaskName = "Test Task"


#Create new plan with Private O365 Group (this will also create new O365 Group), can also create public group
#$result01 = New-PlannerPlan -PlanName $PlanName -visibility Private
#$PlannerPlanID = $result01.id


#Create New Office 365 Group
$responde = New-AADUnifiedGroup -GroupName $GroupName -visibility Private
$GroupID = $($responde.id)

Start-Sleep 10

#create new plan using exsiting O365 Group
$responde1 = New-PlannerPlanToGroup -PlanName $PlanName -GroupID $GroupID
$PlannerPlanID = $($responde1.id)

#Create new Bucket
$responde2 = New-PlannerBucket -PlanID $PlannerPlanID -BucketName $BucketName
$PlannerPlanBucketID = $responde2.id

#Create task
$responde3 = New-PlannerTask -PlanID $PlannerPlanID -TaskName $TaskName -BucketID $PlannerPlanBucketID -startDate "2019.6.3" -dueDate "2019.6.30"
$PlannerPlanTaskID = $responde3.id

#Assign task to users
Invoke-AssignPlannerTask -TaskID $PlannerPlanTaskID -UserPrincipalNames "user01@yourdomain.com", "user02@yourdomain.com"

#Add task check list
Add-PlannerTaskChecklist -TaskID $PlannerPlanTaskID -Title "Check1" -IsChecked $false
Add-PlannerTaskChecklist -TaskID $PlannerPlanTaskID -Title "Check2" -IsChecked $true
Add-PlannerTaskChecklist -TaskID $PlannerPlanTaskID -Title "Check3" -IsChecked $false

#add task description
Add-PlannerTaskDescription -TaskID $PlannerPlanTaskID -Description "This is test task created by powershell planner module"

#Add or update labels
Update-PlannerPlanCategories -PlanID $PlannerPlanID -category1 "Kieken" -category2 "smart" -category3 "very smart" -category4 "wise" -category5 "something"

#Assign Planner Task lables
Invoke-AssignPlannerTaskCategories -TaskID $PlannerPlanTaskID -category1 $false -category2 $true -category3 $true -category4 $false -category5 $false -category6 $false
