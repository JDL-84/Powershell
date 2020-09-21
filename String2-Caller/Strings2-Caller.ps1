<#
.Synopsis
   Calls STRINGS2.EXE against the preferred list of objects
   Deduplicates the output
   Runs REGEX over deduplicated output.
.DESCRIPTION
   Used to find files within binary objects.  
.EXAMPLE
   Strings2-Caller.ps1 -TYPE SourceFile -FEEDITEM C:\Windows\System32\cmd.exe
   Reads file into Strings.
.EXAMPLE
   Strings2-Caller.ps1 -TYPE SourceFolder -FEEDITEM .\input\ 
   Lists all objects in a directory and extracts the strings.
.EXAMPLE
   Strings2-Caller.ps1 -TYPE ProcessID -FEEDITEM 21236
   Validates the PID and passes it to strings. 
.EXAMPLE
   Strings2-Caller.ps1 -TYPE ProcessName -FEEDITEM WhatsApp
   Finds all processes by *NAME* and passes each to strings. 
   Output file is EXE HASH + PID (May have more that 1 running version of same file)
.LINK
   https://github.com/JDL-84/
#>
Param(
    [ValidateSet(“ProcessID”,”ProcessName”,”SourceFolder”,”SourceFile”)]
    [Parameter(Position=1,Mandatory=$true)]
    [string]$TYPE,    
    [Parameter(Position=2,Mandatory=$true)]
    [string]$FEEDITEM,
    [ValidateRange(0,10)]
    [Parameter(Position=3,Mandatory=$false)]
    [int]$MINSTRINGLENGTH = 4

)
BEGIN
{

    #Find the script locaiton
    function GetScriptDirectory
    {
        $scriptInvocation = (Get-Variable MyInvocation -Scope 1).Value
        return Split-Path $scriptInvocation.MyCommand.Path
    }

    function WriteScreen([String[]]$Text, [ConsoleColor[]]$Color) {
    for ($i = 0; $i -lt $Text.Length; $i++) 
    {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
        Write-Host
    }

    function StageOutput
    {
        param([string]$HASH)
        ##OUTPUT TO DIR BASED OFF HASH
        $OUTPUTPATH = ("./Output/{0}" -f $HASH)
                
        ##Clear the folder if the unique hash path exists
        if(!(Test-Path $OUTPUTPATH)) { New-Item -Path $OUTPUTPATH -ItemType Container |Out-Null }
        if(Test-Path $OUTPUTPATH) {Get-ChildItem -Path $OUTPUTPATH | Remove-Item -Force -Recurse}

        return $OUTPUTPATH
    }

    #Set the expected path for Foremost 
    $SD = (GetScriptDirectory)
    $STRINGSEXEPATH = ("{0}\strings.exe" -f $SD)
    $REGEXJSONPATH = ("{0}\RegEx.json" -f $SD)


    ##INITIAL STRING EXTRCT BY PROCESS

    function StringsCallerByProcessList
    {
        param([array]$ProcessList)

        if($ProcessList -ne $null)
        {
            foreach($PROC in $ProcessList)
            {
                WriteScreen -Text "TARGET:`t",$PROC.ProcessName -Color DarkGray,Gray

                ##GET HASH OF FILE
                $HASH = ("{0}_{1}" -f (Get-FileHash -Path $PROC.MainModule.FileName).Hash,$PROC.Id)

                #SET OUTPUT
                $OUTPUTPATH = StageOutput -HASH $HASH

                ##FILENAME
                $FN = $RAWFILEPATH = ("{0}/{1}" -f $OUTPUTPATH,$PROC.ProcessName)
                
                ##CALL IT	
                ##STRINGS2 does not like file paths. Get-Content via powershell and pipe to exe. 
                $RAWFILEPATH = ("{0}.RAW.LOG" -f $FN)
                WriteScreen -Text "`t - STRINGS2:",$PROC.ProcessName,"`r`n`t`t - FILE:",$RAWFILEPATH  -Color DarkGray,Gray,DarkGray,Gray                   
                &$STRINGSEXEPATH -nh -l $MINSTRINGLENGTH -pid $PROC.ID > $RAWFILEPATH

                ##DEDUPE RAW
                $DEDUPEPATH = ("{0}.DEDUPE.LOG" -f $FN)
                DeduplicateFile -RAWFILE $RAWFILEPATH -OUTFILE $DEDUPEPATH

                ##REGEX MATCHES
                WriteScreen -Text "`t - REGEXE:",$PROC.ProcessName -Color DarkGray,Gray
                RegExFile -FILE $DEDUPEPATH -FN $FN    
               
            }
        }
        else
        {
            Write-Error "PROCESS-LIST-EMPTY"
        }
    }

 
    ##INITIAL STRING EXTRCT BY FILE
    function StringsCallerByFile
    {
        Param([String]$FilePath)
      
        $File = Get-ChildItem -Path $FilePath

        WriteScreen -Text "TARGET:`t",$File.Name -Color DarkGray,Gray
        ##GET HASH OF FILE
        $HASH = (Get-FileHash -Path $File.FullName).Hash

        #SET OUTPUT
        $OUTPUTPATH = StageOutput -HASH $HASH

        ##FILENAME
        $FN = $RAWFILEPATH = ("{0}/{1}" -f $OUTPUTPATH,$File.Name)

        ##CALL IT	
        ##STRINGS2 does not like file paths. Get-Content via powershell and pipe to exe. 
        $RAWFILEPATH = ("{0}.RAW.LOG" -f $FN)
        WriteScreen -Text "`t - STRINGS2:",$File.Name,"`r`n`t`t - FILE:",$RAWFILEPATH  -Color DarkGray,Gray,DarkGray,Gray                   
        gc $File.FullName | &$STRINGSEXEPATH -nh -l $MINSTRINGLENGTH > $RAWFILEPATH

        ##DEDUPE RAW
        $DEDUPEPATH = ("{0}.DEDUPE.LOG" -f $FN)
        DeduplicateFile -RAWFILE $RAWFILEPATH -OUTFILE $DEDUPEPATH

        ##REGEX MATCHES
        WriteScreen -Text "`t - REGEXE:",$File.Name -Color DarkGray,Gray
        RegExFile -FILE $DEDUPEPATH -FN $FN                  
    }


    ##DEDUPLICATE RAW
    function DeduplicateFile
    {
        param([string]$RAWFILE,[string]$OUTFILE)

        if(Test-Path $RAWFILE)
        {                     
           WriteScreen -Text "`t - DEDUPE:",$File.Name,"`r`n`t`t - FILE:",$OUTFILE -Color DarkGray,Gray,DarkGray,Gray    
           [Linq.Enumerable]::Distinct([String[]](gc $RAWFILE ))  | Out-File $OUTFILE
         
        }
        else
        {
            Write-Error "UNABLE TO LOCATE" $RAWFILE
        }
    }       

    ##REGEX MATCHES
    function RegExFile
    {
        param([string]$FILE,[string]$FN)

        if((Test-Path $FILE) -and (Test-Path $REGEXJSONPATH))
        {                   
             
           
           ##Load JSON
           $JSON = Get-Content -Raw -Path $REGEXJSONPATH | ConvertFrom-Json

           ##LOAD FILE
           $RAW = gc $FILE

           ##Loop through JSON and find matches. 
           foreach($re in $JSON.RegExTypes)
           {
                WriteScreen -Text "`t`t - QUERY:",$re.filenamepart -Color DarkGray,Gray,DarkGray,Gray   
                ($RAW -match $re.regEX) | Foreach-Object -Begin{If(![String]::IsNullOrEmpty($_)){ continue }} -Process { $_ |  Out-File ("{0}.RegEx.{1}.LOG" -f $FN,$re.filenamepart) -Append}
           }
         
        }
        else
        {
            Write-Error "UNABLE TO LOCATE REGEX FILE(S)"
        }
    }     




    ##START
    ##Check Params 
    [bool]$VALID = $false
    if($TYPE -eq 'ProcessID') 
    {  
        if($PROCESSID -match "^\d+$")
        {
            Write-Error "MISSING PID"
        }
        else 
        {
            write-host $FEEDITEM
            StringsCallerByProcessList -ProcessList (Get-Process -Id $FEEDITEM)
        }
    }
    elseif($TYPE -eq 'ProcessName')
    {
        if([string]::IsNullOrEmpty($FEEDITEM))
        {
            Write-Error "INPUT IS EMPTY"
        }
        else
        {
            StringsCallerByProcessList -ProcessList (Get-Process | Where-Object {$_.Name -like "*$FEEDITEM*"})
        }
    }
    elseif($TYPE -eq 'SourceFolder')
    {
        if(!(Test-Path $FEEDITEM -PathType 'Container'))
        {
            Write-Error "INPUT NOT A VALID CONTAINER"
        }
        else 
        {
             $FILES = Get-ChildItem -Path $FEEDITEM -Recurse

             foreach($FILE in $FILES)
             {
                   StringsCallerByFile -File $FILE.FullName
             }
        }
    }
    elseif($TYPE -eq 'SourceFile')
    {    
    
        if(!(Test-Path $FEEDITEM -PathType 'Leaf'))
        {
            Write-Error "INPUT NOT A VALID FILE"
        }
        else 
        {
           StringsCallerByFile -File $FEEDITEM
        }
    }




}