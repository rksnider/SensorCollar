Files and Scripts used to Augment Git
=====================================
The pre-commit hook script 'commit_timestamps.bsh' finds all files
named 'commit_timestamp.log' in the project's source tree and replaces
them with files of the same name which contain the time, in seconds,
that the commit was started at.  This time can be extracted from these
files and used to identify the source code used to build projects from it.
