function findin {# Find strings in file patterns matching a regex pattern, recursively.
param([string]$filePattern, [string]$string, [switch]$recurse, [switch]$quiet, [switch]$countonly, [switch]$summary, [switch]$long, [switch]$help, [switch]$load, [switch]$header, [int]$characters = 500)

# Use one of the saved search patterns.
if ($load) {$findinFile = "$PSScriptRoot\findin.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f Red "`nError: Saved search file 'find-in.txt' not found.`n"; return}
$savedSearches = Get-Content $findinFile | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {$matchName = $matches[1]; $matchPattern = $matches[2]; [PSCustomObject]@{ Name = $matchName; Pattern = $matchPattern}}
if (-not $savedSearches) {Write-Host -f Yellow "`nWarning: No valid searches found in 'find-in.txt'.`n"; return}
Write-Host -f Yellow "`nSaved Searches:`n"
for ($i=0; $i -lt $savedSearches.Count; $i++) {Write-Host -f Cyan "$($i+1). $($savedSearches[$i].Name)"}
$selection = Read-Host "`nEnter the number of the search to run"
if ($selection -match '^\d+$') {$selection = [int]$selection
if ($selection -gt 0 -and $selection -le $savedSearches.Count) {$string = $savedSearches[$selection - 1].Pattern; Write-Host -f Green "`nLoaded pattern: " -NoNewLine; Write-Host -f White $string}
else {Write-Host -f Red "`nInvalid selection. Exiting.`n"; return}}
else {Write-Host -f Red "`nInvalid selection. Exiting.`n"; return}}

# List the saved search patterns.
if ($list) {$findinFile = "$PSScriptRoot\find-in.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f Red "`nError: Saved search file 'find-in.txt' not found.`n"; return}
$savedSearches = Get-Content $findinFile | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {[PSCustomObject]@{Name = $matches[1]; Pattern = $matches[2]}}
if (-not $savedSearches) {Write-Host -f Yellow "`nWarning: No valid searches found in 'find-in.txt'.`n"; ""; return}
Write-Host -f Yellow "`nSaved Searches:"
foreach ($search in $savedSearches) {Write-Host -f Cyan ($search.Name + ":").PadRight(30) -NoNewLine; Write-Host -f White $search.Pattern}; ""; return}

# Add a new saved search pattern.
if ($add) {$findinFile = "$PSScriptRoot\find-in.txt"
$name = Read-Host "Enter a name for the search"; $pattern = Read-Host "Enter the regex pattern"
if (-not $name -or -not $pattern) {Write-Host -f Red "`nError: Both name and pattern are required.`n"; return}
$safeName = $name -replace "'", "''"; $safePattern = $pattern -replace "'", "''"
"'$safeName' '$safePattern'" | Add-Content -Encoding UTF8 -Path $findinFile
Write-Host -f Green "`nSaved '$name' to find-in.txt.`n"; return}

# Remove a saved search pattern.
if ($remove) {$findinFile = "$PSScriptRoot\find-in.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f Red "`nError: Saved search file 'find-in.txt' not found.`n"; return}
$lines = [System.Collections.Generic.List[string]]@(Get-Content $findinFile); $entries = $lines | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {[PSCustomObject]@{ Name = $matches[1]; Pattern = $matches[2] }}
if (-not $entries) {Write-Host -f Yellow "`nWarning: No valid searches found in 'find-in.txt'.`n"; return}
Write-Host -f Yellow "`nSaved Searches:`n"; for ($i = 0; $i -lt $entries.Count; $i++) {Write-Host -f Cyan "$($i+1). $($entries[$i].Name.PadRight(30))" -NoNewLine; Write-Host -f White $entries[$i].Pattern}
$choice = Read-Host "`nEnter the number of the entry to remove"
if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $entries.Count) {$index = 0; $lineIndexToRemove = -1
foreach ($line in $lines) {if ($line -match "^\s*'(.+?)'\s+'(.+)'$") {if ($index -eq ($choice - 1)) {$lineIndexToRemove = [array]::IndexOf($lines, $line); break}; $index++}}
if ($lineIndexToRemove -ge 0) {$lines.RemoveAt($lineIndexToRemove); Set-Content -Path $findinFile -Value $lines -Encoding UTF8; Write-Host -f Green "`nRemoved '$($entries[$choice - 1].Name)' from find-in.txt.`n"}
else {Write-Host -f Red "`nError: Could not find the exact line to remove.`n"}}
else {Write-Host -f Red "`nInvalid selection. Exiting.`n"}; return}

