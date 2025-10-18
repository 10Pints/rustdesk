$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Application','System','Security'
    Level = 1,2,3
} | Select-Object TimeCreated, Id, LevelDisplayName, LogName, ProviderName, MachineName, UserId, 
    @{Name='Message'; Expression={$_.Message -replace "`r`n", " " -replace "`n", " "}}

# Export as TSV (Tab-Separated Values)
$Events | Export-Csv "C:\rustdesk-server\windows_errors_warnings.tsv" -Delimiter "`t" -NoTypeInformation