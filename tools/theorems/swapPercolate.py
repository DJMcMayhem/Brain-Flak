from basics import *
import re

def swapPercolate(snippet):
	snippet = snippet.replace("(C)","a")
	snippet = snippet.replace("<C>","c")
	snippet = snippet.replace("[C]","d")
	
	while re.search("[\(\[<]C",snippet):
		snippet = snippet.replace("(C)","a")
		snippet = snippet.replace("<C>","c")
		snippet = snippet.replace("[C]","d")
		snippet = snippet.replace("(C","C(")
		snippet = snippet.replace("[C","C[")
		snippet = snippet.replace("<C","C<")

	while re.search("[\]>]C",snippet):
		snippet = snippet.replace(">C","C>")
		snippet = snippet.replace("]C","C]")

	snippet = snippet.replace("a","(C)")
	snippet = snippet.replace("c","<C>")
	snippet = snippet.replace("d","[C]")
	return snippet