# Display the help screen.
if ($help) {Write-Host -f White "`nUsage: " -NoNewLine; Write-Host -f Yellow "findin `"Regex file pattern`" `"Regex string pattern`" -recurse -quiet -countonly -long -summary -load -list -add -remove -help`n"; 
Write-Host -f Yellow "-recurse".PadRight(10) -NoNewLine; Write-Host -f White " to look recursively through the directory structure"; 
Write-Host -f Yellow "-quiet".PadRight(10) -NoNewLine; Write-Host -f White " to suppress the messages for files where no matching pattern was found"; 
Write-Host -f Yellow "-header ##".PadRight(10) -NoNewLine; Write-Host -f White " to view the first ## (defaults to 500) characters of the file, when a match is found"; 
Write-Host -f Yellow "-countonly".PadRight(10) -NoNewLine; Write-Host -f White " to provide the numeric results of matches found, but suppress the contextual matches found"; 
Write-Host -f Yellow "-long".PadRight(10) -NoNewLine; Write-Host -f White " to provide an 80 character prefix and suffix for contextual matching, instead of 40"; 
Write-Host -f Yellow "-summary".PadRight(10) -NoNewLine; Write-Host -f White " to provide a numerical summary"; 
Write-Host -f Yellow "-load".PadRight(10) -NoNewLine; Write-Host -f White " to load a regex string from the saved options in the find-in.txt file"; 
Write-Host -f Yellow "-add".PadRight(10) -NoNewLine; Write-Host -f White " to save a new Regex pattern to the find-in.txt file"; 
Write-Host -f Yellow "-remove".PadRight(10) -NoNewLine; Write-Host -f White " to remove a Regex pattern from the find-in.txt file"; 
Write-Host -f Yellow "-help".PadRight(10) -NoNewLine; Write-Host -f White " to display this screen`n"; return}

$base=Split-Path $filePattern -Parent; if (!$base) {$base="."; $filePattern=(Split-Path $filePattern -Leaf)}; $files=Get-ChildItem -Path $base -File -Recurse:($recurse.IsPresent) -ErrorAction SilentlyContinue | Where-Object {$_.Name -match $filePattern}; $totalMatches=0; $filesChecked=0; $context=if ($long) {80} else {40}; ""

# Display the no matching file pattern error.
if ($files.Count -eq 0) {Write-Host -f Red "`nNo files match pattern '$filePattern'.`n"} 

# Begin searching through each file.
else {foreach ($file in $files) {$filesChecked++; $matchesFound=Select-String -Path $file.FullName -Pattern "(?i)$string" -AllMatches

# Indicate when there are no matches found in file, but suppress this message if the -quiet switch is used.
if ($matchesFound.Count -eq 0) {if (!$quiet) {Write-Host -f Gray "No matches in $($file.FullName)."}} 

# Display only the numeric results when the -countonly switch is used.
else {$totalMatches+=$matchesFound.Count; if ($countonly) {Write-Host -f Cyan $file.FullName -NoNewLine; Write-Host -f Green ": $($matchesFound.Count) match(es)"} 

# Display all matches for the file accordingly, adding truncation characters if appropriate.
else {Write-Host -f Yellow ("-"*100); Write-Host -f Yellow "File: " -NoNewLine; Write-Host -f Cyan $file.FullName; Write-Host -f Yellow ("-"*100)

# Display file header if requested.
if ($header) {Write-Host -f Yellow "File header, $characters characters:`n"; (Get-Content $file.FullName -Raw).Substring(0,$characters); Write-Host -f Yellow ("-"*100); ""}

$matchesFound | ForEach-Object {$lineNumber=$_.LineNumber; $line=$_.Line; $matches=$_.Matches; foreach ($match in $matches) {$matchIndex=$match.Index; $matchLength=$match.Length; $start=[Math]::Max(0,$matchIndex-$context); $preMatch=$line.Substring($start,$matchIndex-$start); $matchText=$line.Substring($matchIndex,$matchLength); $postStart=$matchIndex+$matchLength; $postLength=[Math]::Min($context,$line.Length-$postStart); $postMatch=$line.Substring($postStart,$postLength); <# truncation section #> $prefix=if ($start -gt 0) {"..."} else {""}; $suffix=if (($postStart+$postLength) -lt $line.Length) {"..."} else {""}; <# end of truncation section #> Write-Host -f Cyan -NoNewLine "${lineNumber}, ${matchIndex}: "; Write-Host -f White -NoNewLine "$prefix$preMatch"; Write-Host -f Black -BackgroundColor Yellow -NoNewLine "$matchText"; Write-Host -f White "$postMatch$suffix"}}
Write-Host -f Green "`n$($matchesFound.Count) match(es) found."}}}

# Provide final totals when the -summary switch is used.
if ($summary) {Write-Host -f Yellow ("-"*100); Write-Host -f Green "Summary: $totalMatches match(es) across $filesChecked file(s)."}; ""}}

function getheader ($file,[int]$number = 500) {# Get the header of a file for the specified number of characters
""; Write-Host -ForegroundColor Yellow ("-"*100); Write-Host -ForegroundColor Yellow "`nFile header: $file for $number characters:`n"; (Get-Content $file -Raw).Substring(0,$number); Write-Host -ForegroundColor Yellow ("-"*100); ""}
sal -Name header -Value getheader

function getline($file,[int]$linenumber){# Output a specific line number from a file to the screen and copy it to the clipboard.
""; if (Test-Path $file -ErrorAction SilentlyContinue) {$filearray = gc $file
if ($linenumber -gt $filearray.Count){$lines = $filearray.Count; Write-Host -ForegroundColor Green "$file only has $lines lines."}
else {Write-Host -ForegroundColor Cyan "$($filearray[$linenumber - 1])"; $filearray[$linenumber - 1] | Set-Clipboard}}
else {Write-Host -ForegroundColor Green "$file is not a valid filename."}; ""}

Export-ModuleMember -Function findin, getheader, getline
Export-ModuleMember -Alias header
