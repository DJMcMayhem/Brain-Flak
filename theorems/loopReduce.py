from basics import *
import re

def loopReduce(snippet):
	while re.search("}[^BC\(\)]*{",snippet):
		start = re.search("}[^BC\(\)]*{",snippet).span()[1]-1
		end = findMatch(snippet,start)+1
		snippet = cleanup(snippet[:start] + snippet[end:])
	return snippet
