<#
.Synopsis
   List all files in a directory and process them with Foremost Forensic Scraper
.DESCRIPTION
   Used to find files within binary objects.  
.EXAMPLE
   Foremost-Caller.ps1 -INPUTDIRECTORY "C:\Users\JDL84\Desktop\Input"
   Generates 1000 random post codes
.LINK
   https://github.com/JDL-84/Powershell/tree/master/UK-Random-PostCode-Generator
#>
Param(
    [Parameter(Position=1,Mandatory=$true)]
    [string]$INPUTDIRECTORY

)
BEGIN
{

    #Find the script locaiton
    function GetScriptDirectory
    {
        $scriptInvocation = (Get-Variable MyInvocation -Scope 1).Value
        return Split-Path $scriptInvocation.MyCommand.Path
    }

    #Set the expected path for Foremost 
    $FOREMOSTEXEPATH = ("{0}\Foremost.exe" -f (GetScriptDirectory))

    function ForeMostCaller
    {
        ##GET THE FILES TO BE TESTED
        $FILES = Get-ChildItem -Path $INPUTDIRECTORY -Recurse

             foreach($File in $FILES)
             { 
              
                ##GET HASH OF FILE
                $HASH = (Get-FileHash -Path $File.FullName).Hash

                ##OUTPUT TO DIR BASED OFF HASH
                $OUTPUTPATH = ("./Output/{0}" -f $HASH)
                
                ##Clear the folder if the unique hash path exists
                if(Test-Path $OUTPUTPATH) {Get-ChildItem -Path $OUTPUTPATH | Remove-Item -Force -Recurse}

                ##CALL IT
                &$FOREMOSTEXEPATH -i $File.FullName -o $OUTPUTPATH

             }       
    }

    

    ##CHECK FOR FOREMOST
    if((Test-Path(("{0}\Foremost.exe" -f (GetScriptDirectory)))) -and (Test-Path(("{0}\Foremost.conf" -f (GetScriptDirectory)))))
    {
        if(Test-Path $INPUTDIRECTORY -PathType Container)
        {
             ##BEGIN
             ForeMostCaller
        }
        else
        {
             Write-Error "UNABLE TO LOCATE" $INPUTDIRECTORY
        }
    }
    else
    {
        Write-Error "MISSING-FOREMOST-FILES"
    }
}