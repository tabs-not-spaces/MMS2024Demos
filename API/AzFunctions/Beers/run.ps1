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
            $filter = $Request.Query.Filter
            if ($null -eq $filter) {
                Write-Host "No filter supplied, returning all beers"
                [SimpleBeerDto[]]$beers = Get-Beer -Context $ctx
                
                $statusCode = ($null -ne $beers) ? 
                [HttpStatusCode]::OK : [HttpStatusCode]::NotFound

                $body = ($null -ne $beers) ?
                $beers : @{ message = 'No beers found' }
                break;
            }
            Write-Host "Filtering beers with: $filter"
            [SimpleBeerDto[]]$filteredBeers = Get-Beer -Context $ctx -Filter $filter
            
            $statusCode = ($null -ne $filteredBeers) ?
            [HttpStatusCode]::OK : [HttpStatusCode]::NotFound

            $body = ($null -ne $filteredBeers) ?
            $filteredBeers : @{ message = 'No beers found' }
        }
        'POST' {
            if ($null -eq $Request.Body) {
                $statusCode = [HttpStatusCode]::BadRequest
                $body = @{ message = 'No beer provided' }
                break;
            }

            [Beer]$newBeer = $Request.Body
            Write-Host "Adding beer: $($newBeer.Name)"
            [DetailedBeerDto]$postedBeer = New-beer -Context -Beer $newBeer

            $statusCode = ($null -ne $postedBeer) ?
            [HttpStatusCode]::Created : [HttpStatusCode]::InternalServerError

            $body = ($null -ne $postedBeer) ?
            $postedBeer : @{ message = 'Failed to add beer' }
            $statusCode = [HttpStatusCode]::Created
            $body = @{ message = 'Beer added' }
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