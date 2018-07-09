Set-StrictMode -Version Latest

function DecryptSecureString {
    param(
        [parameter(position=0,mandatory=$true)]
        [System.Security.SecureString]
        $SecureString
    )

    $BStr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BStr)
}