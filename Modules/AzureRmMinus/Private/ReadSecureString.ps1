Set-StrictMode -Version Latest

function ReadSecureString([Parameter(Position=0,mandatory=$false)][String]$Prompt = 'Password:') {
    [Boolean]$Done = $false

    do {
        $SecureString = Read-Host -Prompt $Prompt -AsSecureString
        $ReSecureString = Read-Host -Prompt ('Re-type '+$Prompt) -AsSecureString

        # confirm password
        $Plain = DecryptSecureString $SecureString
        $RePlain = DecryptSecureString $ReSecureString

        if ($Plain -ceq $RePlain) {
            $Done = $true
        } else {
            Write-Host 'Mismatch; try again'
        }

    } while (!$Done)

    $SecureString
}