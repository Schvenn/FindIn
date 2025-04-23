function findin($filePattern,$string,[switch]$recurse,[switch]$quiet,[switch]$countonly,[switch]$summary,[switch]$long,[switch]$help){# Find strings in file patterns matching a regex pattern, recursively. (Use -help for more information.)

if ($help) {Write-Host -ForegroundColor White "`nUsage: " -NoNewLine; Write-Host -ForegroundColor Yellow "findin `"Regex file pattern`" `"Regex string pattern`" -recurse -quiet -countonly -long -summary -help`n"; Write-Host -ForegroundColor Yellow "-recurse" -NoNewLine; Write-Host -ForegroundColor White " to look recursively through the directory structure"; Write-Host -ForegroundColor Yellow "-quiet" -NoNewLine; Write-Host -ForegroundColor White " to suppress the messages for files where no matching pattern was found"; Write-Host -ForegroundColor Yellow "-countonly" -NoNewLine; Write-Host -ForegroundColor White " to provide the numeric results of matches found, but suppress the contextual matches found"; Write-Host -ForegroundColor Yellow "-long" -NoNewLine; Write-Host -ForegroundColor White " to provide an 80 character prefix and suffix for contextual matching, instead of 40"; Write-Host -ForegroundColor Yellow "-summary" -NoNewLine; Write-Host -ForegroundColor White " to provide a numerical summary"; Write-Host -ForegroundColor Yellow "-help" -NoNewLine; Write-Host -ForegroundColor White " to display this screen`n"; return}

if (-not $filePattern -or -not $string) {Write-Host -ForegroundColor Red "`nError: filePattern and string are required unless using -help.`n"; return}

$base=Split-Path $filePattern -Parent; if (!$base) {$base="."; $filePattern=(Split-Path $filePattern -Leaf)}; $files=Get-ChildItem -Path $base -File -Recurse:($recurse.IsPresent) -ErrorAction SilentlyContinue | Where-Object {$_.Name -match $filePattern}; $totalMatches=0; $filesChecked=0; $context=if ($long) {80} else {40}; ""

# No matching file pattern
if ($files.Count -eq 0) {Write-Host -ForegroundColor Red "`nNo files match pattern '$filePattern'.`n"} 

# Begin searching through each file
else {foreach ($file in $files) {$filesChecked++; $matchesFound=Select-String -Path $file.FullName -Pattern "(?i)$string" -AllMatches

# No matches found in file, suppress if -quiet switch used
if ($matchesFound.Count -eq 0) {if (!$quiet) {Write-Host -ForegroundColor Gray "No matches in $($file.FullName)."}} 

# -countonly switch used
else {$totalMatches+=$matchesFound.Count; if ($countonly) {Write-Host -ForegroundColor Cyan $file.FullName -NoNewLine; Write-Host -ForegroundColor Green ": $($matchesFound.Count) match(es)"} 

# Display all matches for the file, accordingly, adding truncation characters, if appropriate
else {Write-Host -ForegroundColor Yellow ("-"*100); Write-Host -ForegroundColor Yellow "File: " -NoNewLine; Write-Host -ForegroundColor Cyan $file.FullName"`n"; $matchesFound | ForEach-Object {$lineNumber=$_.LineNumber; $line=$_.Line; $matches=$_.Matches; foreach ($match in $matches) {$matchIndex=$match.Index; $matchLength=$match.Length; $start=[Math]::Max(0,$matchIndex-$context); $preMatch=$line.Substring($start,$matchIndex-$start); $matchText=$line.Substring($matchIndex,$matchLength); $postStart=$matchIndex+$matchLength; $postLength=[Math]::Min($context,$line.Length-$postStart); $postMatch=$line.Substring($postStart,$postLength); <# truncation section #> $prefix=if ($start -gt 0) {"..."} else {""}; $suffix=if (($postStart+$postLength) -lt $line.Length) {"..."} else {""}; <# end of truncation section #> Write-Host -ForegroundColor Cyan -NoNewLine "${lineNumber}, ${matchIndex}: "; Write-Host -ForegroundColor White -NoNewLine "$prefix$preMatch"; Write-Host -ForegroundColor Black -BackgroundColor Yellow -NoNewLine "$matchText"; Write-Host -ForegroundColor White "$postMatch$suffix"}}
Write-Host -ForegroundColor Green "`n$($matchesFound.Count) match(es) found.`n"}}}

# -summary switch used
if ($summary) {Write-Host -ForegroundColor Yellow ("-"*100); Write-Host -ForegroundColor Green "Summary: $totalMatches match(es) across $filesChecked file(s)."}; ""}}
