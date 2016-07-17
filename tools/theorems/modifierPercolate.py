import re
from basics import *

'''
Modifiers applied to all terms of a loop can be applied to the loop as a whole

{[{}]} --> [{{}}]

'''

def modifierPercolate(snippet):
	finder = re.compile("\{[\[<]")
	result = ""
	while re.search(finder, snippet):
		location = re.search(finder,snippet).span()
		result += snippet[:location[0]]
		if findMatch(snippet,location[0]) -1 == findMatch(snippet,location[1]-1):
			result += snippet[location[1]-1]
			result += "{"
			result += snippet[location[1]:findMatch(snippet,location[1]-1)]
			result += "}"
			result += complement(snippet[location[1]-1])
		else:
			result += snippet[location[0]:findMatch(snippet,location[0])+1]
		snippet = snippet[findMatch(snippet,location[0])+1:]
	return result + snippet

if __name__ == "__main__":
	print modifierPercolate(clean("{<{}{}>}"))
	print modifierPercolate(clean("{<{}><{}>}"))
