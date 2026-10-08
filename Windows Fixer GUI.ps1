# Clean-up

Remove-Variable -Name * -ErrorAction SilentlyContinue
CLS

$ErrorActionPreference= 'silentlycontinue'

# The GUI  System

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

# Main part of said GUI

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Windows Fixer GUI'
$form.Size = New-Object System.Drawing.Size(450,200)
$form.StartPosition = 'CenterScreen'

# Main text

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Location = New-Object System.Drawing.Point(20,20)
$Label1.Size = New-Object System.Drawing.Size(200,20)
$Label1.Text = "Windows Fixer GUI"
$form.Controls.Add($Label1)
$Form.Icon = New-Object System.Drawing.Icon ".\Icon.ico"

# Select Drive

$Label2 = New-Object System.Windows.Forms.Label
$Label2.Location = New-Object System.Drawing.Point(20,60)
$Label2.Size = New-Object System.Drawing.Size(130,20)
$Label2.Text = "Select Option:"
$form.Controls.Add($Label2)

$ComboBox1 = New-Object System.Windows.Forms.ComboBox
$ComboBox1.Size = New-Object System.Drawing.Size(250,20)
$ComboBox1.Items.Add("HardDrive Check and repair")
$ComboBox1.Items.Add("System File Check")
$ComboBox1.Items.Add("Repair the local image of Windows")
$ComboBox1.Items.Add("Update Drivers")
$ComboBox1.Items.Add("Clear Windows Store and update Cache")
$ComboBox1.Items.Add("Clear Icon Cache")
$ComboBox1.Items.Add("Clear thumbnail Cache")
$ComboBox1.Items.Add("Clear print tasks")
$ComboBox1.Location  = New-Object System.Drawing.Point(150,60)
$form.Controls.Add($ComboBox1)

# Process button

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(300,100)
$Button.Size = New-Object System.Drawing.Size(100,25)
$Button.Text = "Process"
$form.Controls.Add($Button)



# Button press
	
