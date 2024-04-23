<#
This PowerShell script checks whether a specified program (for example “Chrome”) is installed on a list of remote computers. 
It reads computer names from a text file and queries each computer using WMI to determine if the program is present.
#>

# Name of the program
$ProgramName = "Chrome"

# Your txt with computers
$ComputerNameList = Get-Content C:\temp\computers.txt -ReadCount 0 

function Check_Program_Installed($computer, $ProgramName) {
$wmi_check = (Get-WMIObject -ComputerName $computer -ErrorAction silentlyContinue -Query "SELECT * FROM Win32_Product Where Name Like '%$ProgramName%'").Length -gt 0

If(-not $wmi_check) {
	Write-Host "'$ProgramName' NOT is installed on computer " $computer -ForegroundColor Red;
} else {
	Write-Host "'$ProgramName' is installed on computer " $computer -ForegroundColor Green
}

}
 

foreach ($computer in $ComputerNameList) 
{
Check_Program_Installed($computer, $ProgramName)
}
