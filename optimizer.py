import re
import theorems
from basics import *

def colorPrint(snippet):
	zeroData = zeroReturn(snippet)
	string = ""
	for entry in zeroData:
		if entry[0]:
			string += '\033[38;5;4m'
		else:
			string += '\033[38;5;3m'
		string += entry[1]
	string += '\033[0m'
	string = string.replace("A","()")
	string = string.replace("B","{}")
	string = string.replace("C","<>")
	string = string.replace("D","[]")
	print string

snip = "((()){})"

last = ""
current = clean(snip)

theoremList = [
	theorems.valueSponger,
	theorems.modifierSponger,
	theorems.anglePercolate,
	theorems.angleSponger,
	theorems.pushReduce,
	theorems.modifierReduce,
	theorems.loopReduce,
	theorems.valueReduce
]

while last != current:
	colorPrint(current)
	last = current
	for theorem in theoremList:
		current = theorem(current)
