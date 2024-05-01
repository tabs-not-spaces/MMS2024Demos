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

    Beer($beer) {
        $beer = $beer -as [PSCustomObject]
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

    [SimpleBeerDto]ToSimpleBeerDto() {
        return [SimpleBeerDto]::new($this)
    }

    [DetailedBeerDto]ToDetailedBeerDto() {
        return [DetailedBeerDto]::new($this)
    }
}

class SimpleBeerDto {
    [string]$RowKey
    [string]$Name
    [string]$Country
    [string]$Style

    SimpleBeerDto($beer) {
        if ($beer -is [Beer]) {
            $this.RowKey = $beer.RowKey
            $this.Name = $beer.Name
            $this.Country = $beer.Country
            $this.Style = $beer.Style
        }
        else {
            $beer = $beer -as [PSCustomObject]
            $this.RowKey = $beer.RowKey
            $this.Name = $beer.Name
            $this.Country = $beer.Country
            $this.Style = $beer.Style
        }
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

    DetailedBeerDto($beer) {
        if ($beer -is [Beer]) {
            $this.RowKey = $beer.RowKey
            $this.Name = $beer.Name
            $this.Brewery = $beer.Brewery
            $this.Country = $beer.Country
            $this.Style = $beer.Style
            $this.Abv = $beer.Abv
            $this.Ibu = $beer.Ibu
            $this.Rating = $beer.Rating
            $this.Description = $beer.Description
        }
        else {
            $beer = $beer -as [PSCustomObject]
            $this.RowKey = $beer.RowKey
            $this.Name = $beer.Name
            $this.Brewery = $beer.Brewery
            $this.Country = $beer.Country
            $this.Style = $beer.Style
            $this.Abv = $beer.Abv
            $this.Ibu = $beer.Ibu
            $this.Rating = $beer.Rating
            $this.Description = $beer.Description
        }
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
        [Parameter(Mandatory = $true)]
        [PSObject]
        $ReferenceObject,

        [Parameter(Mandatory = $true)]
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
            Write-Host "Property '$property' has changed. Old value: '$referenceValue'. New value: '$differenceValue'."
        }
    }
}

function Get-Beer {
    [OutputType([Beer])]
    [OutputType([SimpleBeerDto[]])]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PipeHow.AzBobbyTables.AzDataTableContext]$Context,

        [Parameter(Mandatory = $false)]
        [string]$Filter = $null
    )

    try {
        if ($null -eq $Filter) {
            Write-Host "No filter supplied, returning all beers"
            [Beer[]]$beers = Get-AzDataTableEntity -Context $Context
            return $beers
        }
        Write-Host "Filtering beers with: $Filter"
        [Beer[]]$filteredBeers = Get-AzDataTableEntity -Context $Context -Filter $Filter
        return $filteredBeers
    }
    catch {
        Write-Warning $_.Exception.Message
        return $null
    }
}

function New-Beer {
    [OutputType([Beer])]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PipeHow.AzBobbyTables.AzDataTableContext]$Context,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Beer
    )

    try {
        [Beer]$newBeer = $Beer
        Write-Host "Adding beer: $($newBeer.Name)"
        Add-AzDataTableEntity -Context $Context -Entity $newBeer.ToPSObject() -CreateTableIfNotExists
        return $newBeer
    }
    catch {
        Write-Warning $_.Exception.Message
        return $null
    }
}

function Update-Beer {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PipeHow.AzBobbyTables.AzDataTableContext]$Context,

        [Parameter(Mandatory = $true)]
        [Beer]$ExistingBeer,

        [Parameter(Mandatory = $true)]
        [Beer]$NewBeer
    )

    try {
        # Compare the existing beer with the new beer
        Compare-PSObjectValues -ReferenceObject $ExistingBeer.ToPSObject() -DifferenceObject $NewBeer.ToPSObject()

        # Update the beer
        Write-Host "Updating beer with id: $($ExistingBeer.RowKey)"
        Update-AzDataTableEntity -Context $Context -Entity $NewBeer.ToPSObject()

        return $true
    }
    catch {
        Write-Warning $_.Exception.Message
        return $false
    }
}

function Remove-Beer {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PipeHow.AzBobbyTables.AzDataTableContext]$Context,

        [Parameter(Mandatory = $true)]
        [Beer]$Beer
    )

    try {
        Write-Host "Deleting beer with id: $RowKey"
        Remove-AzDataTableEntity -Context $Context -Entity $Beer.ToPSObject()
        return $true
    }
    catch {
        Write-Warning $_.Exception.Message
        return $false
    }
}

#endregion

