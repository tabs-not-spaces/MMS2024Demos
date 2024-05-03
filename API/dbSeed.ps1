#region authenticate / get table context
$tableName = 'beers'
$pk = 'beers'
$ctx = ($null -ne $env:MSI_SECRET) ? 
$(New-AzDataTableContext -ManagedIdentity $env:MSI_SECRET -TableName $tableName) :
$(New-AzDataTableContext -ConnectionString $env:AzureWebJobsStorage -TableName $tableName)
#endregion

#region seed the database
$payload = Get-Content -Raw -Path ".\API\beerSeed.json" | ConvertFrom-Json -Depth 20

# Convert the Json Payload to a list of beer objects  / table entities and post them to the table
[Beer[]]$beers = $payload

Add-AzDataTableEntity -Context $ctx -Entity $beers.ToPSObject() -CreateTableIfNotExists | Out-Null
#endregion