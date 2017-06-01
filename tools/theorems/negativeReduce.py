from basics import *
import re

'''
Find all of the matches that are reducable
'''

def reducableNegatives(snippet):
	matches = re.finditer("\[[^\[]*\[",snippet)
	#Matches that are balanced between the "["s are reduceable
	valid = lambda x: balanced(snippet[x.span()[0]+1:x.span()[1]-1])
	return filter(valid,matches)

'''
TODO: Add description
'''

def negativeReduce(snippet):
	#This can be made more powerful in the future
	#Perhaps this can be combined with modifier reduce
	while reducableNegatives(snippet) != []:
		location = reducableNegatives(snippet)[0].span()
		end = findMatch(snippet,location[1]-1)
		snippet = snippet[:location[1]-1] + "]" + snippet[location[1]:end] + "[" + snippet[end+1:]
	return cleanup(snippet)

if __name__ == "__main__":
	print negativeReduce(clean("[()[()[()]()]()]"))
	print negativeReduce(clean("[()[()[()]]]"))
