import sys
import re
import theorems

def colorPrint(snippet):
	zeroData = theorems.zeroReturn(snippet)
	string = ""
	for entry in zeroData:
		if entry[0]:
			string += '\033[38;5;4m'
		else:
			string += '\033[38;5;3m'
		string += entry[1]
	string += '\033[0m'
	string = string.replace("A","()")
	string = string.replace("B","{}")
	string = string.replace("C","<>")
	string = string.replace("D","[]")
	print string

def optimize(snippet):
	size = len(snippet)
	current = theorems.clean(snippet)
	first = ""
	colorPrint(current)
	while first != current:
		first = current
		last = current
		for theorem in theorems.theoremList:
			current = theorem(current)
			if current != last:
				print theorem
				assert theorems.balanced(current)
				colorPrint(current)
				last = current
	current = theorems.flesh(current)
	print "Code reduced from %d bytes to %d bytes" %(size,len(current))
	return current

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
	infile.close()

	string = optimize(string)
	
	outfile.write(string)
	
	#Close all the files
	outfile.close()
