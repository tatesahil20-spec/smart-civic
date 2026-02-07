$content = Get-Content "assets/main-Dt0d425S.js" -Raw
$index = $content.IndexOf("calendar")
if ($index -ge 0) {
    $start = [Math]::Max(0, $index - 100)
    $length = [Math]::Min($content.Length - $start, 200)
    Write-Output "Found 'calendar' at index $index"
    Write-Output "Context: ...$($content.Substring($start, $length))..."
} else {
    Write-Output "Not found 'calendar'"
}

$index2 = $content.IndexOf("citizen")
if ($index2 -ge 0) {
    $start = [Math]::Max(0, $index2 - 100)
    $length = [Math]::Min($content.Length - $start, 200)
    Write-Output "Found 'citizen' at index $index2"
    Write-Output "Context: ...$($content.Substring($start, $length))..."
} else {
    Write-Output "Not found 'citizen'"
}
