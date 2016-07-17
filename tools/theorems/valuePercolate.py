from basics import *
import re
from valueReduce import substrings

def valuePercolate(snippet):
	#TODO fix leapfrogging
	result = ""
	while re.search("[A\[\]<>]+",snippet):
		location = re.search("[A\[\]<>]+",snippet).span()
		section = snippet[location[0]:location[1]]
		#Theres got to be a better way to do this
		#I am really tired right now and I'll fix it later
		#I just want it to run
		#Currently I takes the largest balanced substring
		#It finds all the substrings
		#sorts out the unbalanced ones
		#returns the largest
		possibilities = substrings(section)
		possibilities = filter(balanced,possibilities)
		if possibilities != []:
			largest = max(possibilities, key=len)
			sublocation = re.search(largest.replace("[","\[").replace("]","\]"), section).span()
			start = location[0]+sublocation[0]
			end   = location[0]+sublocation[1]
			index = end
			result += snippet[:start]
			#Find the right edge of the current scope
			while (snippet+")")[index] not in ")}>]": #Stop if closing scope (virtual parenthesis at the end of the program)
				index = findMatch(snippet,index)+1
			result += snippet[end:index]
			result += snippet[start:end]
			snippet = snippet[index:]
		else:
			result += snippet[:location[1]]
			snippet = snippet[location[1]:]
	return result + snippet
