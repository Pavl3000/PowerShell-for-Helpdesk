<#

This script gathers information from computers on the network based on Active Directory names. It retrieves the following details:

Logged-in User Name: The name of the currently logged-in user.
MAC Address.
IP Address.
Windows Operating System Build Version.
The manufacturer or vendor of the computer.
Uptime: The duration for which the computer has been running.
Number of Connected Monitors.

 #>






 Clear-Host

# Import a list of computer names from a CSV file saved from Active Directory Users and Computers (ADUC)
# Alternatively, use Get-ADComputer to retrieve computers list from Active Directory
$ComputerNameList = (Import-Csv "C:\Report\ws.csv").name # Extracts only the first column and assigns it to the variable. ! Check column name in your csv file. 

# Path to final report document
$ReportResultPath = "C:\Report\"

# Report variuble
$Report = @()


# Main job cicle
Foreach ($Computer in $ComputerNameList){


    # Computer network status check
    $ComuterNetworkStatus = Test-Connection -ComputerName $Computer -Quiet -Count 1 -ea silentlycontinue
    if ($ComuterNetworkStatus)
        {           
            Invoke-Command -AsJob -ComputerName $Computer -ScriptBlock{
            
                # IP Address
                # Edit subnet template!
                $IPAddress = (Get-NetIPAddress | Where-Object {$_.IPAddress -like "10.46*"}).IPAddress

                # Curent session user
                If ((Get-WMIObject -ClassName Win32_ComputerSystem).Username -eq $null) {$CurrentSessionUser = "Unable to retrieve quser"}
                Else {$CurrentSessionUser = (Get-WMIObject -ClassName Win32_ComputerSystem).Username.Split('\')[1]}

                # MAC Address
                $MACAddress = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).MacAddress

                # Windows build Version
                $WindowsVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId

                # Computer Manufacturer
                $ComputerManufacturer = (Get-ComputerInfo).csManufacturer
        
                # Uptime
                $Uptime = ((Get-Date) - (Get-CimInstance -ClassName win32_operatingsystem).LastBootUpTime).days

                # Detect number of connected monitors/screens 
                $ScreenCount = (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams | where {$_.Active -like "True"} ).Active.Count
            
            
                Return [PSCustomObject]@{
                "Computer name " = $env:computername
                "Current session user " = $CurrentSessionUser
                "IP address " = $IPAddress
                "Windows version " = $WindowsVersion
                "Uptime in days " = $Uptime
                "Monitors " =  $ScreenCount
                "Computer manufacturer " = $ComputerManufacturer
                "MAC Address" = $MACAddress}
             }

        }

    else 
        {$Report += (
            [PSCustomObject]@{
            "Computer name " = $Computer
            "Current session user " = "Offline"
            "IP address " = "Offline"
            "Windows version " = "Offline"
            "Uptime in days " = "Offline"
            "Monitors " =  "Offline"
            "Computer manufacturer " = "Offline"
            "MAC Address" = "Offline"
            }
          )} 


# End of main cicle
}




# Wait for last job to complete
While (Get-Job -State "Running") {    
    Write-Output "Running..."
    Start-Sleep 5      
}    



# Getting the information back from the jobs
foreach($job in Get-Job){
    Receive-Job -Job $job -OutVariable temp
    $Report += $temp
}


Clear-Host
$Report | Format-Table -AutoSize
Get-Job | Remove-Job


$TodayDate = Get-Date -Format "yyyy.MM.dd_hh.mm"

# Export to excel
$Report | export-excel -path "$ReportResultPath\WorkStationReport_$TodayDate.xlsx" -autosize -StartRow 2 -TableName WorkStationReport



$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# Export to html
$Report | ConvertTo-Html -Head $Header | Out-File -FilePath "$ReportResultPath\WorkStationReport_$TodayDate.html"

