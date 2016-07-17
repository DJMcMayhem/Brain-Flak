import sys
import re

def matching(brace1, brace2):
	openers = "([{<"
	closers = ")]}>"
	if brace1 in openers and brace2 in closers:
		return openers.index(brace1) == closers.index(brace2)
	elif brace1 in closers and brace2 in openers:
		return openers.index(brace2) == closers.index(brace1)		
	else:
		return False

def indent(code, indenter):
	return code.replace('\n','\n'+indenter)

'''
atomize will go through a code fragment and split up pieces that are not of the same scope
e.g.
(())<>{{}{}<>}
becomes
(())
<>
{{}{}<>}
'''
def atomize(fragment):
	building = ""
	currentScope = ""
	for character in fragment:
		building += character
		currentScope += character
		if len(currentScope) > 1 and matching(currentScope[-1],currentScope[-2]):
			currentScope = currentScope[:-2]
		building += '\n' if currentScope == "" else ''
	if currentScope != "":
		print "Broken fragment or uneven braces"
	return building[:-1]

def unpack(code, indenter):
	fragments = atomize(code).split('\n')
	result = ""
	#checkPattern tells us if it should be nested
	checkPattern = re.compile(".*([{][^}].*[^{][}]|[<][^>].*[^<][>]).*")
	for fragment in fragments:
		if not checkPattern.match(fragment):
			result += fragment+'\n'
			continue
		#Sub out the nilads
		fragment = fragment.replace('{}','A').replace('<>','B')
		recording = False
		record = ""
		currentScope = ""
		for character in fragment:
			if recording:
				if character not in 'AB':
					currentScope += character
				if len(currentScope) > 1 and matching(currentScope[-1],currentScope[-2]):
					currentScope = currentScope[:-2]
				if currentScope == "":
					result += '\n '
					result += indent(unpack(record.replace('A','{}').replace('B','<>'),indenter)[:-1],indenter)
					result += '\n'+character
					recording = False
				else:
					record += character
			else:
				result += character
				if character in "{<":
					recording = True
					record = ""
					currentScope = character
		result += '\n'
	#Sub the nilads back in
	result = result.replace('A','{}')
	result = result.replace('B','<>')
	return result

if __name__ == "__main__":
	commandLineArgs = sys.argv
	if len(commandLineArgs) != 3:
		print "Please pass a input and output file."
		print "(Example: python %s input.txt output.txt)" %commandLineArgs[0]
		exit()
	#Open files
	infile = open(commandLineArgs[1])
	outfile = open(commandLineArgs[2],"w")
	
	string = infile.read()

	#First we get rid of any formatting that may already exist
	string = re.sub("[^\(\){}\[\]<>]",'',string)

	string = unpack(string,' ')

	outfile.write(string)
	
	#Close all the files
	outfile.close()
	infile.close()
