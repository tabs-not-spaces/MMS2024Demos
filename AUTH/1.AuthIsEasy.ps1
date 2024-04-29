Add-Type -Path ".\AUTH\libs\Microsoft.Identity.Client.dll"

$clientId = 'a8616097-26f4-4390-85e4-d0b047403688'
$tenantId = "powers-hell.com"
[string[]]$scopes = @("user.read")

$publicClientApp = [Microsoft.Identity.Client.PublicCLientApplicationBuilder]::Create($clientId).
    WithAuthority("https://login.microsoftonline.com/$tenantId").WithDefaultRedirectUri().Build()

$authenticationResult = $publicClientApp.AcquireTokenInteractive($scopes).ExecuteAsync().GetAwaiter().GetResult()
$authenticationResult

#region How do I get the auth libraries?
# pick your dotnet version, install it, and run the following commands
dotnet new console -n "AuthIsEasy" --framework "net8.0"
Set-Location "$pwd\AuthIsEasy"
dotnet add package Microsoft.Identity.Client # other libraries are helpful Microsoft.Identity.Client.Extensions.Msal, Microsoft.Identity.Client.Broker
dotnet build
#endregion