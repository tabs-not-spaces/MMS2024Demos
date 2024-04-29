Add-Type -Path ".\AUTH\AuthIsEasy\bin\Debug\net8.0\Microsoft.Identity.Client.dll"
Add-Type -Path ".\AUTH\AuthIsEasy\bin\Debug\net8.0\Microsoft.Identity.Client.Broker.dll"
Add-Type -Path ".\AUTH\AuthIsEasy\bin\Debug\net8.0\Microsoft.Identity.Client.NativeInterop.dll"

$clientId = '2e8de7be-e09d-4b44-bde7-1b11ce981cd9'
$tenantId = 'patchmypc.com'
$redirectUri = "ms-appx-web://microsoft.aad.brokerplugin/$clientId"
[string[]]$scopes = @("user.read", "offline_access")

$brokerOpts = New-Object Microsoft.Identity.Client.BrokerOptions("windows")
$osIdentity = [Microsoft.Identity.Client.PublicClientApplication]::OperatingSystemAccount

$publicClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($clientId).
WithAuthority([Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic, $tenantId).
WithRedirectUri($redirectUri)
[Microsoft.Identity.Client.Broker.BrokerExtension]::WithBroker($publicClientApp, $brokerOpts) | Out-Null

$app = $publicClientApp.Build()
$authenticationResult = $app.AcquireTokenSilent($scopes, $osIdentity).ExecuteAsync().GetAwaiter().GetResult()
$authenticationResult

