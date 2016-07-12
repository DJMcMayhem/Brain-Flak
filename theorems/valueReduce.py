from basics import *
import re

def getValue(snippet):
	while re.search("<",snippet):
		location = re.search("<",snippet).span()
		snippet = snippet[:location[0]] + snippet[findMatch(snippet,location[0])+1:]
	snippet = snippet.replace("A","()")
	atoms = atomize(snippet).split("\n")
	sum = 0
	for atom in atoms:
		if atom == "()":
			sum += 1
		elif atom[0] == "[" and atom[-1] == "]":
			sum -= getValue(atom[1:-1])
	return sum

def factors(n):    
	return reduce(list.__add__, ([x, n//x] for x in range(1, int(n**0.5) + 1) if n % x == 0))

def getSimpleSequence(value):
	if value < 0:
		return "["+getSequence(-value)+"]"
	if value == 0:
		return "<><>"
	if value <= 5:
		#For values less than or equal to four cannot be expressed more simply than n*"()" 
		return "()" * value
	else:
		multipliers = factors(value)[1:-1]
		if multipliers != []:
			#Composite numbers can be reduced by hard coded multiplication
			form = lambda mul: ("("*(mul-1)+
			                    getSequence(value/mul)+
			                    ")"*(mul-1)+
			                    "{}"*(mul-1)
			                   )
			snippets = map(form,multipliers)
			return min(snippets, key = len)
		else:
			#Primes can get pretty long its best to just subtract one and take the hit
			#It cannot get worse because worst case (actually impossible) every number smaller is prime
			#In which case you just get n*"()"
			#There might be room for optimization here
			return getSimpleSequence(value-1) + "()"

def getSequence(value):
	if value < 0:
		return "["+getSequence(-value)+"]"
	if value == 0:
		return "<><>"
	if value <= 5:
		#For values less than or equal to four cannot be expressed more simply than n*"()" 
		return "()" * value
	else:
		#Simple sequence acts as the standard
		simpleSequence = getSimpleSequence(value)
		#Max depth marks the maximum depth before search is stopped
		#Subtract five because the first five sequences are "()"*n
		maxDepth = min(len(simpleSequence)/2 - 5, value)
		depth = 0
		#Go in the positive direction
		while depth < maxDepth:
			depth += 1
			newSequence = getSimpleSequence(value-depth) + getSimpleSequence(depth)
			if len(newSequence) < len(simpleSequence):
				simpleSequence = newSequence
				maxDepth = len(simpleSequence)/2 - 5 + depth
		#Go in the negative direction
		#Additional two allowed for negative "[ ]" monad
		maxDepth = len(simpleSequence)/2 - 7
		depth = 0
		while depth < maxDepth:
			depth += 1
			newSequence = getSimpleSequence(value+depth) + "[" + getSimpleSequence(depth) + "]"
			if len(newSequence) < len(simpleSequence):
				simpleSequence = newSequence
				maxDepth = len(simpleSequence)/2 - 7 + depth
		return simpleSequence

def substrings(snippet):
	length = len(snippet)
	return [snippet[i:j+1] for i in xrange(length) for j in xrange(i,length)]

def valueReduce(snippet):
	result = ""
	while re.search("[A\[\]<>]{2,}",snippet):
		location = re.search("[A\[\]<>]{2,}",snippet).span()
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
		#Filter out empty strings
		possibilities = filter(lambda x:x!="",possibilities)
		if possibilities != []:
			largest = max(possibilities, key=len)
			result += snippet[:location[1]].replace(largest, clean(getSequence(getValue(largest))))
			snippet = snippet[location[1]:]
		else:
			result += snippet[:location[1]]
			snippet = snippet[location[1]:]
	return result + snippet

if __name__ == "__main__":
	print getSequence(121)
