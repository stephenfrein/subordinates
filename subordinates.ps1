### Pull Subordinate Info from Actiev Directory
###
### This runs in Powershell. Searches Active Directory for a list of direct reports for a specified user, and writes that list 
### to a delimited text file along with fields needed by the IDM bulk renewal template. 
        
# TODO - add option to make recursive for multiple levels of managers
        
# CHANGE THESE
$USR = 'user123' # user whose direct reports you want to capture
$OUTPUT_FILE = 'direct_reports.txt' # where will the output go?
$SEPARATOR = ';' # what goes in between the fields of output - usually comma or semicolon

Try
{
    #gets the list of direct reports for specified user
    $reports = Get-ADUser -Identity $USR -Properties directreports | Select-Object -ExpandProperty DirectReports

    #get each report on a separate line
    $lines = $reports -split "\n "

    #blank out our output file so multiple runs don't accumulate in the file
    Clear-Content $OUTPUT_FILE

    #write out the info for each direct report
    foreach ($direct in $lines) {
        Try
        {
            #get username
            $direct = $direct.Substring(0, $direct.IndexOf(",OU="))
            $direct = $direct.Replace("CN=","")
            #find real name for that user
            $record = Get-ADUser $direct
            ### QUERY FOR ADDITIONAL PROPERTIES BELOW
            $lname = $record.Surname
            $fname = $record.GivenName
            ### EXAMPLE OF FILTERING BY EMPLOYEE TYPE (employee vs contractor)
            #if contractor, save data to file
            $type = Get-ADUser -Identity $direct -Properties EmployeeType | Select-Object -ExpandProperty EmployeeType
            if ($type -eq 'E') #employee
            {
                Write-Host 'Employee will not be in output file: '$direct - $fname $lname
            }
            else #assume contractor and write to file
            {
                Add-Content $OUTPUT_FILE $direct$SEPARATOR$lname$SEPARATOR$fname
            }
            
        }
        Catch
        {
            Write-Host 'Some problem processing this direct: '$direct
            Write-Host $_.Exception.Message
        }

    }
}
Catch
{
    Write-Host 'Something went horribly wrong - sorry. :('
    Write-Host $_.Exception.Message
    Break
}
