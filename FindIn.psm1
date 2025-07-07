function findin {# Find strings in file patterns matching a regex pattern, recursively.
param([string]$filePattern, [string]$script:string, [switch]$recurse, [switch]$quiet, [switch]$countonly, [switch]$summary, [switch]$long, [switch]$load, [switch]$header, [int]$characters = 500, [switch]$viewer, [switch]$help, [switch]$modulehelp)

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

if ($modulehelp) {# Inline help.
function scripthelp ($section) {# (Internal) Generate the help sections from the comments section of the script.
""; Write-Host -f yellow ("-" * 100); $pattern = "(?ims)^## ($section.*?)(##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; Write-Host $lines[0] -f yellow; Write-Host -f yellow ("-" * 100)
if ($lines.Count -gt 1) {wordwrap $lines[1] 100| Out-String | Out-Host -Paging}; Write-Host -f yellow ("-" * 100)}
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)")
if ($sections.Count -eq 1) {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help:" -f cyan; scripthelp $sections[0].Groups[1].Value; ""; return}

$selection = $null
do {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help Sections:`n" -f cyan; for ($i = 0; $i -lt $sections.Count; $i++) {
"{0}: {1}" -f ($i + 1), $sections[$i].Groups[1].Value}
if ($selection) {scripthelp $sections[$selection - 1].Groups[1].Value}
$input = Read-Host "`nEnter a section number to view"
if ($input -match '^\d+$') {$index = [int]$input
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index}
else {$selection = $null}} else {""; return}}
while ($true); return}

if (-not $load -and -not $help -and -not $filepattern) {$help = $true}

# Use one of the saved search patterns.
if ($load) {$findinFile = "$PSScriptRoot\findin.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f red "`nError: Saved search file 'findin.txt' not found.`n"; return}
$savedSearches = Get-Content $findinFile | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {$matchName = $matches[1]; $matchPattern = $matches[2]; [PSCustomObject]@{Name = $matchName; Pattern = $matchPattern}}
if (-not $savedSearches) {Write-Host -f yellow "`nWarning: No valid searches found in 'findin.txt'.`n"; return}
Write-Host -f yellow "`nSaved Searches:`n"
for ($i=0; $i -lt $savedSearches.Count; $i++) {Write-Host -f cyan "$($i+1). $($savedSearches[$i].Name)"}
$selection = Read-Host "`nEnter the number of the search to run"
if ($selection -match '^\d+$') {$selection = [int]$selection
if ($selection -gt 0 -and $selection -le $savedSearches.Count) {$script:string = $savedSearches[$selection - 1].Pattern; Write-Host -f green "`nLoaded pattern: " -n; Write-Host -f white $script:string}
else {Write-Host -f red "`nInvalid selection. Exiting.`n"; return}}
else {Write-Host -f red "`nInvalid selection. Exiting.`n"; return}}

# List the saved search patterns.
if ($list) {$findinFile = "$PSScriptRoot\findin.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f red "`nError: Saved search file 'findin.txt' not found.`n"; return}
$savedSearches = Get-Content $findinFile | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {[PSCustomObject]@{Name = $matches[1]; Pattern = $matches[2]}}
if (-not $savedSearches) {Write-Host -f yellow "`nWarning: No valid searches found in 'findin.txt'.`n"; ""; return}
Write-Host -f yellow "`nSaved Searches:"
foreach ($search in $savedSearches) {Write-Host -f cyan ($search.Name + ":").PadRight(30) -n; Write-Host -f white $search.Pattern}; ""; return}

# Add a new saved search pattern.
if ($add) {$findinFile = "$PSScriptRoot\findin.txt"
$name = Read-Host "Enter a name for the search"; $pattern = Read-Host "Enter the regex pattern"
if (-not $name -or -not $pattern) {Write-Host -f red "`nError: Both name and pattern are required.`n"; return}
$safeName = $name -replace "'", "''"; $safePattern = $pattern -replace "'", "''"
"'$safeName' '$safePattern'" | Add-Content -Encoding UTF8 -Path $findinFile
Write-Host -f green "`nSaved '$name' to findin.txt.`n"; return}

