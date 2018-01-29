###########################################
# Jave JDK Version Checks
# Authored by Kevin Beattie
# Purpose: Outputs to STDOUT the Version of Java JSK installed, if found

Function Test-RegistryKey {
    param(
        [Parameter(Mandatory=$true)]
	[string]$key
    ) 
    process {
        if (Test-Path "$Path") {
	    return $true
        } else {
           return $false
        }
    }
} #end function Test-RegistryKey
Function Get-RegistryKeyPropertiesAndValues
{
  Param(
	[Parameter(Mandatory=$true)]
	[string]$path,
	[Parameter(Mandatory=$true)]
	[string]$key,
	[Parameter(Mandatory=$true)]
	[string]$value
  )
  # Test if the Registry Key Exists
  Write-Host "Processing: $path"
  if(Test-RegistryKey $path){
	### Get Sub-Keys 
	$AllJDKVers = Get-ChildItem -path $Path -Name
	ForEach($SubKey in $AlLJDKVers){
		Write-Host "Processing: $Path\$SubKey"
		$SubKeys = (Get-ItemProperty -Path $Path"\"$SubKey)
	}
	return $SubKeys
  } else {
	Write-Host "Key `"$path`" does not exist."
	return $false
  }
} #end function Get-RegistryKeyPropertiesAndValues
Write-Host "====== PowerShell Version:" $PSVersionTable.PSVersion "======"
$regKeyName = "Java Development Kit"
$regKeyPath64 = "HKLM:SOFTWARE\Wow6432Node\JavaSoft\$regKeyName"
$regKeyPath32 = "HKLM:SOFTWARE\JavaSoft\$regKeyName"
$regValueVersion = "CurrentVersion"
$regValueJavaHome = "JavaHome"
$JDK64 = Get-RegistryKeyPropertiesAndValues -path $regKeyPath64 -key $regKeyName -value $regValueVersion
$JDK32 = Get-RegistryKeyPropertiesAndValues -path $regKeyPath32 -key $regKeyName -value $regValueVersion
$JDKInstalled = $ENV:windir+"\temp\JDK_Detected.log"
$JDKMissing = $ENV:windir+"\temp\JDK_NOT_Detected.log"
if(($JDK64) -Or ($JDK32)){
	$ErrorActionPreference="SilentlyContinue"
	Stop-Transcript | out-null
	$ErrorActionPreference = "Continue"
	$OutputFileLocation = $JDKInstalled
	Start-Transcript -path $OutputFileLocation -append
	if($JDK64){
		$Args="-version"
		$JavaEXE=($JDK64).JavaHome+"\bin\javac.exe"
		$JavaVER= & cmd /c `"`"$JavaEXE`" $Args 2>&1`"
		Write-Host "====== Java Results ======"
		Write-Host "JavaJDK-64 File: $JavaEXE"
		Write-Host "JavaC Version: $JavaVER"
		if(Test-Path Env:JAVA_HOME){Write-Host "JAVA_HOME ENV: $ENV:JAVA_HOME"}else{Write-Host "JAVA_HOME ENV: (not set)"}
	} 
	if($JDK32){
		$Args="-version"
		$JavaEXE=($JDK32).JavaHome+"\bin\javac.exe"
		$JavaVER= & cmd /c `"`"$JavaEXE`" $Args 2>&1`"
		Write-Host "====== Java Results ======"
		Write-Host "JavaJDK-32 File: $JavaEXE"
		Write-Host "JavaJDK Version: $JavaVER"
		if(Test-Path Env:JAVA_HOME){Write-Host "JAVA_HOME ENV: $ENV:JAVA_HOME"}else{Write-Host "JAVA_HOME ENV: (not set)"}
	}
	Stop-Transcript
}
if(!($JDK64) -and !($JDK32)){
	$ErrorActionPreference="SilentlyContinue"
	Stop-Transcript | out-null
	$ErrorActionPreference = "Continue"
	$OutputFileLocation = $JDKMissing
	Start-Transcript -path $OutputFileLocation -append
	Write-Host "====== Java Results ======" | Tee-Object -file $JDKMissing
	Write-Host "JAVA JDK NOT FOUND!" | Tee-Object -file $JDKMissing
	Stop-Transcript
}
Start-Sleep -s 10