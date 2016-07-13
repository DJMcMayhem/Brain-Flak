from basics import *
import re

'''
Room for improvement

[()[()]()] --> [()]()[()]
'''

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
			end = location[1]-1
			start = findMatch(snippet,location[0])
			print snippet[start:end]
			snippet = snippet[:start] + "]" + snippet[start+1:end-1] + snippet[end+1:]
	return snippet


if __name__ == "__main__":
	print negativeReduce(clean("[()[()[()]]]"))
