﻿
#=============================================================================#
# PowerShell script sample for Vault Data Standard                            #
#			 Autodesk Vault - Quickstart 2017  								  #
# This sample is based on VDS 2017 RTM and adds functionality and rules       #
# All additions are marked with 'region Quickstart' - 'endregion'			  #
#                                                                             #
# Copyright (c) Autodesk - All rights reserved.                               #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

#this function will be called to check if the Ok button can be enabled
function ActivateOkButton
{
	#region Quickstart
		#return Validate;
		return $true #using dynamic categories the validation is done against prop def criterias
	#endregion
}

# sample validation function
# finds all function definition with names beginning with
# ValidateFile, ValidateFolder and ValidateTask respectively
# these funcions should return a boolean value, $true if the Property is valid
# $false otherwise
# As soon as one property validation function returns $false the entire Validate function will return $false
function Validate
{
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"FileWindow"
		{
			foreach ($func in dir function:ValidateFile*) { if(!(&$func)) { return $false } }
			return $true
		}
		"FolderWindow"
		{
			foreach ($func in dir function:ValidateFolder*) { if(!(&$func)) { return $false } }
			return $true
		}
		"CustomObjectWindow"
		{
			#foreach ($func in dir function:ValidateCustomObject*) { if(!(&$func)) { return $false } }
			return $true
		}
		default { return $true }
	}
    
}

# sample validation function for the Title property
# if the Title is empty the validation will fail
function ValidateFileTitle
{
	return $true
	#if($Prop["_XLTN_TITLE"].Value) { return $true}
	#return $false;
}

