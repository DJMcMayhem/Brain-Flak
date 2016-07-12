from basics import *
import re

def negativeReduce(snippet):
	#This can be made more powerful in the future
	#Perhaps this can be combined with modifier reduce
	while re.search("(\[\[|\]\])",snippet):
		if re.search("\[\[",snippet):
			location = re.search("\[\[",snippet).span()
			start = location[1]
			end = findMatch(snippet,location[1]-1)
			snippet = cleanup(snippet[:location[0]] + snippet[start:end] + "[" + snippet[end+1:])
		else:
			location = re.search("\]\]",snippet).span()
			start = findMatch(snippet,location[0])
			snippet = cleanup(snippet[:start] + "]" + snippet[start+1:location[0]] + snippet[location[1]+1:])
	return snippet