$Button.Add_Click({
	$Button.Text = "Busy..."
	$Button.Enabled = $false
	$Selected = $Combobox1.Text
	if ($Selected -ieq "HardDrive Check and repair")
	{
		Repair-Volume -DriveLetter C -Scan -OfflineScanAndFix -Verbose 4>&1 | Out-File .\volume_info.txt
	}
	elseif ($Selected -ieq "System File Check")
	{
		Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -Wait -Verb RunAs -WindowStyle Hidden
	}
	elseif ($Selected -ieq "Repair the local image of Windows")
	{
		Start-Process -FilePath "C:\Windows\System32\DISM.exe" -ArgumentList '/Online /Cleanup-Image /ScanHealth' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\DISM.exe" -ArgumentList '/Online /Cleanup-Image /CheckHealth' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\DISM.exe" -ArgumentList '/Online /Cleanup-Image /RestoreHealth' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\DISM.exe" -ArgumentList '/Online /Cleanup-Image /startcomponentcleanup' -Wait -Verb RunAs -WindowStyle Hidden
	}
	elseif ($Selected -ieq "Update Drivers")
	{
		$Session = New-Object -ComObject Microsoft.Update.Session
		$Searcher = $Session.CreateUpdateSearcher()
		$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
		$Searcher.SearchScope =  1 # MachineOnly
		$Searcher.ServerSelection = 3 # Third Party
		$Criteria = "IsInstalled=0 and Type='Driver' and ISHidden=0"
		$SearchResult = $Searcher.Search($Criteria)
		$Updates = $SearchResult.Updates
		$Updates | select Title, DriverModel, DriverVerDate, Driverclass, DriverManufacturer | fl
		$UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
		$updates | % { $UpdatesToDownload.Add($_) | out-null }
		$UpdateSession = New-Object -Com Microsoft.Update.Session
		$Downloader = $UpdateSession.CreateUpdateDownloader()
		$Downloader.Updates = $UpdatesToDownload
		$Downloader.Download()
		$UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
		$updates | % { if($_.IsDownloaded) { $UpdatesToInstall.Add($_) | out-null } }
		$Installer = $UpdateSession.CreateUpdateInstaller()
		$Installer.Updates = $UpdatesToInstall
		$InstallationResult = $Installer.Install()
		if($InstallationResult.RebootRequired)
		{
			Show-MessageBox -Title 'Please reboot' -Message 'Reboot required! please reboot now..' -Icon Information -Buttons OK
		}
	}
	elseif ($Selected -ieq "Clear Windows Store and update Cache")
	{
		Start-Process -FilePath "WSReset.exe" -Wait -Verb RunAs -WindowStyle Hidden
		Stop-Service -Name wuauserv
		Stop-Service -Name cryptSvc
		Stop-Service -Name bits
		Stop-Service -Name msiserver
		Remove-Item "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\*.*" -recurse -force
		Remove-Item -path "%systemroot%\SoftwareDistribution" -recurse -force
		Remove-Item -path "%systemroot%\system32\catroot2" -recurse -force
		Start-Process -FilePath "C:\Windows\System32\sc.exe" -ArgumentList 'sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\sc.exe" -ArgumentList 'sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\atl.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\urlmon.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\mshtml.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\shdocvw.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\browseui.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\jscript.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\vbscript.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\scrrun.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\msxml.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\msxml3.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\msxml6.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\actxprxy.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\softpub.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wintrust.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\dssenh.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\rsaenh.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\gpkcsp.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\sccbase.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\slbcsp.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\cryptdlg.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\oleaut32.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\ole32.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\shell32.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\initpki.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wuapi.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wuaueng.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wuaueng1.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wucltui.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wups.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wups2.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wuweb.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\qmgr.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\qmgrprxy.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wucltux.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\muweb.dll' -Wait -Verb RunAs -WindowStyle Hidden
		Start-Process -FilePath "C:\Windows\System32\regsvr32.exe" -ArgumentList '/s %windir%\system32\wuwebv.dll' -Wait -Verb RunAs -WindowStyle Hidden
		netsh winsock reset
		netsh winsock reset proxy
		Start-Service -Name wuauserv
		Start-Service -Name cryptSvc
		Start-Service -Name bits
		Start-Service -Name msiserver
	}
	elseif ($Selected -ieq "Clear Icon Cache")
	{
		Stop-Process -Name "explorer"
		Start-Sleep -Seconds 10
		set iconcache=%localappdata%\IconCache.db
		set iconcache_x=%localappdata%\Microsoft\Windows\Explorer\iconcache*
		Start-Process -FilePath "C:\Windows\System32\ie4uinit.exe" -ArgumentList '-show' -Wait -Verb RunAs -WindowStyle Hidden
		Remove-Item -path "%iconcache%\*.*" -recurse -force
		Remove-Item -path "%iconcache_x%\*.*" -recurse -force
		Start-Process -FilePath "explorer.exe"
		set iconcache=
		set iconcache_x=
	}
	elseif ($Selected -ieq "Clear thumbnail Cache")
	{
		Stop-Process -Name "explorer"
		set thumbcache_x=%localappdata%\Microsoft\Windows\Explorer\thumbcache*
		Start-Process -FilePath "C:\Windows\System32\ie4uinit.exe" -ArgumentList '-show' -Wait -Verb RunAs -WindowStyle Hidden
		Remove-Item -path "%thumbcache%\*.*" -recurse -force
		set thumbcache=
		Start-Process -FilePath "explorer.exe"
	}
	elseif ($Selected -ieq "Clear print tasks")
	{
		Stop-Service -Name spooler -Force
		Remove-Item -path "%systemroot%\System32\spool\printers\*.*" -recurse -force
		Start-Service -Name spooler
	}
	else
	{
		[System.Windows.MessageBox]::Show('Please replace user and Restart this application!','User error detected!','Ok','Error')
	}
	$Button.Text = "Process"
	$Button.Enabled = $true
})

# Closing the application

$form.Add_Closing({param($sender,$e)
    $result = [System.Windows.Forms.MessageBox]::Show(`
        "Are you sure you want to exit?", `
        "Close", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel)
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes)
    {
        $e.Cancel= $true
    }
})

$form.Add_Shown({$form.Activate()})
$form.ShowDialog() | Out-Null
$form.Dispose()

Remove-Variable -Name * -ErrorAction SilentlyContinue
exit
