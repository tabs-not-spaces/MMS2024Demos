using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#region authenticate / get table context
$tableName = 'beers'
$ctx = ($null -ne $env:MSI_SECRET) ? 
$(New-AzDataTableContext -ManagedIdentity $env:MSI_SECRET -TableName $tableName) :
$(New-AzDataTableContext -ConnectionString $env:AzureWebJobsStorage -TableName $tableName)
#endregion

try {
    # using a binary file (a json file) convert to type [Beer[]] and do  a mass insert
    if ($null -eq $Request.Body) {
        $statusCode = [HttpStatusCode]::BadRequest
        $body = @{ message = 'No beers provided' }
        break;
    }
    $binaryData = $Request.Body
    $jsonString = [System.Text.Encoding]::UTF8.GetString($binaryData)

    [Beer[]]$beers = $($jsonString | ConvertFrom-Json)

    Write-Host "Adding beers: $($beers.Count)"
    Add-AzDataTableEntity -Context $ctx -Entity $beers.ToPSObject() -CreateTableIfNotExists | Out-Null

    $statusCode = [HttpStatusCode]::Created
    $body = @{ message = "BeerDb seeded: $($beers.Count) beers added." }
}
catch {
    Write-Error $_.Exception.Message
    $statusCode = [HttpStatusCode]::InternalServerError
    $body = @{ message = 'An error occurred during mass upload' }
}


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode
        Body       = $body
    })