# sample validation function for the FileName property
# if the File Name is empty the validation will fail
function ValidateFileName
{
	if($Prop["_FileName"].Value -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function ValidateFolderName
{
	if($Prop["_FolderName"].Value -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function ValidateCustomObjectName
{
	if($Prop["_CustomObjectName"].Value -or !$dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{
		return $true;
	}
	return $false;
}

function InitializeTabWindow
{
	#$dsDiag.ShowLog()
	#$dsDiag.Inspect()
}

function InitializeWindow
{	
	#begin rules applying commonly
	$Prop["_Category"].add_PropertyChanged({
        if ($_.PropertyName -eq "Value")
        {
			#region quickstart
				#$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				m_CategoryChanged
			#endregion
        }		
    })
	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"FileWindow"
		{
			#rules applying for File
			$dsWindow.Title = SetWindowTitle $UIString["LBL24"] $UIString["LBL25"] $Prop["_FileName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				if ($Prop["_IsOfficeClient"].Value)
				{
					$Prop["_Category"].Value = $UIString["CAT2"]
				}
				else
				{
					$Prop["_Category"].Value = $UIString["CAT1"]
				}
			}
						
		}
		"FolderWindow"
		{
			#rules applying for Folder
			$dsWindow.Title = SetWindowTitle $UIString["LBL29"] $UIString["LBL30"] $Prop["_FolderName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				$Prop["_Category"].Value = $UIString["CAT5"]
			}
		}
		"CustomObjectWindow"
		{
			#rules applying for Custom Object
			$dsWindow.Title = SetWindowTitle $UIString["LBL61"] $UIString["LBL62"] $Prop["_CustomObjectName"].Value
			if ($Prop["_CreateMode"].Value)
			{
				$Prop["_Category"].Value = $Prop["_CustomObjectDefName"].Value

				#region Quickstart
					$dsWindow.FindName("Categories").IsEnabled = $false
					$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
					$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				#endregion
			}
		}
	}
}

function SetWindowTitle($newFile, $editFile, $name)
{
	if ($Prop["_CreateMode"].Value)
    {
		$windowTitle = ($newFile)
	}
	elseif ($Prop["_EditMode"].Value)
	{
		$windowTitle = "$($editFile) - $($name)"
	}
	elseif ($Prop["_ReadOnly"].Value)
	{
		$windowTitle = "$($editFile) - $($name)$($UIString["LBL26"])"
	}
	return $windowTitle
}

function OnLogOn
{
	#Executed when User logs on Vault
	#$vaultUsername can be used to get the username, which is used in Vault on login
}
function OnLogOff
{
	#Executed when User logs off Vault
}

function GetTitleWindow
{
	$message = "Autodesk Data Standard - Create/Edit "+$Prop["_FileName"]
	return $message
}

#fired when the file selection changes
function OnTabContextChanged
{
	$xamlFile = [System.IO.Path]::GetFileName($VaultContext.UserControl.XamlFile)
	
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "FileMaster" -and $xamlFile -eq "CAD BOM.xaml")
	{
		$fileMasterId = $vaultContext.SelectedObject.Id
		$file = $vault.DocumentService.GetLatestFileByMasterId($fileMasterId)
		$bom = @(GetFileBOM($file.id))
		$dsWindow.FindName("bomList").ItemsSource = $bom
	}
	if ($VaultContext.SelectedObject.TypeId.SelectionContext -eq "ItemMaster" -and $xamlFile -eq "Associated Files.xaml")
	{
		$items = $vault.ItemService.GetItemsByIds(@($vaultContext.SelectedObject.Id))
		$item = $items[0]
		$itemids = @($item.Id)
		$assocFiles = @(GetAssociatedFiles $itemids $([System.IO.Path]::GetDirectoryName($VaultContext.UserControl.XamlFile)))
		$dsWindow.FindName("AssoicatedFiles").ItemsSource = $assocFiles
	}
}

function GetNewCustomObjectName
{
	$dsDiag.Trace(">> GetNewCustomObjectName")
	#region Default
		#if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
		#{	
		#	$dsDiag.Trace("read text from TextBox CUSTOMOBJECTNAME")
		#	$customObjectName = $dsWindow.FindName("CUSTOMOBJECTNAME").Text
		#	$dsDiag.Trace("customObjectName = $customObjectName")
		#}
		#else{
		#	$dsDiag.Trace("-> GenerateNumber")
		#	$customObjectName = $Prop["_GeneratedNumber"].Value
		#	$dsDiag.Trace("customObjectName = $customObjectName")
		#}
	#endregion

	#region Quickstart
		$m_Cat = $Prop["_Category"].Value
		switch ($m_Cat)
		{
			$UIString["MSDCE_CO02"] #Person
			{
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					$Prop["_XLTN_IDENTNUMBER"].Value = $Prop["_GeneratedNumber"].Value
				}
				$customObjectName = $Prop["_XLTN_FIRSTNAME"].Value + " " + $Prop["_XLTN_LASTNAME"].Value
				return $customObjectName
			}

			Default 
			{
				$dsDiag.Trace("-- GetNewObjectName Default = all categories ---")
				if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty -eq $false)
				{
					if($Prop["_XLTN_IDENTNUMBER"]){ $Prop["_XLTN_IDENTNUMBER"].Value = $Prop["_GeneratedNumber"].Value}
				}
				$customObjectName = $dsWindow.FindName("CUSTOMOBJECTNAME").Text
				$dsDiag.Trace("--- txtName returns $customObjectName ") 
				IF ($customObjectName -eq "") 
				{ 
					$customObjectName = $Prop["_XLTN_TITLE"].Value
					$dsDiag.Trace("--- Title gets the new object name") 
				}
				$dsDiag.Trace("--- GetNewCustomObjectName returns $customObjectName") 
				return $customObjectName
			}
		}
}

#Constructs the filename(numschems based or handtyped)and returns it.
function GetNewFileName
{
	$dsDiag.Trace(">> GetNewFileName")
	if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{	
		$dsDiag.Trace("read text from TextBox FILENAME")
		$fileName = $dsWindow.FindName("FILENAME").Text
		$dsDiag.Trace("fileName = $fileName")
	}
	else{
		$dsDiag.Trace("-> GenerateNumber")
		$fileName = $Prop["_GeneratedNumber"].Value
		$dsDiag.Trace("fileName = $fileName")
	}
	$newfileName = $fileName + $Prop["_FileExt"].Value
	$dsDiag.Trace("<< GetNewFileName $newfileName")
	return $newfileName
}

function GetNewFolderName
{
	$dsDiag.Trace(">> GetNewFolderName")
	if($dsWindow.FindName("DSNumSchmsCtrl").NumSchmFieldsEmpty)
	{	
		$dsDiag.Trace("read text from TextBox FOLDERNAME")
		$folderName = $dsWindow.FindName("FOLDERNAME").Text
		$dsDiag.Trace("folderName = $folderName")
	}
	else{
		$dsDiag.Trace("-> GenerateNumber")
		$folderName = $Prop["_GeneratedNumber"].Value
		$dsDiag.Trace("folderName = $folderName")
	}
	$dsDiag.Trace("<< GetNewFolderName $folderName")
	return $folderName
}

# This function can be used to force a specific folder when using "New Standard File" or "New Standard Folder" functions.
# If an empty string is returned the selected folder is used
# ! Do not remove the function
function GetParentFolderName
{
	$folderName = ""
	return $folderName
}

function GetCategories
{
	if ($dsWindow.Name -eq "FileWindow")
	{
		#return $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
		#region quickstart
			$global:mFileCategories = $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
			return $global:mFileCategories
		#endregion
	}
	elseif ($dsWindow.Name -eq "FolderWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
	}
	elseif ($dsWindow.Name -eq "CustomObjectWindow")
	{
		return $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true)
	}
}

