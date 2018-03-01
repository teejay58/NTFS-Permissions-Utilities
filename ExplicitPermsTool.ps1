function Get-ExplicitPerms {

<#
.VERSION 1.0

.AUTHOR tjscott@austincc.edu

.SYNOPSIS
Recursively creates a CSV report of non-inherited permissions and owners of directories within a directory structure. 

.DESCRIPTION
Get-ExplicitPerms will recurse starting with a directory specified by the user, and produce a report of the Owner of each directory 
as well as all explicitly-assigned permissions. 

.NOTES
The script is hard-coded to exclude any directories with the words "Data" or "Users" in them. This is relevant 
to the author's environment, and it may provide useful code for whoever else wants to run this script. It 
creates a csv file that holds the results, in a place specified by the user.

.INPUTS
A string containing report location. A string containing the location where the query will begin. An integer that tells
the function how deep to recurse when looking at directories.

.OUTPUTS
A csv file report. 

.PARAMETER ReportLoc
A fully qualified path and filename for the location of the results report. You may use a mapped drive, or a fully qualified
name. i.e., C:\temp\report.csv or \\server1\data\report.csv or H:\report.csv.

.PARAMETER StartDir
The point on the server where you want to start querying permissions. Do you really want to start at the root directory?
This is one way to limit the scope of your query if necessary.

.PARAMETER LimitRecursion
This is an integer value that lets you limit how many levels to allow recursion to query. 
If you are unsure, start with 0 (zero). If you want to see more, use 1 or more for this variable. 

.EXAMPLE
Get-ExplicitPerms -ReportLoc "c:\temp\explicitperms.csv" -StartDir "\\Server1\d$\" -LimitRecursion 0

.EXAMPLE
Get-ExplicitPerms -ReportLoc "c:\temp\explicitperms.csv" -StartDir "H:\" -LimitRecursion 1


#>
 
    [CmdletBinding()]
    Param(
        [string]$ReportLoc = 'c:\temp\explicitperms.csv', [string]$StartDir = '\\Server1\d$\', [int]$LimitRecursion = 0
        )
    Begin{
    
        $csvheader = "Owner,ExplicitPerms,Directory"
    
        $doneDir = ""

        if (test-path $ReportLoc) {Remove-Item $ReportLoc} # If the csv file exists, delete it before continuing. 


        $DataObj = new-object PSObject
        $DataObj | add-member -membertype NoteProperty -name "Owner" -Value $null
        $DataObj | add-member -membertype NoteProperty -name "ExplicitPerms" -value $null
        $DataObj | add-member -membertype NoteProperty -name "Directory" -Value $null

        $OutputLine = new-object PSObject
        $OutputLine | add-member -membertype NoteProperty -name "Owner" -Value $null
        $OutputLine | add-member -membertype NoteProperty -name "ExplicitPerms" -value $null
        $OutputLine | add-member -membertype NoteProperty -name "Directory" -Value $null

        Add-Content -path $ReportLoc -value $csvheader


        Function Get-DirInfo ($ADirectory)
            {
            $DataObj.Directory = $ADirectory
            $ACL = (Get-Item -LiteralPath $ADirectory).GetAccessControl()
            $AclExpand = $acl | select -expand access
            [array]$explicitperms = ($AclExpand | where {-not $_.IsInherited}) | select identityreference
            $DataObj.ExplicitPerms = $explicitperms.identityreference
            $DataObj.owner = $acl.owner
            }


    }  # End Begin Block

    Process{
        $dirlist = Get-ChildItem -LiteralPath $startdir -Directory -Depth $LimitRecursion -Recurse | Where-Object { ($_.fullname -notlike ‘*Data*’) } | where-object {($dir -notlike '*Users*')}

        Foreach ($dir in $($dirlist.fullname)) 
            {
            Get-DirInfo -ADirectory $dir
            if ($dir -ne $donedir) 
                {              
                $outputLine.Owner = $DataObj.owner
                $Outputline.ExplicitPerms = " "
                $outputline.Directory = $dir
                $OutputLine | export-csv -path $ReportLoc -notypeinformation -append 
                $donedir = $dir
                }

            foreach ($perm in $($Dataobj.ExplicitPerms)) 
                {
                $outputLine.Owner = " "
                $outputline.ExplicitPerms = $perm
                $outputline.Directory = $dir
                $OutputLine | export-csv -path $ReportLoc -notypeinformation -append
                }

            $Outputline.owner = $null
            $outputline.ExplicitPerms = $null
            $OutputLine.Directory = $null
                
            }
    
            $donedir = $StartDir
        }  # End Process Block  


    End{
        write-output "Finished this directory structure: $DoneDir"

    }



}
