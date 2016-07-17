from basics import *
import re

'''
reducablePushes finds all regex matches in with a zeroReturn at the start

This will return a list of pushes that are reducable
'''

def reducablePushes(snippet):
	zeroData = zeroReturn(snippet)
	return filter(lambda x: zeroData[x.span()[0]][0],re.finditer("\)[\(<\[AD]*B",snippet))

'''
pushReduce takes pops that occur after a push and reduces them into a single expression

e.g.
If we push one to the stack, "(())", and then duplicate it ,"(({}))",
it is the same as pushing one to the stack twice "((()))"

(())(({})) --> ((()))

This only works if the push is in a zeroReturn scope

e.g.
((())(({}))) --> ((())(({})))
'''

def pushReduce(snippet):
	while reducablePushes(snippet) != []:
		location = reducablePushes(snippet)[0].span()
		start = findMatch(snippet,location[0])
		snippet = (snippet[:start] +                        #Everything before the effected area
		           snippet[location[0]+1:location[1]-1] +   #Everything between the ")" and the "B"
		           snippet[start+1:location[0]] +           #Everything between the ")" and its match
		           snippet[location[1]:]                    #Everything after the effected ares
		)
	return snippet

if __name__ == "__main__":
	snippet = clean("((<>)({}))(({}))")
	print pushReduce(snippet)
