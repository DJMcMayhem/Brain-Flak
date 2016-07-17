from basics import *
import re

'''
topStack goes through a snippet and determines for every point in the program if the value at the top of the stack is:
   -Zero
   -Not zero
   -Unknown

It returns a list of tuples
'''

def topStack(snippet,start = "Unknown"):
	#This could be a bit more advanced in figuring out the state of the top of the stack
	result = []
	current = start
	snippet = snippet.replace("(CC)","GGGF")
	for character in snippet:
		result.append(current)
		if character == "{":
			current = "Not Zero"
		elif character == "}" or character == "F":
			current = "Zero"
		elif character in ["B",")","C"]:
			current = "Unknown"
	snippet = snippet.replace("GGGF","(CC)")
	return zip(result,snippet)

'''
Doubly nested curly braces reduce to singly nested braces

{{foo}} --> {foo}
'''

def miniTheorem(snippet):
	finder = re.compile("\{\{")
	result = ""
	while re.search(finder, snippet):
		location = re.search(finder,snippet).span()
		result += snippet[:location[0]]
		if findMatch(snippet,location[0]) -1 == findMatch(snippet,location[1]-1):
			result += "{"
			result += snippet[location[1]:findMatch(snippet,location[1]-1)]
			result += "}"
		else:
			result += snippet[location[0]:findMatch(snippet,location[0])+1]
		snippet = snippet[findMatch(snippet,location[0])+1:]
	return result + snippet

'''
Loop reduce uses data from topStack to simplify loops

The rules it uses are as follows

If there is a zero on the top of the stack and a loop is begining that loop cannot be executed and is removed

(<><>){{}} --> (<><>)

If there is a non zero on the top of the stack at the begining of the loop
and a zero at the top of the stack at the end of a loop, the loop executes only once and can be reduced to its contents

{{(<><>)}} --> {(<><>)}
'''

def loopReduce(snippet, start = "Unknown"):
	result = ""
	finder = re.compile("\{")
	stackData = topStack(snippet,start)
	while re.search(finder, snippet):
		location = re.search(finder,snippet).span()[0]
		match = findMatch(snippet,location)+1
		result += snippet[:location]
		if stackData[location][0] == "Zero":
			pass
		elif stackData[location][0] == "Not Zero" and stackData[match-1][0] == "Zero":
			result += loopReduce(snippet[location+1:match-1],stackData[location+1][0])
		else:
			result += "{" + loopReduce(snippet[location+1:match-1],stackData[location+1][0]) + "}"
		snippet = snippet[match:]
		stackData = stackData[match:]
	return miniTheorem(result + snippet)

if __name__ == "__main__":
	#GOALS
	'''
	There are still improvements possible
	I would like to make it so that the system recognizes and evaluates push values
	e.g. (()) means non zero on the stack
	e.g. (<()[]>) means zero on the stack
	I would like to make it so that the system can reason about pushes and stack height
	e.g. ([]()) means non zero on the stack
	e.g. (<><>)({}())  means non zero on the stack
	'''
	print loopReduce(clean("(()){(<><>)}"))   # --> (())(<><>)
	print loopReduce(clean("(<()>){{}}"))     # --> (<()>)
	print loopReduce(clean("([]()){(<><>)}")) # --> ([]())(<><>)
