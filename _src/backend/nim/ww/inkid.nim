# wissen-wasse/_src/backend/ww/inkid.nim
import times, hashes, strutils, std/random
import ../other/types

randomize()

proc fragment*(s: string, size: int): string =
  var outx: seq[string] = @[]
  var i = 0
  while i < s.len:
    outx.add s[i ..< min(i + size, s.len)]
    i += size
  outx.join("-")

proc weakHash*(s: string): string =
    let h = hash(s)
    toHex(cast[uint32](h), 8)

proc generatedInkId*(payload: string): InkId =
    let ts = getTime()
    let millis = ts.toUnix() * 1000 + (ts.nanosecond div 1_000_000)
    let rnd = rand(InkEntropy)

    let raw =
        $millis & ":" &
        $rnd & ":" &
        WWSeed & ":" &
        payload.len.intToStr

    InkId(fragment(weakHash(raw), InkFragmentSize))

proc isValidInkId*(id: InkId): bool =
  let s = $id
  if s.len == 0: return false

  for p in s.split('-'):
    if p.len != InkFragmentSize or not p.allCharsInSet(HexDigits):
      return false
  true
