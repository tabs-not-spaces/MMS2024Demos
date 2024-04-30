# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity
}

#region classes
class Beer {
    [string]$PartitionKey
    [string]$RowKey
    [string]$Name
    [string]$Brewery
    [string]$Country
    [string]$Style
    [string]$Abv
    [int]$Ibu
    [double]$Rating
    [string]$Description

    Beer([PSCustomObject]$beer) {
        $this.PartitionKey = 'beers'
        $this.RowKey = $beer.RowKey ?? [Guid]::NewGuid().ToString()
        $this.Name = $beer.name
        $this.Brewery = $beer.brewery
        $this.Country = $beer.country
        $this.Style = $beer.style
        $this.Abv = $beer.abv
        $this.Ibu = $beer.ibu
        $this.Rating = $beer.rating
        $this.Description = $beer.description
    }
    Beer([hashtable]$beer) {
        $this.PartitionKey = 'beers'
        $this.RowKey = $beer.RowKey ?? [Guid]::NewGuid().ToString()
        $this.Name = $beer.Name
        $this.Brewery = $beer.Brewery
        $this.Country = $beer.Country
        $this.Style = $beer.Style
        $this.Abv = $beer.Abv
        $this.Ibu = $beer.Ibu
        $this.Rating = $beer.Rating
        $this.Description = $beer.Description
    }

    [hashtable]ToHashtable() {
        return @{
            PartitionKey = $this.PartitionKey
            RowKey       = $this.RowKey
            Name         = $this.Name
            Brewery      = $this.Brewery
            Country      = $this.Country
            Style        = $this.Style
            Abv          = $this.Abv
            Ibu          = $this.Ibu
            Rating       = $this.Rating
            Description  = $this.Description
        }
    }

    [PSCustomObject]ToPSObject() {
        return [PSCustomObject]@{
            PartitionKey = $this.PartitionKey
            RowKey       = $this.RowKey
            Name         = $this.Name
            Brewery      = $this.Brewery
            Country      = $this.Country
            Style        = $this.Style
            Abv          = $this.Abv
            Ibu          = $this.Ibu
            Rating       = $this.Rating
            Description  = $this.Description
        }
    }
}

class SimpleBeerDto {
    [string]$Name
    [string]$Brewery
    [string]$Country
    [string]$Style
    [double]$Rating
    [string]$RowKey

    SimpleBeerDto([Beer]$entity) {
        $this.Name = $entity.Name
        $this.Brewery = $entity.Brewery
        $this.Country = $entity.Country
        $this.Style = $entity.Style
        $this.Rating = $entity.Rating
        $this.RowKey = $entity.RowKey
    }
}

class DetailedBeerDto {
    [string]$RowKey
    [string]$Name
    [string]$Brewery
    [string]$Country
    [string]$Style
    [string]$Abv
    [int]$Ibu
    [double]$Rating
    [string]$Description

    DetailedBeerDto([Beer]$entity) {
        $this.RowKey = $entity.RowKey
        $this.Name = $entity.Name
        $this.Brewery = $entity.Brewery
        $this.Country = $entity.Country
        $this.Style = $entity.Style
        $this.Abv = $entity.Abv
        $this.Ibu = $entity.Ibu
        $this.Rating = $entity.Rating
        $this.Description = $entity.Description
    }

    [PSCustomObject] ToPSObject() {
        return [PSCustomObject]@{
            RowKey      = $this.RowKey
            Name        = $this.Name
            Brewery     = $this.Brewery
            Country     = $this.Country
            Style       = $this.Style
            Abv         = $this.Abv
            Ibu         = $this.Ibu
            Rating      = $this.Rating
            Description = $this.Description
        }
    }
}
#endregion

#region functions
function Compare-PSObjectValues {
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]
        $ReferenceObject,

        [Parameter(Mandatory=$true)]
        [PSObject]
        $DifferenceObject
    )

    # Get the properties of the reference object
    $properties = $ReferenceObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    # Compare the values of each property
    foreach ($property in $properties) {
        $referenceValue = $ReferenceObject.$property
        $differenceValue = $DifferenceObject.$property

        if ($referenceValue -ne $differenceValue) {
            Write-Output "Property '$property' has changed. Old value: '$referenceValue'. New value: '$differenceValue'."
        }
    }
}
#endregion

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.
