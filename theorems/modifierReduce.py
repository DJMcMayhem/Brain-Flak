from basics import *
import re

def reducableModifiers(snippet):
	finder = re.compile("(\[<|<\[).*(\]>|>\])")
	matches = re.finditer(finder, snippet)
	matches = filter(lambda x:balanced(snippet[x.span()[0]:x.span()[1]]),matches)
	return matches

def modifierReduce(snippet):
	snippet = snippet.replace("><","")
	snippet = snippet.replace("][","")
	finder = re.compile("[<\[]C*[>\]]")
	while re.search(finder, snippet):
		location = re.search(finder, snippet).span()
		snippet = snippet[:location[0]] + snippet[location[0]+1:location[1]-1] + snippet[location[1]:]
	while reducableModifiers(snippet) != []:
		location = reducableModifiers(snippet)[0].span()
		snippet = snippet[:location[0]] + "<" + snippet[location[0]+2:location[1]-2] + ">" + snippet[location[1]:]
	return snippet

if __name__ == "__main__":
	print modifierReduce(clean("(<[()<{}[()]>]>)"))
