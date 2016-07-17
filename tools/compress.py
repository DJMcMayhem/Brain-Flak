import sys
import re

if __name__ == "__main__":
	commandLineArgs = sys.argv
	if len(commandLineArgs) != 3:
		print "Please pass a input and output file."
		print "(Example: python %s input.txt output.txt)" %commandLineArgs[0]
		exit()
	#Open first file replace whitespace and write to second file
	#Open files
	infile = open(commandLineArgs[1])
	outfile = open(commandLineArgs[2],"w")
	
	string = infile.read()
	string = re.sub("[^\(\){}\[\]<>]",'',string)
	
	outfile.write(string)
	
	#Close all the files
	outfile.close()
	infile.close()
