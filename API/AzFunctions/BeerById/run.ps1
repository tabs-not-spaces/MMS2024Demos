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

    switch ($Request.Method) {
        'GET' {
            # Get the beer
            $beerId = $Request.Params.id
            Write-Host "Getting beer with id: $beerId"
            [DetailedBeerDto]$beer = $(Get-Beer -Context $ctx -Filter "RowKey eq '$beerId'")

            # Set the response
            $statusCode = ($null -ne $beer) ? 
            [HttpStatusCode]::OK : 
            [HttpStatusCode]::NotFound

            $body = ($null -ne $beer) ? 
            $beer.ToPSObject() : 
            @{ message = "No beer found with id: $beerId" }
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
            [Beer]$existingBeer = Get-Beer -Context $ctx -Filter "RowKey eq '$beerId'"
            if ($null -eq $existingBeer) {
                $statusCode = [HttpStatusCode]::NotFound
                $body = @{ message = "No beer found with id: $beerId" }
                break;
            }

            # Convert the request body to a Beer object
            [Beer]$newBeer = $Request.Body

            # Update the beer
            $result = Update-Beer -Context $ctx -ExistingBeer $existingBeer -NewBeer $newBeer

            # Set the response
            $statusCode = $result ? 
            [HttpStatusCode]::OK : 
            [HttpStatusCode]::InternalServerError

            $body = $result ? 
            @{ message = "Beer with id: $beerId updated" } : 
            @{ message = "Failed to update beer with id: $beerId" }
        }
        'DELETE' {
            # Delete the beer
            $beerId = $Request.Params.id

            # Get the existing beer (if not found, return 404)
            [Beer]$existingBeer = Get-Beer -Context $ctx -Filter "RowKey eq '$beerId'"
            if ($null -eq $existingBeer) {
                $statusCode = [HttpStatusCode]::NotFound
                $body = @{ message = "No beer found with id: $beerId" }
                break;
            }

            # Delete the beer
            $result = Remove-Beer -Context $ctx -Beer $existingBeer

            # Set the response
            $statusCode = $result ?
            [HttpStatusCode]::OK :
            [HttpStatusCode]::InternalServerError

            $body = $result ?
            @{ message = "Beer with id: $beerId deleted" } :
            @{ message = "Failed to delete beer with id: $beerId" }

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