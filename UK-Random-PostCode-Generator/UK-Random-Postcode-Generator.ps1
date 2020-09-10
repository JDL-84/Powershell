<#
.Synopsis
   Random Unverified UK Post Code Generator
.DESCRIPTION
   Used to generate uk post codes for stress testing an internal address finder service. 
.EXAMPLE
   UK-Random-Postcode-Generator.ps1 -Limiter 1000
   Generates 1000 random post codes
.EXAMPLE
   UK-Random-Postcode-Generator.ps1 -Limiter 1000 -REGION SE
   Generates 1000 random post codes, for only SE region (SE## #AA)
.EXAMPLE
   UK-Random-Postcode-Generator.ps1 | Out-File -Append .\Generated_PostCodes_UK_Unverified.log -Encoding utf8
   Generates 1000 random post codes,
.LINK
   https://github.com/JDL-84/Powershell/tree/master/UK-Random-PostCode-Generator
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Param(
    [Parameter(Position=1)]
    [int]$LIMITER = 10000,
    [Parameter(Position=1)]
    [string]$REGION

)
BEGIN
{
    ##Wiki list of UK postcode regions
    $REGIONS = @( "AB"  , "AL"  , "B"  , "BA"  , "BB"  , "BD"  , "BH"  , "BL"  , "BN"  , "BR"  , "BS"  , "BT"  , "CA"  , "CB"  , "CF"  , "CH"  , "CM"  , "CO"  , "CR"  , "CT"  , "CV"  , "CW"  , "DA"  , "DD"  , "DE"  , "DG"  , "DH"  , "DL"  , "DN"  , "DT"  , "DY"  , "E"  , "EC"  , "EH"  , "EN"  , "EX"  , "FK"  , "FY"  , "G"  , "GL"  , "GU"  , "HA"  , "HD"  , "HG"  , "HP"  , "HR"  , "HS"  , "HU"  , "HX"  , "IG"  , "IP"  , "IV"  , "KA"  , "KT"  , "KW"  , "KY"  , "L"  , "LA"  , "LD"  , "LE"  , "LL"  , "LN"  , "LS"  , "LU"  , "M"  , "ME"  , "MK"  , "ML"  , "N"  , "NE"  , "NG"  , "NN"  , "NP"  , "NR"  , "NW"  , "OL"  , "OX"  , "PA"  , "PE"  , "PH"  , "PL"  , "PO"  , "PR"  , "RG"  , "RH"  , "RM"  , "S"  , "SA"  , "SE"  , "SG"  , "SK"  , "SL"  , "SM"  , "SN"  , "SO"  , "SP"  , "SR"  , "SS"  , "ST"  , "SW"  , "SY"  , "TA"  , "TD"  , "TF"  , "TN"  , "TQ"  , "TR"  , "TS"  , "TW"  , "UB"  , "W"  , "WA"  , "WC"  , "WD"  , "WF"  , "WN"  , "WR"  , "WS"  , "WV"  , "YO"  , "ZE"   )
    
    #Set loop counter to 0
    $ROUND=0

    function GetRegion
    {        
          return Get-Random -InputObject $REGIONS 
    }

    function CheckPassedRegion
    {
        if(![String]::IsNullOrEmpty(($REGION))) 
        { 
            ##User set post code region. 
            if(!$REGIONS.Contains($REGION.ToUpper())) { Write-Warning ("Supplied REGION '{0}' was not in list of known regions."-f $REGION)}
        }
    }

    function GetLetter
    {
          return (-join ((65..90)  | Get-Random -Count 1 | % {[char]$_}))
    }

    function GetNumber($min, $max)
    {
           return (  Get-Random -Minimum $min -Maximum $max )
    }

    function GetFakePostCode
    {
        Param([string]$SETREGION)        

        ##Check if REGION was specified, if not geneerate one. 
        if([String]::IsNullOrEmpty(($SETREGION))) { $SETREGION = (GetRegion) }
      

        ##Random to Switch formats
        switch((GetNumber -min 1 -max 4)) 
        {
          ##   AAnn nAA
         1 {  return ("{0}{1} {2}{3}{4}" -f $SETREGION,(GetNumber -min 1 -max 99),(GetNumber -min 0 -max 9),(GetLetter),(GetLetter)) ; break}

          ##   AAAn nAA
         2 {  return ("{0}{1}{2} {3}{4}{5}" -f $SETREGION,(GetLetter),(GetNumber -min 0 -max 9),(GetNumber -min 0 -max 9),(GetLetter),(GetLetter)); break}

          ##   AAnA nAA
         3 {  return ("{0}{1}{2} {3}{4}{5}" -f $SETREGION,(GetNumber -min 0 -max 9),(GetLetter),(GetNumber -min 0 -max 9),(GetLetter),(GetLetter)); break}

        }        

    }

    
    ##Check if region parameter is in the list of known regions. 
    ##Will just warn and allow it to continue. 
    CheckPassedRegion

    ##Genertate until we reach the limiter
    do
    {
        $ROUND++
        GetFakePostCode -SETREGION $REGION
 
    }
    while( $ROUND -lt $LIMITER)
}

