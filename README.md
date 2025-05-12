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

--------------
Two companion functions are also provided:

GetHeader ## - to view the first ## (default set to 100) characters of a file

GetLine ## - to view a specific line # of a file
