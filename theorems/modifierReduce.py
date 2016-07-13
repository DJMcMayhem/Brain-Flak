from basics import *
import re

def modifierReduce(snippet):
	snippet = snippet.replace("><","")
	snippet = snippet.replace("][","")
	finder = re.compile("[<\[]C*[>\]]")
	while re.search(finder, snippet):
		location = re.search(finder, snippet).span()
		snippet = snippet[:location[0]] + snippet[location[0]+1:location[1]-1] + snippet[location[1]:]
	return snippet

if __name__ == "__main__":
	print modifierReduce(clean("(<<>>)"))
