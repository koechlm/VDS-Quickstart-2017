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
		$mHelpTarget = "C:\ProgramData\Autodesk\Vault 2017\Extensions\DataStandard\"+$PSCulture+"\HelpFiles\"+$mHPage
		$mhelpfile = Invoke-Item $mHelpTarget	
	}
	Catch
	{
		[System.Windows.MessageBox]::Show("Help Target not found", "Vault Quickstart Client")
	}