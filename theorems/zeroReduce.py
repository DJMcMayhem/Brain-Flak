from basics import *

'''
zero reduce makes expressions that push zero to the stack more effecient

It does so by wrapping and zeroing a earlier expression

{{}}(<><>) --> (<{{}}>)

It can only do so if the previous expression is in a zero return scope
or if the earlier expression is already zeroed

 ({}(<><>))  --> ({}(<><>))

(<{}>(<><>)) -->  ((<{}>))

It also allows for multiple levels of push

{}((<><>)) --> ((<{}>))
'''

def zeroReduce(snippet):
	result = ""
	finder = re.compile("\(*CC\)*")
	while re.search(finder,snippet):
		zeroData = zeroReturn(snippet)
		location = re.search(finder,snippet).span()
		sublocation = re.search("CC",snippet[location[0]:location[1]]).span()
		if location[0] == 0:
			#If we are at the start of the snippet do nothing
			result += snippet[:location[1]]
		elif snippet[location[0]-1] == ">":
			#i.e. earlier expression is zeroed
			end = location[0]
			start = findMatch(snippet,location[0]-1)
			result += snippet[:start]
			result += snippet[location[0]:location[0]+sublocation[0]]
			result += snippet[start:end]
			result += snippet[location[0]+sublocation[1]:location[1]]
		elif zeroData[location[0]-1][0]:
			end = location[0]
			start = findMatch(snippet,location[0]-1)
			result += snippet[:start]
			result += snippet[location[0]:location[0]+sublocation[0]]
			result += "<"
			result += snippet[start:end]
			result += ">"
			result += snippet[location[0]+sublocation[1]:location[1]]
		else:
			result += snippet[:location[1]]
		snippet = snippet[location[1]:]
	return result + snippet


if __name__ == "__main__":
	#Example
	print zeroReduce(clean("{{}(){}}(<><>)()({}(<><>))()(<><>)"))
