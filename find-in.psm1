function findin {# Find strings in file patterns matching a regex pattern, recursively.
param([string]$filePattern, [string]$script:string, [switch]$recurse, [switch]$quiet, [switch]$countonly, [switch]$summary, [switch]$long, [switch]$load, [switch]$header, [int]$characters = 500, [switch]$viewer, [switch]$help, [switch]$modulehelp)

if ($modulehelp) {# Inline help.
function wordwrap ($field, [int]$maximumlinelength = 65) {# Modify fields sent to it with proper word wrapping.
if ($null -eq $field -or $field.Length -eq 0) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()

foreach ($line in $field -split "`n") {if ($line.Trim().Length -eq 0) {$wrapped += ''; continue}
$remaining = $line.Trim()
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1

foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakChar = $char; $breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1; $breakChar = ''}
$chunk = $segment.Substring(0, $breakIndex + 1).TrimEnd(); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1).TrimStart()}

if ($remaining.Length -gt 0) {$wrapped += $remaining}}
return ($wrapped -join "`n")}

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
if (-not (Test-Path $findinFile)) {Write-Host -f red "`nError: Saved search file 'find-in.txt' not found.`n"; return}
$savedSearches = Get-Content $findinFile | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {$matchName = $matches[1]; $matchPattern = $matches[2]; [PSCustomObject]@{ Name = $matchName; Pattern = $matchPattern}}
if (-not $savedSearches) {Write-Host -f yellow "`nWarning: No valid searches found in 'find-in.txt'.`n"; return}
Write-Host -f yellow "`nSaved Searches:`n"
for ($i=0; $i -lt $savedSearches.Count; $i++) {Write-Host -f cyan "$($i+1). $($savedSearches[$i].Name)"}
$selection = Read-Host "`nEnter the number of the search to run"
if ($selection -match '^\d+$') {$selection = [int]$selection
if ($selection -gt 0 -and $selection -le $savedSearches.Count) {$script:string = $savedSearches[$selection - 1].Pattern; Write-Host -f green "`nLoaded pattern: " -n; Write-Host -f white $script:string}
else {Write-Host -f red "`nInvalid selection. Exiting.`n"; return}}
else {Write-Host -f red "`nInvalid selection. Exiting.`n"; return}}

# List the saved search patterns.
if ($list) {$findinFile = "$PSScriptRoot\find-in.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f red "`nError: Saved search file 'find-in.txt' not found.`n"; return}
$savedSearches = Get-Content $findinFile | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {[PSCustomObject]@{Name = $matches[1]; Pattern = $matches[2]}}
if (-not $savedSearches) {Write-Host -f yellow "`nWarning: No valid searches found in 'find-in.txt'.`n"; ""; return}
Write-Host -f yellow "`nSaved Searches:"
foreach ($search in $savedSearches) {Write-Host -f cyan ($search.Name + ":").PadRight(30) -n; Write-Host -f white $search.Pattern}; ""; return}

# Add a new saved search pattern.
if ($add) {$findinFile = "$PSScriptRoot\find-in.txt"
$name = Read-Host "Enter a name for the search"; $pattern = Read-Host "Enter the regex pattern"
if (-not $name -or -not $pattern) {Write-Host -f red "`nError: Both name and pattern are required.`n"; return}
$safeName = $name -replace "'", "''"; $safePattern = $pattern -replace "'", "''"
"'$safeName' '$safePattern'" | Add-Content -Encoding UTF8 -Path $findinFile
Write-Host -f green "`nSaved '$name' to find-in.txt.`n"; return}

# Remove a saved search pattern.
if ($remove) {$findinFile = "$PSScriptRoot\find-in.txt"
if (-not (Test-Path $findinFile)) {Write-Host -f red "`nError: Saved search file 'find-in.txt' not found.`n"; return}
$lines = [System.Collections.Generic.List[string]]@(Get-Content $findinFile); $entries = $lines | Where-Object {$_ -match "^\s*'(.+?)'\s+'(.+)'$"} | ForEach-Object {[PSCustomObject]@{ Name = $matches[1]; Pattern = $matches[2] }}
if (-not $entries) {Write-Host -f yellow "`nWarning: No valid searches found in 'find-in.txt'.`n"; return}
Write-Host -f yellow "`nSaved Searches:`n"; for ($i = 0; $i -lt $entries.Count; $i++) {Write-Host -f cyan "$($i+1). $($entries[$i].Name.PadRight(30))" -n; Write-Host -f white $entries[$i].Pattern}
$choice = Read-Host "`nEnter the number of the entry to remove"
if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $entries.Count) {$index = 0; $lineIndexToRemove = -1
foreach ($line in $lines) {if ($line -match "^\s*'(.+?)'\s+'(.+)'$") {if ($index -eq ($choice - 1)) {$lineIndexToRemove = [array]::IndexOf($lines, $line); break}; $index++}}
if ($lineIndexToRemove -ge 0) {$lines.RemoveAt($lineIndexToRemove); Set-Content -Path $findinFile -Value $lines -Encoding UTF8; Write-Host -f green "`nRemoved '$($entries[$choice - 1].Name)' from find-in.txt.`n"}
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
Write-Host -f yellow "-load".PadRight(11) -n; Write-Host -f white " to load a regex string from the saved options in the find-in.txt file"
Write-Host -f yellow "-add".PadRight(11) -n; Write-Host -f white " to save a new Regex pattern to the find-in.txt file"
Write-Host -f yellow "-remove".PadRight(11) -n; Write-Host -f white " to remove a Regex pattern from the find-in.txt file"
Write-Host -f yellow "-viewer".PadRight(11) -n; Write-Host -f white " to pass the files with matches to the internal artifact viewer interface, retaining the search terms"
Write-Host -f yellow "-help".PadRight(11) -n; Write-Host -f white " to display this screen"
Write-Host -f yellow "-modulehelp".PadRight(11) -n; Write-Host -f white " to display a helpscreen about the entire module`n"; return}

