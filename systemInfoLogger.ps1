# Processor and memory properties to extract from WMI information
#+ While these are not used in this script, it may be possible to expand arrays in future versions of Powershell.
#+ Currently, a loop is required to select each element of the array.
#+ Given how unlikely it is that the names will change over time, as well as how few items there are to iterate over, it was decided to hardcode them.

# Local log name
#+ Simply save to a directory within the root of the drive. This way, if the copy fails below, the user can manually copy the file from a highly-visible place.
if (-not (test-path("$env:systemDrive\ImageLog\")))
{
    mkdir "$env:systemDrive\ImageLog\"
}

if (test-path("$env:systemDrive\ImageLog\$env:computername.log"))
{
      # File already exists.
        #+ Rename to %Filename%%Timestamp%.log
        # echo (-join($UNCPath,$env:computername,".log"))
        $oldFile = ("$env:systemDrive\ImageLog\$env:computername.log")
        $oldTime = $(get-date((get-item -Path FileSystem::$oldFile).lastwritetime) -format filedatetime)
        # echo $oldTime
        rename-item ($oldFile) (-join($env:systemDrive,"\ImageLog\",$env:computername,$oldTime,".log"))
}

# UNC Paths do not work on Windows 10 for some reason.
#+ They do, however, work on Windows 7 machines; hence the inclusion of both UNC & REST methods to copy the file over
$UNCPath = "\\redacted\redacted\redacted\redacted\redacted\ImageLogs\"

[string] $usrName = "redacted"

[string] $RESTAPIroot = "redacted"
[string] $ImageLogsLabsPath = "redacted"
[string] $uploadCommand = "redacted"
[string] $filename = "$env:computername.log"
[string] $conType = "application/octet-stream"

[string] $uniqueLog = "$env:systemDrive\ImageLog\$env:computerName.log"
[string] $logMessage= ""


# Log settings
$logMessage= -join("System Properties as of ",(get-date -format yyyyMMddTHHmmssffff).tostring())
add-content -path $uniqueLog -value $logMessage
# System Information
$computersystem = (get-wmiobject -class win32_computersystem | select-object -Property "Name","Domain","Manufacturer","Model","TotalPhysicalMemory")
$bios = (get-wmiobject -class win32_bios | select-object -property "SerialNumber")
# Processor Information
$processor = (get-wmiobject -class win32_processor -property * | select-object -Property "Name","MaxClockSpeed","AddressWidth","NumberOfCores","NumberOfLogicalProcessors")
# HDD Information
$hdd = (get-wmiobject -class win32_diskdrive | select-object Manufacturer,Model,Size , @{Name="Capacity (GB)";Expression={[math]::round($_.size / 1GB)}} )
$hddCapacity = $hdd.'Capacity (GB)'.ToString()
# MAC Addresses per physical NIC
$nic = (get-netadapter -physical | select Name,InterfaceDescription,MacAddress )
# Windows Version Information
$os = (get-ciminstance -classname win32_operatingsystem | select-object -property Caption,Version )

if(Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | where DisplayName -like "*redacted*")
{
    $antivirus = "redacted"
}
if(Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | where DisplayName -like "*redacted*")
{
    $antivirus = "redacted"
}

if (!$antivirus)
{
    $antivirus = "Windows Defender"
}

add-content -path $uniqueLog -value (-join($computersystem.Name,",",$computersystem.Domain,",",$computersystem.Manufacturer,",",$computersystem.Model,",",$computersystem.TotalPhysicalMemory,",",$bios.SerialNumber,",",$processor.Name,",",$processor.MaxClockSpeed,",",$processor.AddressWidth,",",$processor.NumberOfCores,",",$processor.NumberOfLogicalProcessors,",",$hddCapacity,",",$nic.MacAddress[0].ToString(),",",$os.Caption,",",$os.Version,",",$antivirus))

# Add blank line to end of file, in case successive reimaging appends new information to this file.
add-content -path $uniqueLog -value " "

# Copy log to network share
if (test-path($UNCPath)){
    # Try UNC path (preferred method)
    #+ Assumes user is joined to the domain and has write permission for this share.
    if (test-path((-join($UNCPath,$env:computername,".log")))){
        # File already exists.
        #+ Rename to %Filename%%Timestamp%.log
        $oldFile = (-join($UNCPath,$env:computername,".log"))
        $oldTime = $(get-date((get-item -Path FileSystem::$oldFile).lastwritetime) -format filedatetime)
        rename-item ($oldFile) (-join($UNCPath,$env:computername,$oldTime,".log"))
    }
    copy-item $uniqueLog -Destination (-join($UNCPath,$env:computername,".log"))
}
else{
    # Copy via REST API to Filr
    #+ Not as preferred, as REST API folder identifiers

    #invoke-webrequest -credential $usrName -headers @{"Authorization" = $restCredential } -uri (-join($RESTAPIroot,$ImageLogsLabsPath,$uploadCommand,$filename)) -ContentType $conType -method Post -infile $uniqueLog
    
    $filename = (-join($env:computername,$(get-date -format yyyyMMddThhmmssffff),".log"))
    invoke-webrequest -credential (get-credential $usrName) -headers @{"Authorization" = "Authorization: Basic redacted" } -uri "redactedURL?file_name=$filename" -ContentType "application/octet-stream" -method Post -infile $uniqueLog
}
# Last resort
#+ If file copy does not work, it is possible to e-mail the log files from a newly-imaged PC, so long as it has Internet access
#+ This is a comparatively insecure method, but better than nothing.
#Send-MailMessage -Attachments "$env:systemDrive\imageLog\$env:computername.log" -From redacted@redactedDomain.edu -smtpserver "redacted.redacted.com" -port redacted -subject "$env:ComputerName Properties" -To "redactedAddress@redactedDomain.edu" -credential (Get-Credential -credential redactedUsername)
sleep 15    # Wait for message to be sent
exit 0
Exit-PSHostProcess
Exit-PSSession
