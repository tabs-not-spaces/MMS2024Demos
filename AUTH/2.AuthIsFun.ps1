#region types & config
Add-Type -Path ".\AUTH\AuthIsEasy\bin\Debug\net8.0\Microsoft.Identity.Client.dll"
Add-Type -Path ".\AUTH\AuthIsEasy\bin\Debug\net8.0\Microsoft.Identity.Client.Broker.dll"
Add-Type -Path ".\AUTH\AuthIsEasy\bin\Debug\net8.0\Microsoft.Identity.Client.NativeInterop.dll"

$clientId = '2e8de7be-e09d-4b44-bde7-1b11ce981cd9'
$tenantId = 'patchmypc.com'
$redirectUri = "ms-appx-web://microsoft.aad.brokerplugin/$clientId"
[string[]]$scopes = @("https://graph.microsoft.com/.default")
#endregion

#region auth flow
#set up broker configuration
$brokerOpts = New-Object Microsoft.Identity.Client.BrokerOptions("windows")
$osIdentity = [Microsoft.Identity.Client.PublicClientApplication]::OperatingSystemAccount

#create the public client app
$publicClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($clientId).
WithAuthority([Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic, $tenantId).
WithRedirectUri($redirectUri)

#add the broker
[Microsoft.Identity.Client.Broker.BrokerExtension]::WithBroker($publicClientApp, $brokerOpts) | Out-Null

#build the pca and acquire a token
$app = $publicClientApp.Build()
$authenticationResult = $app.AcquireTokenSilent($scopes, $osIdentity).ExecuteAsync().GetAwaiter().GetResult()
$authenticationResult
#endregion

#region create the header, make a basic graph request
$restParams = @{
    Uri         = "https://graph.microsoft.com/beta/me"
    Method      = 'GET'
    Headers     = @{ Authorization = $authenticationResult.CreateAuthorizationHeader() }
    ContentType = 'application/json'
}
$graphResponse = Invoke-RestMethod @restParams
$graphResponse
#endregion