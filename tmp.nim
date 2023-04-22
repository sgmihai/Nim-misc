import std/[tables, strutils, sequtils, os, parseopt, random]
import flatty

const
  cmds = "add, remove, import, export, ask, exit, log, hardest card, reset stats"
  msgs = ["""Input the action ("$1"):""" % cmds,"The card:","The definition of the card:", #0, 1 , 2
  """The card "$1" already exists. Try again:""","""The definition "$1" already exists. Try again:""", #3,4
  """The pair ("$1":"$2") has been added.""","Which card?","The card has been removed.", #5, 6, 7
  """Can't remove "$1": there is no such card.""","File name:","File not found.","How many times to ask?", #8, 9, 10, 11
  """Print the definition of "$1":""","""Wrong. The right answer is "$1".""", #12, 13
  """Wrong. The right answer is "$1", but your definition is correct for "$2".""","Correct!","The log has been saved.", #14, 15, 16
  "Bye bye!", "$1 cards have been loaded.","""The hardest card is "$1". You have $2 errors answering it.""",#17, 18, 19
  "There are no cards with errors.","Card statistics have been reset.", #20, 21
  """The hardest cards are $1. You have $2 errors answering them.""","$1 cards have been saved."] #22, 23
type Cards = Table[string, (string, int)]
var cards: Cards
var exportFile, log: string

proc logecho(s: string) =
  echo s
  log.add(s&"\n")

proc logread(): string =
  result = readLine(stdin)
  log.add(result&"\n")

proc importCards(fileName: string) =
  try:
    cards = fileName.open.readAll.fromFlatty(typedesc(Cards))
    logecho msgs[18] % $cards.len
  except CatchableError: logecho msgs[10]

proc exportCards(fileName: string) =
  try:
    writeFile(fileName, toFlatty(cards))
    logecho msgs[23] % $cards.len
  except CatchableError: logecho "Couldn't write to file"

var optparser = initOptParser(quoteShellCommand(commandLineParams()))
for kind, key, val in optparser.getopt():
  case kind:
  of cmdLongOption, cmdShortOption:
    case key:
    of "export_to": exportFile = val
    of "import_from": importCards(val)
  else: discard

while (logecho msgs[0]; var input = logread(); true):
  case input:
    of "add":
      logecho msgs[1] 
      while (var card = logread(); true):
        if cards.hasKey(card): logecho msgs[3] % [card]; continue
        else:
          logecho msgs[2]
          while (var answ = logread(); true):
            if cards.values.toSeq.anyIt(it[0] == answ): logecho msgs[4] % [answ]; continue
            else: cards[card] = (answ, 0); logecho msgs[5] % [card, answ]; break
          break
    of "remove":
      logecho msgs[6]
      var card = logread()
      if cards.hasKey(card): logecho msgs[7]; cards.del(card)
      else: logecho msgs[8] % [card]
    of "import": logecho msgs[9]; importCards(logread())
    of "export": logecho msgs[9]; exportCards(logread())
    of "ask":
      logecho msgs[11]
      for i in 1..logread().parseInt():
        let randCardKey = cards.keys.toSeq()[rand(cards.len-1)]
        logecho msgs[12] % [randCardKey]
        let answ = logread()
        if cards[randCardKey][0] != answ:
          if cards.values.toSeq.anyIt(it[0] == answ):
            logecho msgs[14] % [cards[randCardKey][0], cards.keys.toSeq.filterIt(cards[it][0] == answ)[0]]
          else: logecho msgs[13] % [cards[randCardKey][0]]
          inc cards[randCardKey][1]
        else: logecho msgs[15]
    of "exit": logecho msgs[17]; (if exportFile != "": exportCards(exportFile)); quit(QuitSuccess)
    of "log": logecho msgs[9]; writeFile(logread(), log); logecho msgs[16]
    of "hardest card":
      if cards.keys.toSeq.allIt(cards[it][1] == 0): logecho msgs[20]
      else:
        let maxValue = cards[cards.keys.toSeq[cards.keys.toSeq.mapIt(cards[it][1]).maxIndex()]][1]
        let maxCardKeys = cards.keys.toSeq.filterIt(cards[it][1] == maxValue)
        if (maxCardKeys.len == 1): logecho msgs[19] % [maxCardKeys[0], $cards[maxCardKeys[0]][1]]
        else: logecho msgs[22] % [maxCardKeys.mapIt('"'&it&'"').join(","), $cards[maxCardKeys[0]][1]]
    of "reset stats": (logecho msgs[21]; for card in cards.keys: cards[card][1] = 0)
    else: discard