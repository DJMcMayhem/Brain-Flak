from basics import *
import re

def angleSponger(snippet):
	snippet = snippet.replace("CC","")
	snippet = cleanup(snippet)
	return snippet
