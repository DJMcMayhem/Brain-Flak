import re
import theorems

def colorPrint(snippet):
	zeroData = theorems.zeroReturn(snippet)
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

def optimize(snippet):
	current = theorems.clean(snippet)
	first = ""
	colorPrint(current)
	while first != current:
		first = current
		last = current
		for theorem in theorems.theoremList:
			current = theorem(current)
			if current != last:
				print theorem
				assert theorems.balanced(current)
				colorPrint(current)
				last = current
	return current

snip = "([[[()()()()]()()()()()()()()()()()()()()()()[()()()()()()()()()]]{}[()()()()()()()]]()()()()()()()()()()()()()()()()()()()()()()()())"

optimize(snip)