function GetNumSchms
{
	if ($Prop["_CreateMode"].Value)
	{
		try
		{
			[System.Collections.ArrayList]$numSchems = @($vault.DocumentService.GetNumberingSchemesByType('Activated'))
			if ($numSchems.Count -gt 1)
			{
				#$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
				#region Quickstart
					$mWindowName = $dsWindow.Name
					switch($mWindowName)
					{
						"FileWindow"
						{
							$_FilteredNumSchems = $numSchems | Where { $_.IsDflt -eq $true}
							$Prop["_NumSchm"].Value = $_FilteredNumSchems[0].Name
							$dsWindow.FindName("NumSchms").IsEnabled = $false
							return $_FilteredNumSchems
						}

						"FolderWindow" 
						{
							#numbering schemes are available for items and files specificly; 
							#for folders we use the file numbering schemes and filter to these, that have a corresponding name in folder categories
							$_FolderCats = $vault.CategoryService.GetCategoriesByEntityClassId("FLDR", $true)
							$_FilteredNumSchems = @()
							Foreach ($item in $_FolderCats) 
							{
								$_temp = $numSchems | Where { $_.Name -eq $item.Name}
								$_FilteredNumSchems += ($_temp)
							}
							#we need an option to unselect a previosly selected numbering; to achieve that we add a virtual one, named "None"
							$noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
							$noneNumSchm.Name = "None"
							$_FilteredNumSchems += ($noneNumSchm)

							return $_FilteredNumSchems
						}

						"CustomObjectWindow"
						{
							$_FilteredNumSchems = $numSchems | Where { $_.Name -eq $Prop["_Category"].Value}
							return $_FilteredNumSchems
						}
						default
						{
							$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
							return $numSchems
						}
					}
				#region
			}
			Else {
				$dsWindow.FindName("NumSchms").IsEnabled = $false				
			}
			return $numSchems
		}
		catch [System.Exception]
		{		
			#[System.Windows.MessageBox]::Show($error)
		}
	}
}


# Decides if the NumSchmes field should be visible
function IsVisibleNumSchems
{
	$ret = "Collapsed"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "Visible" }
	return $ret
}

#Decides if the FileName should be enabled, it should only when the NumSchmField isnt
function ShouldEnableFileName
{
	$ret = "true"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "false" }
	return $ret
}

function ShouldEnableNumSchms
{
	$ret = "false"
	$numSchems = $vault.DocumentService.GetNumberingSchemesByType([Autodesk.Connectivity.WebServices.NumSchmType]::Activated)
	if($numSchems.Length -gt 0)
	{	$ret = "true" }
	return $ret
}

#define the parametrisation for the number generator here
function GenerateNumber
{
	$dsDiag.Trace(">> GenerateNumber")
	$selected = $dsWindow.FindName("NumSchms").Text
	if($selected -eq "") { return "na" }

	$ns = $global:numSchems | Where-Object { $_.Name.Equals($selected) }
	switch ($selected) {
		"Sequential" { $NumGenArgs = @(""); break; }
		default      { $NumGenArgs = @(""); break; }
	}
	$dsDiag.Trace("GenerateFileNumber($($ns.SchmID), $NumGenArgs)")
	$vault.DocumentService.GenerateFileNumber($ns.SchmID, $NumGenArgs)
	$dsDiag.Trace("<< GenerateNumber")
}

