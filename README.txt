FILES in this directory
-----------------------
== DIRECTORIES
archives/	- archive of old scripts (for source control look to sg/edu/nus/comp/kanmy/zoning)
doc/		- cgi files and documentation
lib/		- simone's lexicon and files and full models trained over all annot data
bin/		- all scripts
   /wsdl        - scripts for web services
tmp/		- temporary holding space for redo.pl output

== META TEXT FILES
TODO.txt	- next steps
README.txt 	- this file
mapping.txt	- mapping between annot files and ACL Anthology
	
== DATA FILES
*.annot		- source files from Simone Teufel's original AZ corpus

== LIB FILES
(stoplist|singleCP|multiCP).(txt|db) - flat and perl db files for cue phrase lexicon and stopword list
		single file has single word cues, multi has multiword word cues
cgiLog.txt	- cgi output log file

== OUTPUT FILES
fold.*
model.*
out.*
result.*
train.*

== SCRIPTS / PROGRAMS
(best to see how these programs are pipelined in bin/redo.pl or doc/zoning.cgi)

annot2txt.pl	- converts annot files to txt
detail2out2.pl	- analyzes detailed prediction output to output just
		  the two most highly confident tags and confidence
		  scores
dbmEdit.pl	- utility to build perl databases from the flat files
mergeDelimitOut.pl	- merges delimited sentences with highest
			  confidence non-UNDEFINED tags for iterative
			  results
maxent		- maximum entropy machine learner from Zhang Le
redo.pl		- redo all experimentation, recreates output files
scores.pl	- creates macro f1, confusion matrix given 2-column tsv file
		  (answer and guesses, don't remember which is which)
tag2feats.pl	- takes tagged file to generate feature for maxent
txt2tag.pl	- takes text from rawText or annot format (see cmdline
		  options) to generate a tagged file.  Runs sentence
		  delimitation if from rawText.



