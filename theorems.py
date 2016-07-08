import re
from basics import *

def angleSponger(snippet):
	snippet = snippet.replace("CC","")
	snippet = cleanup(snippet)
	return snippet

def valueSponger(snippet):
	snippet = snippet.replace("(B)","E")
	zeroData = zeroReturn(snippet)
	zeroData[:] = [x for x in zeroData if x not in [(True,"A"),(True,"D"),(True,"E")]]
	if zeroData == []: return ""
	snippet = reduce(lambda x,y:x+y,zip(*zeroData)[1])
	snippet = snippet.replace("E","(B)")
	snippet = cleanup(snippet)
	return snippet

def modifierSponger(snippet):
	zeroData = zeroReturn(snippet)
	if zeroData == []: return ""
	zeroData[:] = [x for x in zeroData if not (x[0] and x[1] in "[]<>")]
	snippet = reduce(lambda x,y:x+y,zip(*zeroData)[1])
 	return cleanup(snippet)

def modifierReduce(snippet):
	snippet = snippet.replace("><","")
	snippet = snippet.replace("][","")
	return snippet

def loopReduce(snippet):
	while re.search("}[^BC\(\)]*{",snippet):
		start = re.search("}[^BC\(\)]*{",snippet).span()[1]-1
		end = findMatch(snippet,start)+1
		snippet = cleanup(snippet[:start] + snippet[end:])
	return snippet

def anglePercolate(snippet):
	snippet = snippet.replace("(C)","a")
	snippet = snippet.replace("<C>","c")
	snippet = snippet.replace("[C]","d")
	
	while re.search("[\(\[<]C",snippet):
		snippet = snippet.replace("(C","C(")
		snippet = snippet.replace("[C","C[")
		snippet = snippet.replace("<C","C<")

	snippet = snippet.replace("(C)","a")
	snippet = snippet.replace("<C>","c")
	snippet = snippet.replace("[C]","d")
	
	while re.search("C[\]>]",snippet):
		snippet = snippet.replace("C>",">C")
		snippet = snippet.replace("C]","]C")

	snippet = snippet.replace("a","(C)")
	snippet = snippet.replace("c","<C>")
	snippet = snippet.replace("d","[C]")
	return snippet

def pushReduce(snippet):
	result = ""
	finder = re.compile("\)[\(<\[AD]*B")
	while re.search(finder,snippet):
		zeroData = zeroReturn(snippet)
		search = re.search(finder,snippet)
		if search:
			location = search.span()
			if zeroData[location[0]][0] and zeroData[location[0]+1][0]: 
				end = findMatch(snippet,location[0])+1
				snippet = snippet[:end-1] + snippet[location[0]+1:location[1]-1] + snippet[end:location[0]] + snippet[location[1]:]
			else:
				result = snippet[:location[1]]
				snippet = snippet[location[1]:]
	return result + snippet

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

def getSequence(value):
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
			return getSequence(value-1) + "()"

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
		if possibilities != []:
			largest = max(possibilities, key=len)
			result += snippet[:location[1]].replace(largest, clean(getSequence(getValue(largest))))
			snippet = snippet[location[1]:]
		else:
			result += snippet[:location[1]]
			snippet = snippet[location[1]:]
	return result + snippet

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

if __name__ == "__main__":
	print valuePercolate(clean("((){}(){})"))
