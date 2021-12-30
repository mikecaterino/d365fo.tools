﻿param (
        [Parameter(Mandatory = $true)]
        [string] $tenant,

        [Parameter(Mandatory = $true)]
        [string] $resource,

        [Parameter(Mandatory = $true)]
        [string] $clientId,

        [Parameter(Mandatory = $true)]
        [string] $clientSecret,

        [string] $serviceGroupFilter,

        [switch] $OutputAsJson
    )

try
{
    if ($PSBoundParameters.ContainsKey('serviceGroupFilter'))
    {
        $serviceGroups = Get-D365JsonService -Name "$serviceGroupFilter" -Url "$resource" -Tenant "$tenant" -ClientId "$clientId" -ClientSecret "$clientSecret" -RawOutput
    }
    else
    {
        $serviceGroups = Get-D365JsonService -Url "$resource" -Tenant "$tenant" -ClientId "$clientId" -ClientSecret "$clientSecret" -RawOutput
    }

    $bearerParms = @{
        Resource        = $resource
        ClientId        = $clientId
        ClientSecret    = $clientSecret
        AuthProviderUri = "https://login.microsoftonline.com/$tenant/oauth2/token"
    }

    $bearer = Invoke-ClientCredentialsGrant @bearerParms | Get-BearerToken
    $headers = @{Authorization = $bearer }

    $authorized = $true
}
catch
{
    $authSuccess = $false
    "Unable to get a token."
}

if ($authorized)
{
    $apiUrl = $resource + "/api/services/"
    
    if (-not $OutputAsJson)
    {
        "Service group,Service,Method,Service response,Input parameters"
    }

    foreach($serviceGroup in $serviceGroups.ServiceGroups | Sort-Object Name)
    {
        $serviceGroupURL = $apiUrl + $serviceGroup.Name
        $serviceGroupResponse = Invoke-RestMethod $serviceGroupURL -Method 'GET' -Headers $headers        
        $serviceObject = @{}

        foreach($service in $serviceGroupResponse.Services | Sort-Object Name)
        {
            $serviceURL = $serviceGroupURL + "/" + $service.Name
            $serviceResponse = Invoke-RestMethod $serviceURL -Method 'GET' -Headers $headers
            $methodObject = @{}

            foreach($method in $serviceResponse.Operations | Sort-Object Name)
            {
                $methodURL = $serviceURL + "/" + $method.Name
                
                $serviceMethodResponse = Invoke-RestMethod $methodURL -Method 'GET' -Headers $headers

                $parameterString = ""

                foreach($parameter in $serviceMethodResponse.Parameters)
                {
                    if ($parameterString -ne "")
                    {
                        $parameterString += ";"
                    }

                    $parameterString += "[" + $parameter.Type + "]:" + $parameter.Name 
                }

                if (-not $OutputAsJson)
                {
                    $serviceGroup.Name + "," + $service.Name + "," + $method.Name + ",[" + $serviceMethodResponse.Return.Type + "]:" + $serviceMethodResponse.Return.Name + "," + $parameterString
                }

                $methodObject += @{
                                    $method.Name  = @{
                                        Response = "[" + $serviceMethodResponse.Return.Type + "]:" + $serviceMethodResponse.Return.Name
                                        InputParameters = $parameterString
                                        }
                                    }
            }

            $serviceObject += @{$service.Name = $methodObject}
        }

        $serviceGroupObject += @{$serviceGroup.Name = $serviceObject}
    }

    if ($OutputAsJson)
    {
        $serviceGroupObject | ConvertTo-Json -Depth 10
    }
}