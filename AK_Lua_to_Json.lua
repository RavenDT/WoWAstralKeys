assert(loadfile(arg[1]))()
JSON = assert(loadfile("lib/JSON.lua"))()

outputString = table.concat({
    "{",
    "\"AstralKeys\":", JSON:encode(AstralKeys), ",",
    "\"AstralCharacters\":", JSON:encode(AstralCharacters), ",",
    "\"AstralLists\":", JSON:encode(AstralLists),
    "}"
},"")

print(outputString)
