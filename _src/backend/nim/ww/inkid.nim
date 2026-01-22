# wissen-wasse/_src/backend/ww/inkid.nim
import times, json, hashes, strutils, std/random
import ../other/types

randomize()

# helpers
proc fragment*(s: string, size: int): string =
    # a cada 4 caracteres, o quinto será uma linha (-)
    var outx = seq[string] @[]
    var i = 0
    while i < s.len:
        outx.add s[i ..< min(i + size, s.len)]
        i += size
    outx.join("-")

proc weakHash*(s: string): string =
    # hash rápido, não reversível, não criptográfico
    let h = hash(s)
    toHex(cast[uint32](h), 8)

# geração do inkid
proc generatedInkId*(payload: string): InkId =
    let ts = getTime()
    let millis = ts.toUnix() * 1000 + (ts.nanosecond div 1_000_000)
    let rnd = rand(InkEntropy)

    let raw =
        $millis & ":" &
        $rnd & ":" &
        WWSeed & ":" &
        payload.len.intToStr

    let hashed = weakHash(raw)
    InkId(fragment(hashed, InkFragmentSize))

proc isValidInkId*(id: InkId): bool =
    let s = $id
    if s.len == 0: return false

    let parts = s.split('-')
    for p in parts:
        if p.len != InkFragmentSize:
            return false
        if not p.allCharsInSet(HexDigits):
            return false
    true