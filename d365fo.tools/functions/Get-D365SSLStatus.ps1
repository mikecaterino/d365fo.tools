param (
        [Parameter(Mandatory = $true)]
        [string] $tenant,

        [Parameter(Mandatory = $true)]
        [string] $clientId,

        [Parameter(Mandatory = $true)]
        [string] $clientSecret,

        [Parameter()]
        [String[]] $environments,

        [Parameter()]
        [string]$environment
    )

if (-not ($PSBoundParameters.ContainsKey('environments') -or $PSBoundParameters.ContainsKey('environment')))
{
    throw "An environment or an array of environments must be provided"
}
elseif ($PSBoundParameters.ContainsKey('environments') -and $PSBoundParameters.ContainsKey('environment'))
{
    throw "An environment OR an array of environments must be provided. Both cannot be provided."
}
elseif ($PSBoundParameters.ContainsKey('environment'))
{
    $environments = @($environment)
}

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

forEach($url in $environments)
{
    try
    {
        $bearerParms = @{
        Resource        = $url.Substring(0, $url.Length-1)
        ClientId        = $clientId
        ClientSecret    = $clientSecret
        AuthProviderUri = "https://login.microsoftonline.com/$tenant/oauth2/token"
        }

        $bearer = Invoke-ClientCredentialsGrant @bearerParms | Get-BearerToken

        if ($bearer -ne '')
        {
            $authorized = $true
        }
    }
    catch
    {
        $authorized = $false
    }

    if ($authorized)
    {
        $req = [Net.HttpWebRequest]::Create($url + 'data')
        $req.PreAuthenticate = $true
        $req.Headers.Add('Authorization', $bearer)

        $req.GetResponse() | Out-Null

        try
        {
            $output = [PSCustomObject]@{'Environment' = $url
                        'Expiration' = $req.ServicePoint.Certificate.GetExpirationDateString()
                        }
        }
        catch
        {
            $output = [PSCustomObject]@{'Environment' = $url
                        'Expiration' = 'Unknown'
                        }
        }

        $output
    }
    else
    {
        "Unable to get a token."
    }
}