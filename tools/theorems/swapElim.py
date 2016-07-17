from basics import *
import re

def swapElim(snippet):
	snippet = snippet.replace("CC","")
	snippet = cleanup(snippet)
	return snippet
