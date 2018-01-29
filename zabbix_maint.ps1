###########################################
# Zabbix Maintenance Script
# Authored by Kevin Beattie
# Published October 20, 2015
# Requires PowerShell v2.0
# Some code was borrowed from http://sharpcodenotes.blogspot.com/2013/03/how-to-make-http-request-with-powershell.html

###########################################
# Variables
$url = "http://monitoringURL" # Zabbix URL
$apipath = "apiPath" # Path to API CMDLET
$apiuser="username" # API User's Username
$apipassword="password" # API User's password
$hostname="$env:computername.$env:userdnsdomain"

###########################################
# Display PowerShell Version
Write-Host "PowerShell Version: " $PSVersionTable.PSVersion | Format-List

###########################################
# JSON Data for Zabbix Authentication
$apikey = @"
{
    "jsonrpc" : "2.0",
    "method" : "user.login",
    "params": {
        "password" : "$apipassword",
        "user" : "$apiuser"
    },
    "id" : 1
}
"@

###########################################
# JSON Data for Zabbix Host
$json_hostid = @"
    {
        "jsonrpc":"2.0",
        "method":"host.get",
        "params":{
            "output":"extend",
            "filter":{
                "host":["$hostname"]} 
        },
        "auth":"$auth",
        "id": 2
    }
"@

###########################################
# Function to Pause Script for Debugging
function Pause ($Message = "Press any key to continue . . . ") {
    if ((Test-Path variable:psISE) -and $psISE) {
        $Shell = New-Object -ComObject "WScript.Shell"
        $Button = $Shell.Popup("Click OK to continue.", 0, "Script Paused", 0)
    }
    else {     
        Write-Host -NoNewline $Message
        [void][System.Console]::ReadKey($true)
        Write-Host
    }
}

###########################################
# Function to sanitize the data, throw into a hash table and teturn specific data
function FindData ($data, $pattern) {
    Write-Host "PARSING JSON DATA FOR PATTERN: ""$pattern"""
    Write-Host "RECEIVED DATA: " $data -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "SEARCH PATTERN: " $pattern -ForegroundColor Black -BackgroundColor Yellow
    $data -replace "`"", "'"
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $newdata = $ser.DeserializeObject($data)
    Write-Host "CONVERTED DATA:" $newdata -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "FOUND DATA: " $found_data -ForegroundColor Black -BackgroundColor Green
    if (!$found_data) { Write-Host "ERROR: Failed to find data based on search pattern of ""$pattern""" -ForegroundColor Red -BackgroundColor Black; Pause;}
    $found_data = $newdata.result
    $found_data
}

###########################################
# function to Deal with API Communication
function Http-Web-Request([string]$method,[string]$encoding,[string]$server,[string]$path,[string]$postData){
    ## Compose the URL and create the request
    $url = "$server/$path"
    [System.Net.HttpWebRequest] $request = [System.Net.HttpWebRequest] [System.Net.WebRequest]::Create($url)
 
    ## Add the method (GET, POST, etc.)
    $request.Method = $method
    ## Add an headers to the request
    #foreach($key in $headers.keys)
    #{
    #    $request.Headers.Add($key, $headers[$key])
    #}
    ## We are using $encoding for the request as well as the expected response
    $request.Accept = $encoding
    ## Send a custom user agent if you want
    $request.UserAgent = "PowerShell script"
 
    ## Create the request body if the verb accepts it (NOTE: utf-8 is assumed here)
    if ($method -eq "POST" -or $method -eq "PUT") {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($postData) 
        $request.ContentType = $encoding
        $request.ContentLength = $bytes.Length
         
        [System.IO.Stream] $outputStream = [System.IO.Stream]$request.GetRequestStream()
        $outputStream.Write($bytes,0,$bytes.Length)  
        $outputStream.Close()
    }
 
    ## This is where we actually make the call.  
    try
    {
        [System.Net.HttpWebResponse] $response = [System.Net.HttpWebResponse] $request.GetResponse()     
        $sr = New-Object System.IO.StreamReader($response.GetResponseStream())       
        $txt = $sr.ReadToEnd() 
        ## NOTE: comment out the next line if you don't want this function to print to the terminal
        Write-Host "CONTENT-TYPE: " $response.ContentType
        ## NOTE: comment out the next line if you don't want this function to print to the terminal
        Write-Host "RAW RESPONSE DATA:" $txt
        ## If we have XML content, print out a pretty version of it
        #if ($response.ContentType.StartsWith("text/xml"))
        #{
        #    ## NOTE: comment out the next line if you don't want this function to print to the terminal
        #    Format-XML($txt)
        #}
        ## Return the response body to the caller
        return $txt
    }
    ## This catches errors from the server (404, 500, 501, etc.)
    catch [Net.WebException] { 
        [System.Net.HttpWebResponse] $resp = [System.Net.HttpWebResponse] $_.Exception.Response  
        ## NOTE: comment out the next line if you don't want this function to print to the terminal
        Write-Host $resp.StatusCode -ForegroundColor Red -BackgroundColor Yellow
        ## NOTE: comment out the next line if you don't want this function to print to the terminal
        Write-Host $resp.StatusDescription -ForegroundColor Red -BackgroundColor Yellow
        ## Return the error to the caller
        return $resp.StatusDescription
    }
}

###########################################
# Call Zabbix API to get API Key
$result = Http-Web-Request "POST" 'application/json' $url $apipath $apikey
$apitoken = FindData $result "result"
# Write-Host "The API token variable is" $apitoken.Length "characters long." -ForegroundColor Black -BackgroundColor Yellow
if (!$apitoken) {Write-Host "ERROR: Missing API Key" -ForegroundColor Red -BackgroundColor Black; Pause;}
if (($apitoken.Length -gt 32) -or ($apitoken.Length -lt 32)) { Write-Host "ERROR: Missing API Key" -ForegroundColor Red -BackgroundColor Black; Pause; }


Write-Host "API-TOKEN: " $apitoken -ForegroundColor Black -BackgroundColor Yellow

###########################################
# Call Zabbix API to Get Host Information
$result = Http-Web-Request "POST" 'application/json' $url $apipath $json_hostid
$hostid = FindData $result "hostid"
Write-Host "Host ID: " $hostid