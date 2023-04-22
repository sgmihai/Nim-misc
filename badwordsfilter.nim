import strutils, sequtils
try: var biggerWords = readLine(stdin).open.readAll.toLowerAscii.split()
let period = if biggerWords[^1].endsWith("."): biggerWords[^1] = biggerWords[^1].strip(); "." else: ""
while (var x = readLine(stdin); x != "exit"):
  echo x.split.mapIt(if it.toLowerAscii in biggerWords: '*'.repeat(it.len) else: it).join(" ") & period
echo "Bye!"