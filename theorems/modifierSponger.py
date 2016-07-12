from basics import *
import re

def modifierSponger(snippet):
	zeroData = zeroReturn(snippet)
	if zeroData == []: return ""
	zeroData[:] = [x for x in zeroData if not (x[0] and x[1] in "[]<>")]
	snippet = reduce(lambda x,y:x+y,zip(*zeroData)[1])
 	return cleanup(snippet)
