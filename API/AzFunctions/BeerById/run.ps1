using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#region authenticate / get table context
$tableName = 'beers'
$pk = 'beers'
$ctx = ($null -ne $env:MSI_SECRET) ? 
$(New-AzDataTableContext -ManagedIdentity $env:MSI_SECRET -TableName $tableName) :
$(New-AzDataTableContext -ConnectionString $env:AzureWebJobsStorage -TableName $tableName)
#endregion

try {

    switch ($Request.Method) {
        'GET' {
            $beerId = $Request.Params.id
            Write-Host "Getting beer with id: $beerId"
            [Beer]$beer = Get-AzDataTableEntity -Context $ctx -Filter "RowKey eq '$beerId'"
            if ($null -eq $beer) {
                $statusCode = [HttpStatusCode]::NotFound
                $body = @{ message = 'No beer found' }
                break;
            }
            $statusCode = [HttpStatusCode]::OK
            $body = $beer.ToPSObject()
        }
        'POST' {
            # Update the beer
            if ($null -eq $Request.Body) {
                $statusCode = [HttpStatusCode]::BadRequest
                $body = @{ message = 'No beer provided' }
                break;
            }
            $beerId = $Request.Params.id
            Write-host "Updating beer with id: $($beerId)"

            # Get the existing beer
            [Beer]$existingBeer = Get-AzDataTableEntity -Context $ctx -Filter "RowKey eq '$beerId'"

            # Convert the request body to a Beer object
            [Beer]$newBeer = $Request.Body

            # Compare the existing beer with the new beer
            Compare-PSObjectValues -ReferenceObject $existingBeer.ToPSObject() -DifferenceObject $newBeer.ToPSObject()

            # Update the beer
            Update-AzDataTableEntity -Context $ctx -Entity $newBeer.ToPSObject()

            $statusCode = [HttpStatusCode]::OK
            $body = $newBeer.ToPSObject()
        }
        'DELETE' {
            #TODO Implement delete
        }
    }
    
}
catch {
    $statusCode = [HttpStatusCode]::InternalServerError
    $body = $_.Exception.Message
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode
        Body       = $body
    })