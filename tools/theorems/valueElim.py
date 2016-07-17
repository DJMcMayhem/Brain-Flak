from basics import *
import re

def valueElim(snippet):
	snippet = snippet.replace("(B)","E")
	zeroData = zeroReturn(snippet)
	zeroData[:] = [x for x in zeroData if x not in [(True,"A"),(True,"D"),(True,"E")]]
	if zeroData == []: return ""
	snippet = reduce(lambda x,y:x+y,zip(*zeroData)[1])
	snippet = snippet.replace("E","(B)")
	snippet = cleanup(snippet)
	return snippet
