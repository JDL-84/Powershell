##https://github.com/JDL-84
##
Param(
    [Parameter(Position=1)]
    [int]$Limiter = 1000000

)
BEGIN
{

    function GetRegion
    {
          ##Wiki list of UK postcode regions
          $REGIONS = @( "AB"  , "AL"  , "B"  , "BA"  , "BB"  , "BD"  , "BH"  , "BL"  , "BN"  , "BR"  , "BS"  , "BT"  , "CA"  , "CB"  , "CF"  , "CH"  , "CM"  , "CO"  , "CR"  , "CT"  , "CV"  , "CW"  , "DA"  , "DD"  , "DE"  , "DG"  , "DH"  , "DL"  , "DN"  , "DT"  , "DY"  , "E"  , "EC"  , "EH"  , "EN"  , "EX"  , "FK"  , "FY"  , "G"  , "GL"  , "GU"  , "HA"  , "HD"  , "HG"  , "HP"  , "HR"  , "HS"  , "HU"  , "HX"  , "IG"  , "IP"  , "IV"  , "KA"  , "KT"  , "KW"  , "KY"  , "L"  , "LA"  , "LD"  , "LE"  , "LL"  , "LN"  , "LS"  , "LU"  , "M"  , "ME"  , "MK"  , "ML"  , "N"  , "NE"  , "NG"  , "NN"  , "NP"  , "NR"  , "NW"  , "OL"  , "OX"  , "PA"  , "PE"  , "PH"  , "PL"  , "PO"  , "PR"  , "RG"  , "RH"  , "RM"  , "S"  , "SA"  , "SE"  , "SG"  , "SK"  , "SL"  , "SM"  , "SN"  , "SO"  , "SP"  , "SR"  , "SS"  , "ST"  , "SW"  , "SY"  , "TA"  , "TD"  , "TF"  , "TN"  , "TQ"  , "TR"  , "TS"  , "TW"  , "UB"  , "W"  , "WA"  , "WC"  , "WD"  , "WF"  , "WN"  , "WR"  , "WS"  , "WV"  , "YO"  , "ZE"   )
          return Get-Random -InputObject $REGIONS 
    }

    function GetLetter
    {
          return (-join ((65..90) + (97..122) | Get-Random -Count 1 | % {[char]$_})).ToString().ToUpper()
    }

    function GetNumber($min, $max)
    {
          return ( (1) | ForEach-Object { Get-Random -Minimum $min -Maximum $max } ) -join ''
    }

    function GetFakePostCode
    {
        ##Random to Switch formats
        switch((GetNumber -min 1 -max 4)) 
        {
          ##   AAnn nAA
         1 {  return ("{0}{1} {2}{3}{4}" -f (GetRegion),(GetNumber -min 1 -max 99),(GetNumber -min 0 -max 9),(GetLetter),(GetLetter)) ; break}

          ##   AAAn nAA
         2 {  return ("{0}{1}{2} {3}{4}{5}" -f (GetRegion),(GetLetter),(GetNumber -min 0 -max 9),(GetNumber -min 0 -max 9),(GetLetter),(GetLetter)); break}

          ##   AAnA nAA
         3 {  return ("{0}{1}{2} {3}{4}{5}" -f (GetRegion),(GetNumber -min 0 -max 9),(GetLetter),(GetNumber -min 0 -max 9),(GetLetter),(GetLetter)); break}

        }
    }

    $Round=0

    do
    {
        $Round++
        GetFakePostCode #| Out-File -Append D:\Generated_PostCodes_UK_Unverified.log -Encoding utf8
 
    }
    while($Round -lt $Limiter)
}


