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
            $statusCode = [HttpStatusCode]::OK
            $filter = $Request.Query.Filter
            if ($null -eq $filter) {
                write-output "No filter supplied, returning all beers"
                $body = Get-AzDataTableEntity -Context $ctx
                break;
            }
            Write-Output "Filtering beers with: $filter"
            $filteredBeers = Get-AzDataTableEntity -Context $ctx -Filter $filter
            if ($null -eq $filteredBeers) {
                write-output "No beers found for filter: $filter"
                $statusCode = [HttpStatusCode]::NotFound
                $body = @{ message = 'No beers found' }
                break;
            }
            $body = $filteredBeers
        }
        'POST' {
            if ($null -eq $Request.Body) {
                $statusCode = [HttpStatusCode]::BadRequest
                $body = @{ message = 'No beer provided' }
                break;
            }
            [Beer]$newBeer = $Request.Body
            Add-AzDataTableEntity -Context $ctx -Entity $newBeer.ToPSObject() -CreateTableIfNotExists
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