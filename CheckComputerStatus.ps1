Clear-Host

# This script checks which computers in a list are turned on and which are turned off

# Import a list of computer names from a CSV file saved from Active Directory Users and Computers (ADUC)
# Alternatively, use Get-ADComputer to retrieve computers list from Active Directory
$ComputerNameList = (Import-Csv "C:\temp\computers.csv" -Header "1","2","3","4","5","6","7","8").1

foreach ($computer in $ComputerName) 

{
  IF (Test-Connection -BufferSize 32 -Count 1 -ComputerName $computer -Quiet) {
        Write-Host "The remote computer " $computer " is Online " -ForegroundColor Green
  } Else {
        Write-Host "The remote computer " $computer " is Offline " -ForegroundColor Red}
}