$base=Split-Path $filePattern -Parent; if (!$base) {$base="."; $filePattern=(Split-Path $filePattern -Leaf)}; $files=Get-ChildItem -Path $base -File -Recurse:($recurse.IsPresent) -ErrorAction SilentlyContinue | Where-Object {$_.Name -match $filePattern}; $totalMatches=0; $filesChecked=0; $context=if ($long) {80} else {40}; ""

# Display the no matching file pattern error.
if ($files.Count -eq 0) {Write-Host -f red "`nNo files match pattern '$filePattern'.`n"} 

# Begin searching through each file.
else {$matchedFiles = @(); foreach ($file in $files) {$filesChecked++; $matchesFound=Select-String -Path $file.FullName -Pattern "(?i)$script:string" -AllMatches

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
""; $script:viewfile = $viewfile; $script:viewfilearray = $filearray; $searchTerm = $script:string; $pattern = "(?i)$script:string"; $searchHits = @(0..($content.Count - 1) | Where-Object {$content[$_] -match $pattern}); $currentSearchIndex = $searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1; $pos = $currentSearchIndex

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

# Read log content once
$content = Get-Content $script:viewfile
if (-not $content) {Write-Host -f red "`nFile is empty.`n"; return}

$separators = @(0) + (0..($content.Count - 1) | Where-Object {$content[$_] -match '^[=]{100}$'}); $pageSize = 35; $pos = 0; $script:viewfileName = [System.IO.Path]::GetFileName($script:viewfile); $searchHits = @(); $currentSearchIndex = -1

function Get-BreakPoint {param($start), $maxEnd = [Math]::Min($start + $pageSize - 1, $content.Count - 1); for ($i = $start + 29; $i -le $maxEnd; $i++) {if ($content[$i] -match '^[-=]{100}$') {return $i}}; return $maxEnd}

function Show-Page {cls; $start = $pos; $end = Get-BreakPoint $start; $pageLines = $content[$start..$end]; $highlight = if ($searchTerm) {$pattern} else {$null}
foreach ($line in $pageLines) {if ($line -match '^[-=]{100}$') {Write-Host -f Yellow $line}
elseif ($highlight -and $line -match $highlight) {$parts = [regex]::Split($line, "($highlight)")
foreach ($part in $parts) {if ($part -match "^$highlight$") {Write-Host -f black -b yellow $part -n}
else {Write-Host -f white $part -n}}; ""}
else {Write-Host -f white $line}}

# Pad with blank lines if this page has fewer than $pageSize lines
$linesShown = $end - $start + 1
if ($linesShown -lt $pageSize) {for ($i = 1; $i -le ($pageSize - $linesShown); $i++) {Write-Host ""}}}

$errormessage = ""; $searchmessage = "Search Commands"
# Main menu loop
while ($true) {Show-Page; $pageNum = [math]::Floor($pos / $pageSize) + 1; $totalPages = [math]::Ceiling($content.Count / $pageSize)
if ($searchHits.Count -gt 0) {$currentMatch = ($searchHits | Where-Object {$_ -eq $pos} | ForEach-Object {[array]::IndexOf($searchHits, $_) + 1})
if ($currentMatch) {$searchmessage = "Match $currentMatch of $($searchHits.Count)"}}
Write-Host ""; Write-Host -f yellow ("=" * 120)
$left = "$script:viewfileName".PadRight(57); $middle = "$errormessage".PadRight(44); $right = "(Page $pageNum of $totalPages)"
Write-Host -f white $left -n; Write-Host -f red $middle -n; Write-Host -f cyan $right
$left = "Page Commands".PadRight(55); $middle = "| $searchmessage ".PadRight(35); $right = "| Exit Commands"
Write-Host -f yellow ($left + $middle + $right)
Write-Host -f yellow "[F]irst [N]ext [+/-]# Lines p[A]ge # [P]revious [L]ast | [<][S]earch[>] [#]Number [C]lear | [D]ump [X]Edit [M]enu [Q]uit" -n; $action = Read-Host " "
$errormessage = ""; $searchmessage = "Search Commands"

if ($action -match '^[+-]?\d+$') {$offset = [int]$action; $newPos = $pos + $offset; $pos = [Math]::Max(0, [Math]::Min($newPos, $content.Count - $pageSize))}

if ($action -match '^#([+-]?\d+)$') {$jump = [int]$matches[1]
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."}
else {if ($jump -ge 1 -or $jump -le -1) {$targetIndex = if ($jump -lt 0) {[Math]::Max(0, $currentSearchIndex + $jump)} 
else {$jump - 1}
if ($targetIndex -ge 0 -and $targetIndex -lt $searchHits.Count) {$pos = $searchHits[$targetIndex]; $errormessage = "Jumped to match #$($targetIndex + 1)."} 
else {$errormessage = "Match #$jump is out of range."}} 
else {$pos = $searchHits[0]; $errormessage = "Jumped to first match."}}}

if ($action -match '^A(\d+)$') {$requestedPage = [int]$matches[1]
if ($requestedPage -lt 1 -or $requestedPage -gt $totalPages) {$errormessage = "Page #$requestedPage is out of range."}
else {$pos = ($requestedPage - 1) * $pageSize}}

switch ($action.ToUpper()) {'F' {$pos = 0}
'N' {$next = Get-BreakPoint $pos; if ($next -lt $content.Count - 1) {$pos = $next + 1} else {$pos = [Math]::Min($pos + $pageSize, $content.Count - 1)}}
'P' {$pos = [Math]::Max(0, $pos - $pageSize)}
'L' {$lastPageStart = [Math]::Max(0, [int][Math]::Floor(($content.Count - 1) / $pageSize) * $pageSize); $pos = $lastPageStart}
'<' {$currentSearchIndex = ($searchHits | Where-Object {$_ -lt $pos} | Select-Object -Last 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[-1]; $errormessage = "Wrapped to last match."}
$pos = $currentSearchIndex}
'S' {Write-Host -f green "Keyword to search forward from this point in the logs" -n; $searchTerm = Read-Host " "
if (-not $searchTerm) {$errormessage = "No keyword entered."; $searchTerm = $null; $searchHits = @(); break}
$pattern = "(?i)$searchTerm"; $searchHits = @(0..($content.Count - 1) | Where-Object {$content[$_] -match $pattern})
if (-not $searchHits) {$errormessage = "Keyword not found in file."; $searchHits = @(); $currentSearchIndex = -1}
$currentSearchIndex = $searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1
if ($null -eq $currentSearchIndex) {Write-Host -f green "No match found after this point. Jump to first match? (Y/N)" -n; $wrap = Read-Host " "
if ($wrap -match '^[Yy]$') {$currentSearchIndex = $searchHits[0]}
else {$errormessage = "Keyword not found further forward."; $searchHits = @()}}
$pos = $currentSearchIndex}
'>' {$currentSearchIndex = ($searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[0]; $errormessage = "Wrapped to first match."}
$pos = $currentSearchIndex}
'C' {$searchTerm = $null; $searchHits.Count = 0; $searchHits = @(); $currentSearchIndex = $null}
'D' {""; gc $script:viewfile | more; return}
'X' {edit $script:viewfile; "" ; return}
'M' {artifactviewer -filearray $script:viewfilearray; return}
'Q' {""; return}
default {Write-Host -f red "`nInvalid input.`n"}}}}

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
## artifactviewer
This integrated utility allows you to investigate each of the files with matching criteria inside an interactive file viewer.
Once inside the viewer, the options include:

Navigation:

	[F]irst page
	[N]ext page
	[+/-]# to move forward or back a specific # of lines
	p[A]ge # to jump to a specific page
	[P]revious page
	[L]ast page

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
## findin

	Usage: findin "Regex file pattern" "Regex string pattern" -recurse -quiet -countonly -long -summary -load -list -add -remove -help

	-recurse    to look recursively through the directory structure
	-quiet      to suppress the messages for files where no matching pattern was found
	-header #   to view the first # (defaults to 500) characters of the file, when a match is found
	-countonly  to provide the numeric results of matches found, but suppress the contextual matches found
	-long       to provide an 80 character prefix and suffix for contextual matching, instead of 40
	-summary    to provide a numerical summary
	-load       to load a regex string from the saved options in the find-in.txt file
	-add        to save a new Regex pattern to the find-in.txt file
	-remove     to remove a Regex pattern from the find-in.txt file
	-viewer     to pass the files with matches to the internal artifact viewer interface, retaining the search terms
	-help       to display this screen
	-modulehelp to display a helpscreen about the entire module
	
## getheader

	Usage: getheader <file> <number of characters to view>
	
The default is set to 500 characters.
# getline

	Usage: getline <file> <line number to view>
##>