# Remove a saved search pattern.
if ($remove) {$findinFile = "$PSScriptRoot\findin.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f red "`nError: Saved search file 'findin.txt' not found.`n"; return}
$lines = [System.Collections.Generic.List[string]]@(Get-Content $findinFile); $entries = $lines | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {[PSCustomObject]@{Name = $matches[1]; Pattern = $matches[2]}}
if (-not $entries) {Write-Host -f yellow "`nWarning: No valid searches found in 'findin.txt'.`n"; return}
Write-Host -f yellow "`nSaved Searches:`n"; for ($i = 0; $i -lt $entries.Count; $i++) {Write-Host -f cyan "$($i+1). $($entries[$i].Name.PadRight(30))" -n; Write-Host -f white $entries[$i].Pattern}
$choice = Read-Host "`nEnter the number of the entry to remove"
if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $entries.Count) {$index = 0; $lineIndexToRemove = -1
foreach ($line in $lines) {if ($line -match "^\s*'(.+?)'\s+'(.+)'$") {if ($index -eq ($choice - 1)) {$lineIndexToRemove = [array]::IndexOf($lines, $line); break}; $index++}}
if ($lineIndexToRemove -ge 0) {$lines.RemoveAt($lineIndexToRemove); Set-Content -Path $findinFile -Value $lines -Encoding UTF8; Write-Host -f green "`nRemoved '$($entries[$choice - 1].Name)' from findin.txt.`n"}
else {Write-Host -f red "`nError: Could not find the exact line to remove.`n"}}
else {Write-Host -f red "`nInvalid selection. Exiting.`n"}; return}

