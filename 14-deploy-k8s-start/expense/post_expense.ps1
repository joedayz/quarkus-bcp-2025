Param(
    [Parameter(Mandatory = $false)] [string] $Host,
    [Parameter(Mandatory = $false)] [string] $Amount
)

if (-not $Host -or -not $Amount) {
    Write-Host "Incorrect arguments provided"
    Write-Host "    Usage: .\\post_expense.ps1 HOST AMOUNT"
    Write-Host ""
    Write-Host "    Example: .\\post_expense.ps1 localhost:8080 10"
    exit 1
}

$Url = "http://$Host/expense"

$Expense = [ordered]@{
    name          = "My Expense"
    paymentMethod = "CASH"
    amount        = $Amount
} | ConvertTo-Json -Compress

Write-Host "Posting expense to $Url"
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $Expense
    $response | Out-Host
} catch {
    Write-Error $_
    exit 1
}

Write-Host ""

