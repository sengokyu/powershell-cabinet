Set-StrictMode -Version Latest

$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | Where-Object { -not $_.Name.ToLower().Contains('.tests.') } )
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | Where-Object { -not $_.Name.ToLower().Contains('.tests.') } )

($Private+$Public) | %{ . $_.FullName }

Export-ModuleMember -Function $Public.Basename