#define here how the numbering preview should look like
function GetNumberPreview
{
	$selected = $dsWindow.FindName("NumSchms").Text
	switch ($selected) {
		"Sequential" { $Prop["_FileName"].Value="???????"; break; }
		"Short" { $Prop["_FileName"].Value=$Prop["Project"].Value + "-?????"; break; }
		"Long" { $Prop["_FileName"].Value=$Prop["Project"].Value + "." + $Prop["Material"].Value + "-?????"; break; }
		default { $Prop["_FileName"].Value="NA" }
	}
}

function ItemTitle
{
	$val = $Prop["_XLTN_TITLE_ITEM_CO"].Value
	return $val
}

function ItemDescription
{
	$val = $Prop["_XLTN_DESCRIPTION_ITEM_CO"].Value
	return $val
}

#region Quickstart 
function m_TemplateChanged {
	#$dsDiag.Trace(">> Template Changed ...")
	$mContext = $dsWindow.DataContext
	$mTemplatePath = $mContext.TemplatePath
	$mTemplateFile = $mContext.SelectedTemplate
	$mTemplate = $mTemplatePath + "/" + $mTemplateFile
	$mFolder = $vault.DocumentService.GetFolderByPath($mTemplatePath)
	$mFiles = $vault.DocumentService.GetLatestFilesByFolderId($mFolder.Id,$false)
	$mTemplateFile = $mFiles | Where-Object { $_.Name -eq $mTemplateFile }
	$Prop["_Category"].Value = $mTemplateFile.Cat.CatName
	$mCatName = $mTemplateFile.Cat.CatName
	$dsWindow.FindName("Categories").SelectedValue = $mCatName
	If ($mCatName) #if something went wrong the user should be able to select a category
	{
		$dsWindow.FindName("Categories").IsEnabled = $false #comment out this line if admins like to release the choice to the user
	}
	#$dsDiag.Trace(" ... TemplateChanged finished <<")
}

function m_CategoryChanged 
{
	$mWindowName = $dsWindow.Name
    switch($mWindowName)
	{
		"FileWindow"
		{
			#Quickstart uses the default numbering scheme for files; GoTo GetNumSchms function to disable this filter incase you'd like to apply numbering per category for files as well
			$dsWindow.FindName("TemplateCB").add_SelectionChanged({
				m_TemplateChanged
			})
			$Prop['_XLTN_AUTHOR'].Value = $VaultConnection.UserName
		}

		"FolderWindow" 
		{
			$dsWindow.FindName("NumSchms").SelectedItem = $null
			$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
			$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Collapsed"
			$dsWindow.FindName("FOLDERNAME").Visibility = "Visible"
					
			$Prop["_NumSchm"].Value = $Prop["_Category"].Value
			IF ($dsWindow.FindName("DSNumSchmsCtrl").Scheme.Name -eq $Prop["_Category"].Value) 
			{
				$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Visible"
				$dsWindow.FindName("FOLDERNAME").Visibility = "Collapsed"
			}
			Else
			{
				$Prop["_NumSchm"].Value = "None" #we need to reset in case a user switches back from existing numbering scheme to manual input
			}
			
			#set the start date = today for project category
			If ($Prop["_Category"].Value -eq $UIString["CAT6"] -and $Prop["_XLTN_DATESTART"] )		
			{
				$Prop["_XLTN_DATESTART"].Value = Get-Date -displayhint date
			}
		}

		"CustomObjectWindow"
		{
			#categories are bound to CO type name
		}
		default
		{
			#nothing for 'unknown' new window type names
		}			
	} #end switch window
} #end function m_CategoryChanged

function mHelp ([Int] $mHContext) {
	Try
	{
		Switch ($mHContext){
			500 {
				$mHPage = "File.html";
			}
			600 {
				$mHPage = "Folder.html";
			}
			700 {
				$mHPage = "CustomObject.html";
			}
			Default {
				$mHPage = "Index.html";
			}
		}
		$mHelpTarget = "C:\ProgramData\Autodesk\Vault 2017\Extensions\DataStandard" + "\" + $PSCulture + "\HelpFiles\"+$mHPage
		$mhelpfile = Invoke-Item $mHelpTarget 
	}
	Catch
	{
		[System.Windows.MessageBox]::Show("Help Target not found", "Vault Quickstart Client")
	}
}

#endregion quickstart