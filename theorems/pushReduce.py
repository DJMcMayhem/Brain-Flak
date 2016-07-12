from basics import *
import re

def pushReduce(snippet):
	result = ""
	finder = re.compile("\)[\(<\[AD]*B")
	while re.search(finder,snippet):
		zeroData = zeroReturn(result+snippet)[len(result):]
		search = re.search(finder,snippet)
		if search:
			location = search.span()
			if zeroData[location[0]][0] and zeroData[location[0]+1][0]: 
				end = findMatch(snippet,location[0])+1
				snippet = snippet[:end-1] + snippet[location[0]+1:location[1]-1] + snippet[end:location[0]] + snippet[location[1]:]
			else:
				result += snippet[:location[1]]
				snippet = snippet[location[1]:]
	return result + snippet
