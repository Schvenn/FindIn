@{RootModule = 'Findin.psm1'
ModuleVersion = '3.2'
GUID = '2bfb6cfc-8c62-4e9f-9f1b-2e5c61709a6e'
Author = 'Schvenn'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '(c) Craig Plath. All rights reserved.'
Description = 'Advanced regex-based file search tool with pattern loading, optional recursion, context display, gzip support, and integration with a custom viewer.'
PowerShellVersion = '5.1'
FunctionsToExport = @('findin','getheader','getline')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @('header')
FileList = @('Findin.psm1', 'FindIn.txt')
PrivateData = @{PSData = @{Tags = @('artifact','find','gzip','log','regex','search','viewer','security','forensics','cybersecurity','SOC')
LicenseUri = 'https://github.com/Schvenn/FindIn/blob/main/LICENSE'
ProjectUri = 'https://github.com/Schvenn/FindIn'
ReleaseNotes = 'Initial PowerShell gallery release. Advanced search utility, includes full integration with artifactviewer and pattern loading system.'}}}