# Display the help screen.
if ($help) {Write-Host -f white "`nUsage: " -n; Write-Host -f yellow "findin `"Regex file pattern`" `"Regex string pattern`" -recurse -quiet -countonly -long -summary -load -list -add -remove -help`n"
Write-Host -f yellow "-recurse".PadRight(11) -n; Write-Host -f white " to look recursively through the directory structure"
Write-Host -f yellow "-quiet".PadRight(11) -n; Write-Host -f white " to suppress the messages for files where no matching pattern was found"
Write-Host -f yellow "-header ##".PadRight(11) -n; Write-Host -f white " to view the first ## (defaults to 500) characters of the file, when a match is found"
Write-Host -f yellow "-countonly".PadRight(11) -n; Write-Host -f white " to provide the numeric results of matches found, but suppress the contextual matches found"
Write-Host -f yellow "-long".PadRight(11) -n; Write-Host -f white " to provide an 80 character prefix and suffix for contextual matching, instead of 40"
Write-Host -f yellow "-summary".PadRight(11) -n; Write-Host -f white " to provide a numerical summary"
Write-Host -f yellow "-load".PadRight(11) -n; Write-Host -f white " to load a regex string from the saved options in the findin.txt file"
Write-Host -f yellow "-add".PadRight(11) -n; Write-Host -f white " to save a new Regex pattern to the findin.txt file"
Write-Host -f yellow "-remove".PadRight(11) -n; Write-Host -f white " to remove a Regex pattern from the findin.txt file"
Write-Host -f yellow "-viewer".PadRight(11) -n; Write-Host -f white " to pass the files with matches to the internal artifact viewer interface, retaining the search terms"
Write-Host -f yellow "-help".PadRight(11) -n; Write-Host -f white " to display this screen"
Write-Host -f yellow "-modulehelp".PadRight(11) -n; Write-Host -f white " to display a helpscreen about the entire module`n"; return}

$base=Split-Path $filePattern -Parent; if (!$base) {$base="."; $filePattern=(Split-Path $filePattern -Leaf)}; $files=Get-ChildItem -Path $base -File -Recurse:($recurse.IsPresent) -ErrorAction SilentlyContinue | Where-Object {$_.Name -match $filePattern}; $totalMatches=0; $filesChecked=0; $context=if ($long) {80} else {40}; ""

# Display the no matching file pattern error.
if ($files.Count -eq 0) {Write-Host -f red "`nNo files match pattern '$filePattern'.`n"} 

# Begin searching through each file.
else {$matchedFiles = @(); $script:gzLineCounter = 0; foreach ($file in $files) {$filesChecked++

# Handle GZip files.
if ($file.Extension -eq ".gz") {try {$stream = [System.IO.File]::OpenRead($file.FullName); $gzip = New-Object System.IO.Compression.GzipStream($stream, [System.IO.Compression.CompressionMode]::Decompress); $reader = New-Object System.IO.StreamReader($gzip); $content = $reader.ReadToEnd(); $reader.Close(); $gzip.Close(); $stream.Close()
$matchesFound = $content -split "`r?`n" | ForEach-Object {$line = $_; $lineNum = $null
if ($line -match "(?i)$script:string") {$lineNum = ++$script:gzLineCounter; $mockMatch = [PSCustomObject]@{LineNumber = $lineNum; Line = $line; Matches = [regex]::Matches($line, "(?i)$script:string")}
return $mockMatch}} | Where-Object {$_ -ne $null}}
catch {Write-Host -f red "Failed to read: $($file.FullName)"}}

# Handle plaintext files.
else {$matchesFound = Select-String -Path $file.FullName -Pattern "(?i)$script:string" -AllMatches}

# Create an array of matching files
if ($matchesFound) {$matchedFiles += $file.FullName}

# Indicate when there are no matches found in file, but suppress this message if the -quiet switch is used.
if ($matchesFound.Count -eq 0) {if (!$quiet) {Write-Host -f gray "No matches in $($file.FullName)."}} 

# Display only the numeric results when the -countonly switch is used.
else {$totalMatches+=$matchesFound.Count; if ($countonly) {Write-Host -f cyan $file.FullName -n; Write-Host -f green ": $($matchesFound.Count) match(es)"} 

# Display all matches for the file accordingly, adding truncation characters if appropriate.
else {Write-Host -f yellow ("-"*100); Write-Host -f yellow "File: " -n; Write-Host -f cyan $file.FullName; Write-Host -f yellow ("-"*100)

# Display file header if requested.
if ($header) {Write-Host -f yellow "File header, $characters characters:`n"; (Get-Content $file.FullName -Raw).Substring(0,$characters); Write-Host -f yellow ("-"*100); ""}

$matchesFound | ForEach-Object {$lineNumber=$_.LineNumber; $line=$_.Line; $matches=$_.Matches; foreach ($match in $matches) {$matchIndex=$match.Index; $matchLength=$match.Length; $start=[Math]::Max(0,$matchIndex-$context); $preMatch=$line.Substring($start,$matchIndex-$start); $matchText=$line.Substring($matchIndex,$matchLength); $postStart=$matchIndex+$matchLength; $postLength=[Math]::Min($context,$line.Length-$postStart); $postMatch=$line.Substring($postStart,$postLength); <# truncation section #> $prefix=if ($start -gt 0) {"..."} else {""}; $suffix=if (($postStart+$postLength) -lt $line.Length) {"..."} else {""}; <# end of truncation section #> Write-Host -f cyan "${lineNumber}, ${matchIndex}: " -n; Write-Host -f white "$prefix$preMatch" -n; Write-Host -f black -b yellow "$matchText" -n; Write-Host -f white "$postMatch$suffix"}}
Write-Host -f green "`n$($matchesFound.Count) match(es) found."}}}

# Provide final totals when the -summary switch is used.
if ($summary) {Write-Host -f yellow ("-"*100); Write-Host -f green "Summary: $totalMatches match(es) in $($matchedfiles.count) of $filesChecked file(s)."}; ""}

# Output array.
if ($viewer) {Write-Host -f yellow "Are you ready to open the ArtifactViewer to investigate these files? (Y/N)" -n; $ready = Read-Host " "
if ($ready -match "(?i)Y") {artifactviewer -filearray $matchedFiles}
else {Write-Host -f red "Cancelled.`n"}}}

function artifactviewer ([string[]]$filearray) {# ArtifactViewer.
""; $script:viewfile = $viewfile; $script:viewfilearray = $filearray; 

# File array selection menu
function filemenu_virtual ($script:viewfilearray) {$page = 0; $perpage = 30; $script:viewfile = $null; $errormessage = $null
while ($true) {cls; $input = $null; $entryIndex = $null; $sel = $null
Write-Host -f cyan "Search Results (Page $($page + 1))`n"; $startIndex = $page * $perpage; $endIndex = [Math]::Min(($page + 1) * $perpage - 1, $script:viewfilearray.Count - 1); $paged = $script:viewfilearray[$startIndex..$endIndex]; $optionCount = 0
for ($i = 0; $i -lt $paged.Count; $i++) {$optionCount++; $name = Split-Path -Leaf $paged[$i]; Write-Host -f white "$optionCount. $name" -n; $sizeKB = try {[math]::Round(((Get-Item $paged[$i]).Length + 500) / 1KB, 0)} catch {" "}; Write-Host -f white " [$sizeKB KB]"}
if (($page + 1) * $perpage -lt $script:viewfilearray.Count) {$optionCount++; Write-Host "$optionCount. NEXT..." -f Cyan}
Write-Host -f red "`n$errormessage"; Write-Host -f White "Make a selection or press Enter" -n; $input = Read-Host " "
if (-not $input) {return}
if ($input -match '^\d+$') {$sel = [int]$input; $entryIndex = $sel - 1
if ($entryIndex -ge 0 -and $entryIndex -lt $paged.Count) {$script:viewfile = $paged[$entryIndex]; return}
elseif ($sel -eq $optionCount -and ($page + 1) * $perpage -lt $script:viewfilearray.Count) {$page++} else {$errormessage = "Invalid selection."}}
else {$errormessage = "Invalid input."}}}

filemenu_virtual $script:viewfilearray

# Error-checking
if (-not (Test-Path $script:viewfile -PathType Leaf -ErrorAction SilentlyContinue) -or (-not $script:viewfile)) {Write-Host -f red "`nNo file provided.`n"; return}
if (-not (Test-Path $script:viewfile)) {Write-Host -f red "`nFile not found.`n"; return}

# Read GZip files.
if ($script:viewfile -like "*.gz") {try {$stream = [System.IO.File]::OpenRead($script:viewfile); $gzip = New-Object System.IO.Compression.GzipStream($stream, [System.IO.Compression.CompressionMode]::Decompress); $reader = New-Object System.IO.StreamReader($gzip); $rawText = $reader.ReadToEnd(); $reader.Close(); $gzip.Close(); $stream.Close(); $content = $rawText -split "`r?`n"}
catch {Write-Host -f red "`nFailed to read compressed file: $script:viewfile`n"; return}}

# Read plaintext files.
else {$content = Get-Content $script:viewfile}

if (-not $content) {Write-Host -f red "`nFile is empty.`n"; return}

$searchTerm = $script:string; $pattern = "(?i)$script:string"; $searchHits = @(0..($content.Count - 1) | Where-Object {$content[$_] -match $pattern}); $currentSearchIndex = $searchHits[0]; $pos = 0

$content = $content | ForEach-Object {wordwrap $_ $null} | ForEach-Object {$_ -split "`n"}

$pageSize = 44; $script:viewfileName = [System.IO.Path]::GetFileName($script:viewfile)

function getbreakpoint {param($start); return [Math]::Min($start + $pageSize - 1, $content.Count - 1)}

function showpage {cls; $start = $pos; $end = getbreakpoint $start; $pageLines = $content[$start..$end]; $highlight = if ($searchTerm) {"$pattern"} else {$null}
foreach ($line in $pageLines) {if ($highlight -and $line -match $highlight) {$parts = [regex]::Split($line, "($highlight)")
foreach ($part in $parts) {if ($part -match "^$highlight$") {Write-Host -f black -b yellow $part -n}
else {Write-Host -f white $part -n}}; ""}
else {Write-Host -f white $line}}

# Pad with blank lines if this page has fewer than $pageSize lines
$linesShown = $end - $start + 1
if ($linesShown -lt $pageSize) {for ($i = 1; $i -le ($pageSize - $linesShown); $i++) {Write-Host ""}}}

# Main menu loop
$statusmessage = ""; $errormessage = ""; $searchmessage = "Search Commands"
while ($true) {showpage; $pageNum = [math]::Floor($pos / $pageSize) + 1; $totalPages = [math]::Ceiling($content.Count / $pageSize)
if ($searchHits.Count -gt 0) {$currentMatch = [array]::IndexOf($searchHits, $pos); if ($currentMatch -ge 0) {$searchmessage = "Match $($currentMatch + 1) of $($searchHits.Count)"}
else {$searchmessage = "Search active ($($searchHits.Count) matches)"}}
line yellow -double
if (-not $errormessage -or $errormessage.length -lt 1) {$middlecolour = "white"; $middle = $statusmessage} else {$middlecolour = "red"; $middle = $errormessage}
$left = "$script:fileName".PadRight(57); $middle = "$middle".PadRight(44); $right = "(Page $pageNum of $totalPages)"
Write-Host -f white $left -n; Write-Host -f $middlecolour $middle -n; Write-Host -f cyan $right
$left = "Page Commands".PadRight(55); $middle = "| $searchmessage ".PadRight(34); $right = "| Exit Commands"
Write-Host -f yellow ($left + $middle + $right)
Write-Host -f yellow "[F]irst [N]ext [+/-]# Lines p[A]ge # [P]revious [L]ast | [<][S]earch[>] [#]Match [C]lear | [D]ump [X]Edit [M]enu [Q]uit " -n
$statusmessage = ""; $errormessage = ""; $searchmessage = "Search Commands"

function getaction {[string]$buffer = ""
while ($true) {$key = [System.Console]::ReadKey($true)
switch ($key.Key) {'LeftArrow' {return 'P'}
'UpArrow' {return 'U1L'}
'Backspace' {return 'P'}
'PageUp' {return 'P'}
'RightArrow' {return 'N'}
'DownArrow' {return 'D1L'}
'PageDown' {return 'N'}
'Enter' {if ($buffer) {return $buffer}
else {return 'N'}}
'Home' {return 'F'}
'End' {return 'L'}
default {$char = $key.KeyChar
switch ($char) {',' {return '<'}
'.' {return '>'}
{$_ -match '(?i)[B-Z]'} {return $char.ToString().ToUpper()}
{$_ -match '[A#\+\-\d]'} {$buffer += $char}
default {$buffer = ""}}}}}}

$action = getaction

switch ($action.ToString().ToUpper()) {'F' {$pos = 0}
'N' {$next = getbreakpoint $pos; if ($next -lt $content.Count - 1) {$pos = $next + 1}
else {$pos = [Math]::Min($pos + $pageSize, $content.Count - 1)}}
'P' {$pos = [Math]::Max(0, $pos - $pageSize)}
'L' {$lastPageStart = [Math]::Max(0, [int][Math]::Floor(($content.Count - 1) / $pageSize) * $pageSize); $pos = $lastPageStart}

'<' {$currentSearchIndex = ($searchHits | Where-Object {$_ -lt $pos} | Select-Object -Last 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[-1]; $statusmessage = "Wrapped to last match."; $errormessage = $null}
$pos = $currentSearchIndex
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null}}
'S' {Write-Host -f green "`n`nKeyword to search forward from this point in the logs" -n; $searchTerm = Read-Host " "
if (-not $searchTerm) {$errormessage = "No keyword entered."; $statusmessage = $null; $searchTerm = $null; $searchHits = @(); continue}
$pattern = "(?i)$searchTerm"; $searchHits = @(0..($content.Count - 1) | Where-Object { $content[$_] -match $pattern })
if ($searchHits.Count -eq 0) {$errormessage = "Keyword not found in file."; $statusmessage = $null; $currentSearchIndex = -1}
else {$currentSearchIndex = $searchHits | Where-Object { $_ -gt $pos } | Select-Object -First 1
if ($null -eq $currentSearchIndex) {Write-Host -f green "No match found after this point. Jump to first match? (Y/N)" -n; $wrap = Read-Host " "
if ($wrap -match '^[Yy]$') {$currentSearchIndex = $searchHits[0]; $statusmessage = "Wrapped to first match."; $errormessage = $null}
else {$errormessage = "Keyword not found further forward."; $statusmessage = $null; $searchHits = @(); $searchTerm = $null}}
$pos = $currentSearchIndex}}
'>' {$currentSearchIndex = ($searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[0]; $statusmessage = "Wrapped to first match."; $errormessage = $null}
$pos = $currentSearchIndex
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null}}
'C' {$searchTerm = $null; $searchHits.Count = 0; $searchHits = @(); $currentSearchIndex = $null}

'D' {""; gc $script:file | more; return}
'X' {edit $script:file; "" ; return}
'M' {artifactviewer -filearray $script:viewfilearray; return}
'Q' {"`n"; return}
'U1L' {$pos = [Math]::Max($pos - 1, 0)}
'D1L' {$pos = [Math]::Min($pos + 1, $content.Count - $pageSize)}

default {if ($action -match '^[\+\-](\d+)$') {$offset = [int]$action; $newPos = $pos + $offset; $pos = [Math]::Max(0, [Math]::Min($newPos, $content.Count - $pageSize))}

elseif ($action -match '^(\d+)$') {$jump = [int]$matches[1]
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null; continue}
$targetIndex = $jump - 1
if ($targetIndex -ge 0 -and $targetIndex -lt $searchHits.Count) {$pos = $searchHits[$targetIndex]
if ($targetIndex -eq 0) {$statusmessage = "Jumped to first match."}
else {$statusmessage = "Jumped to match #$($targetIndex + 1)."}; $errormessage = $null}
else {$errormessage = "Match #$jump is out of range."; $statusmessage = $null}}

elseif ($action -match '^A(\d+)$') {$requestedPage = [int]$matches[1]
if ($requestedPage -lt 1 -or $requestedPage -gt $totalPages) {$errormessage = "Page #$requestedPage is out of range."; $statusmessage = $null}
else {$pos = ($requestedPage - 1) * $pageSize}}

else {$errormessage = "Invalid input."; $statusmessage = $null}}}}}

