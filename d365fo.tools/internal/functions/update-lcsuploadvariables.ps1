﻿
<#
    .SYNOPSIS
        Update the broadcast message config variables
        
    .DESCRIPTION
        Update the active broadcast message config variables that the module will use as default values
        
    .EXAMPLE
        PS C:\> Update-BroadcastVariables
        
        This will update the broadcast variables.
        
    .NOTES
        Author: Mötz Jensen (@Splaxi)
#>

function Update-LcsUploadVariables {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [CmdletBinding()]
    [OutputType()]
    param ( )
    
    $hashParameters = Get-D365LcsApiConfig -OutputAsHashtable

    foreach ($item in $hashParameters.Keys) {
            
        $name = "LcsUpload" + (Get-Culture).TextInfo.ToTitleCase($item)
        
        Write-PSFMessage -Level Verbose -Message "$name - $($hashParameters[$item])" -Target $hashParameters[$item]
        Set-Variable -Name $name -Value $hashParameters[$item] -Scope Script
    }
}