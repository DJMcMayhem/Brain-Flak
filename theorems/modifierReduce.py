from basics import *
import re

def modifierReduce(snippet):
	snippet = snippet.replace("><","")
	snippet = snippet.replace("][","")
	return snippet