function getheader ($file,[int]$number = 500) {# Get the header of a file for the specified number of characters
""; if (-not $file) {Write-Host -f cyan "Usage: getheader `"filename`" ##`n"; return}; Write-Host -f yellow ("-"*100); Write-Host -f yellow "`nFile header: $file for $number characters:`n"; (Get-Content $file -Raw).Substring(0,$number); Write-Host -f yellow ("-"*100); ""}
sal -Name header -Value getheader

function getline($file,[int]$linenumber){# Output a specific line number from a file to the screen and copy it to the clipboard.
""; if (-not $file) {Write-Host -f cyan "Usage: getline `"filename`" ##`n"; return};  if (Test-Path $file -ErrorAction SilentlyContinue) {$filearray = gc $file
if ($linenumber -gt $filearray.Count){$lines = $filearray.Count; Write-Host -f green "$file only has $lines lines."}
else {Write-Host -f cyan "$($filearray[$linenumber - 1])"; $filearray[$linenumber - 1] | Set-Clipboard}}
else {Write-Host -f green "$file is not a valid filename."}; ""}

Export-ModuleMember -Function findin, getheader, getline
Export-ModuleMember -Alias header

<#
## ArtifactViewer
This integrated utility allows you to investigate each of the files with matching criteria inside an interactive file viewer.
Once inside the viewer, the options include:

Navigation:

	[F]irst page / [HOME]
	[N]ext page / [PgDn] / [Right]
	[+/-]# to move forward or back a specific # of lines / [Down] / [Up]
	p[A]ge # to jump to a specific page
	[P]revious page / [PgUp] / [Left]
	[L]ast page / [END]

Search:

	[S]earch for a term
	[<] Previous match
	[>] Next match
	[#]Number to find a specific match number
	[C]lear search term

Exit Commands:

	[D]ump to screen with | MORE and Exit
	[X]Edit using Notepad++, if available. Otherwise, use Notepad.
	[M]enu to open the file selection menu
	[Q]uit
## FindIn

	Usage: findin "Regex file pattern" "Regex string pattern" -recurse -quiet -countonly -long -summary -load -list -add -remove -help

	-recurse    to look recursively through the directory structure
	-quiet      to suppress the messages for files where no matching pattern was found
	-header #   to view the first # (defaults to 500) characters of the file, when a match is found
	-countonly  to provide the numeric results of matches found, suppressing the contextual matches
	-long       to provide an 80 character prefix and suffix for contextual matching, instead of 40
	-summary    to provide a numerical summary
	-load       to load a regex string from the saved options in the findin.txt file
	-add        to save a new Regex pattern to the findin.txt file
	-remove     to remove a Regex pattern from the findin.txt file
	-viewer     to pass the files with matches to artifactviewer, retaining the search terms
	-help       to display this screen
	-modulehelp to display a helpscreen about the entire module
	
## GetHeader

	Usage: getheader <file> <number of characters to view>
	
The default is set to 500 characters.
## GetLine

	Usage: getline <file> <line number to view>
## License
MIT License

Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>
