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

	-recurse   to look recursively through the directory structure
	-quiet     to suppress the messages for files where no matching pattern was found
	-header ## to view the first ## (defaults to 500) characters of the file, when a match is found
	-countonly to provide the numeric results of matches found, but suppress the contextual matches found
	-long      to provide an 80 character prefix and suffix for contextual matching, instead of 40
	-summary   to provide a numerical summary
	-load      to load a regex string from the saved options in the find-in.txt file
	-add       to save a new Regex pattern to the find-in.txt file
	-remove    to remove a Regex pattern from the find-in.txt file
	-help      to display this screen
	
## getheader

	Usage: getheader <file> <number of characters to view>
	
The default is set to 500 characters.
# getline

	Usage: getline <file> <line number to view>
