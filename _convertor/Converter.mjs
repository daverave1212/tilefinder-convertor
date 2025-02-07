
import { splitCodeIntoTokens } from './Lexer.mjs'
import * as Grammar from './Grammar.mjs'
import fs from 'fs'

function lex(line, operators=null) {
    if (operators == null) {
        operators = Grammar.getAllOperators()
    }
    const words = splitCodeIntoTokens(line, Grammar.getAllOperators(), Grammar.separators)
    return words.map(word => word.value)
}

function expressizeLine(line) {
    const words = lex(line)
    const expressions = []
    for (const word of ...Grammar.)
}

function isSpace(str) {
    return str.trim().length == 0
}

function findFromTo(str, fromStr, stopAt, fromIndex=0, outData={}) {
    const index = str.indexOf(fromStr, fromIndex)
    if (index == -1) {
        return null
    }
    const startIndex = index + fromStr.length
    // console.log(`  Finding from "${fromStr}" to "${stopAt}" fromIndex=${fromIndex} in str: ${str}. index=${index}`)
    let endIndex = -1
    if (Array.isArray(stopAt)) {
        for (let i = startIndex; i < str.length; i++) {
            let didFind = false
            for (const toStr of stopAt) {
                if (str.substring(i).startsWith(toStr)) {
                    // console.log(`  Found one! At ${i} for toStr="${toStr}"`)
                    endIndex = i
                    didFind = true
                    break
                }
            }
            if (didFind) {
                break
            }
        }
    } else {
        endIndex = str.indexOf(stopAt, startIndex)
    }
    if (endIndex == -1) {
        endIndex = str.length
    }
    outData.endIndex = endIndex

    const word = str.substring(startIndex, endIndex)
    return word
}

function isNumber(str) {
    return /^-?\d+(\.\d+)?$/.test(str)
}


// console.log(capitalizeFunctions('item.resistances = Resistances.createFromDynamicForItem(resistances);'))
// process.exit()

const hxFolderPath = `C:\\Other\\Tilefinder\\TaleAndAle-master\\C# Conversion\\code`
const csFolderPath = "C:\\Other\\Tilefinder\\TaleAndAle-master\\C# Conversion\\converted_src"

if (process.argv.length < 4) {
    console.log("Use like: node Converter.mjs FileName Databases")
    exit()
}

let fileName = process.argv[2]
const folderName = process.argv[3]

function capitalizeFunctions(str) {
    const letters = `qwertyuiopasdfghjklzxcvbnm`.split('')
    for (const letter of letters) {
        str = str.replaceAll(`function ${letter}`, `function ${letter.toUpperCase()}`)
    }
    const funcNames = []
    for (let i = 0; i <= str.length; i++) {
        const char = str.charAt(i)
        if (char == '.') {
            const outData = {}
            const thisPart = findFromTo(str, '.', [' ', '.', '(', ';'], i, outData)
            if (str[outData.endIndex] == '(') {
                funcNames.push(thisPart)
            }
        }
    }
    for (const funcName of funcNames) {
        str = str.replaceAll(`.${funcName}`, `.${funcName.charAt(0).toUpperCase() + funcName.substring(1)}`)
    }
    return str
}


function getIndentation(line) {
    let indentation = 0
    while (isSpace(line[indentation])) {
        if (line[indentation] == '\t') {
            indentation += 4
        } else {
            indentation++
        }
    }
    return indentation
}

function replacePrimitive(line, fromStr, toStr) {
    if (line.includes(fromStr) == false) {
        return line
    }
    const alphabet = 'qwertyuiopasdfghjklzxcvbnm'
    const strStart = line.indexOf(fromStr)
    if (alphabet.includes(line[strStart])) {
        return line
    }
    line = line.replace(fromStr, toStr)
    return replacePrimitive(line, fromStr, toStr)
}

function replaceLambdas(line) {
    if (line.includes('->') == false) {
        return line
    }

    let indentation = getIndentation(line)
    const words = splitCodeIntoTokens(line, [')', '('], Grammar.separators).map(token => token.value)
    const newWords = []
    for (const word of words) {
        if (word.includes('->') == false) {
            newWords.push(word)
            continue
        }

        const types = word.split('->')
        const csType = types[types.length - 1] == 'Void' ? 'Action': 'Func'
        
        if (types[types.length - 1] == 'Void') {
            types.pop()
        }

        const fullType = `${csType}<${types.join(', ')}>`
        newWords.push(fullType)
    }
    
    let newLine = newWords.join(' ')
    newLine = newLine.replaceAll(' (', '(')
    newLine = newLine.replaceAll(' )', ')')
    newLine = newLine.replaceAll('( ', '(')
    newLine = newLine.replaceAll(') ', ')')
    for (let i = 0; i < indentation; i++) {
        newLine = ' ' + newLine
    }

    return newLine
}

function replaceFor(line) {
    if (line.includes("for (") == false) {
        if (line.includes('...') == false) {
            return line
        }
    }

    const varName = findFromTo(line, 'for (', ' in ')
    const fromIndex = findFromTo(line, ' in ', '...')
    const toIndex = findFromTo(line, '...', ')')

    const forStart = line.indexOf('for (')
    const forEnd = line.indexOf('{')

    const beforeFor = line.substring(0, forStart)
    const afterFor = line.substring(forEnd)

    return `${beforeFor}for (int ${varName} = ${fromIndex}; ${varName} < ${toIndex}; ${varName}++)${afterFor}`
}

function replaceConstants(line) {
    if (/^.*var\s*\w+\s*=\s*(["']|true|false|-?\d+(\.\d+)?).*$/.test(line) == false) {
        return line
    }
    line = line.replaceAll("'", '"')
    const words = lex(line, [';', ')', '('])

    const equalI = words.findIndex(word => word == '=')
    const varName = words[equalI - 1]
    let varValue = words[equalI + 1]
    if (varValue == '-') {
        varValue = '-' + words[equalI + 2]
    }
    
    if (varValue == null) {
        return line
    }

    let varType
    if (isNumber(varValue)) {
        if (varValue.includes('.')) {
            varType = 'double'
        } else {
            varType = 'int'
        }
    }
    if (varValue.startsWith('"')) {
        varType = 'string'
    }
    if (varValue == 'true' || varValue == 'false') {
        varType = 'bool'
    }

    if (varType == null) {
        return line
    }
    
    line = line.replaceAll(varName, `${varType} ${varName}`)
    
    return line
}

const allFoundTypeNames = []
function replaceOneType(line) {
    if (line.includes(':') == false) {
        return line
    }

    if (line.includes('case ')) {
        return line
    }

    const words = lex(line)
    const colonI = words.findIndex(word => word == ':')

    let varName
    if (words[colonI - 1] != ')') {
        varName = words[colonI - 1]
    } else {
        let i = colonI - 2
        let parStack = [')']
        while (i >= 0) {
            
            if (Grammar.specialOperators.includes(words[i])) {
                if (words[i] == ')') {
                    parStack.push(')')
                }
                if (words[i] == parStack[parStack.length - 1]) {
                    parStack.pop()
                }
            }

            if (parStack.length == 0) {
                varName = words[i]
            }

            i--
        }
    }

    const stringStack = []
    let colonI = -1
    for (let i = 0; i < line.length; i++) {
        const char = line[i]
        if (stringStack.length == 0 && char == ':') {
            colonI = i
        }
        if (char == '"' || char == "'") {
            if (stringStack.length == 0) {
                stringStack.push(char)
            } else {
                if (stringStack[stringStack.length - 1] == char) {
                    stringStack.pop()
                }
            }
        }
    }

    if (colonI == -1) {
        return line
    }
    
    let leftWordStart = colonI - 1
    while (isSpace(line[leftWordStart])) {
        leftWordStart--
    }
    let leftWordEnd = leftWordStart
    let paranthesisStack = 0
    while (true) {
        if (leftWordEnd < 0) {
            break
        }
        if (line[leftWordEnd] == ')') {
            paranthesisStack++
        }
        if (line[leftWordEnd] == '(') {
            paranthesisStack--
            if (paranthesisStack < 0) {
                break
            }
        }
        if (isSpace(line[leftWordEnd])) {
            if (paranthesisStack == 0) {
                break
            }
        }
        if ([';', ',', '->'].includes(line[leftWordEnd])) {
            break
        }
        leftWordEnd--
    }
    leftWordEnd++
    leftWordStart++ // Fix cause they are 1 too much to the 

    let rightWordStart = colonI + 1
    while (isSpace(line[rightWordStart])) {
        rightWordStart++
    }
    let rightWordEnd = rightWordStart
    let arrowStack = 0
    while (true) {
        if (rightWordEnd >= line.length - 1) {
            break
        }
        if (line[rightWordEnd] == '<') {
            arrowStack++
        } else if (line[rightWordEnd] == '>') {
            arrowStack--
        }
        if (arrowStack == 0) {
            if (isSpace(line[rightWordEnd])) {
                break
            }
            if ([';', ',', '->', ')', '('].includes(line[rightWordEnd])) {
                break
            }
        }
        rightWordEnd++
    }

    const leftWord = line.substring(leftWordEnd, leftWordStart)
    const rightWord = line.substring(rightWordStart, rightWordEnd)
    if (rightWord.trim().length > 0 && Grammar.getAllOperators().includes(rightWord.trim()) == false) {
        allFoundTypeNames.push(rightWord)
    }
    // console.log(`${leftWord} -- ${rightWord}`)
    const newLine = line.substring(0, leftWordEnd) + `${rightWord} ${leftWord}` + line.substring(rightWordEnd)

    return newLine.replaceAll(' var ', ' ')
}

function replaceGenerics(line) {
    if (line.includes('<') == false) {
        return line
    }
    let startArrowI = line.indexOf('<')
    if (line[startArrowI-1] == ' ' || line[startArrowI+1] == ' ') {
        return line
    }
    let collectionTypeI = startArrowI
    while (!isSpace(line[collectionTypeI]) && collectionTypeI > 0) {
        collectionTypeI--
    }
    collectionTypeI++

    const collectionType = line.substring(collectionTypeI, startArrowI)
    
    
    let arrowEndI = startArrowI + 1
    let arrowStack = 1
    while (true) {
        if (line[arrowEndI] == '>') {
            arrowStack--
            if (arrowStack == 0) {
                break
            }
        }
        if (line[arrowEndI] == '<') {
            arrowStack++
        }
        arrowEndI++
    }
    const typeParams = line.substring(startArrowI + 1, arrowEndI)


    if (collectionType == 'Array') {
        return line.substring(0, collectionTypeI) + `${typeParams}[]` + line.substring(arrowEndI + 1)
    }
    return line.substring(0, collectionTypeI) + `${collectionType}<${typeParams}>` + line.substring(arrowEndI + 1)

}

function fixSwitch(line) {
    if (/^.*switch\s*\w+\s\{$/.test(line) == false) {
        return line
    }
    line = line.replaceAll('switch ', 'switch (')
    line = line.replaceAll(' {', ') {')
    return line
}

function replaceConstructorCS(lines) {
    let currentClass
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i]
        if (line.indexOf('public class') != -1) {
            currentClass = findFromTo(line, 'public class ', [' ', '<', '\n'])
        }
        if (line.indexOf('function New') != -1) {
            lines[i] = line.replaceAll('function New', currentClass)
        }
    }
    return lines
}


let debug = true
if (debug) {
    let line = `	public static function getNextIInDirection(i: Int, direction: Int): Int {`
    while (line.includes(':')) {
        const oldLine = line
        line = replaceOneType(line)
        console.log(line)
        if (oldLine == line) {
            break
        }
    }
    process.exit()
}





let haxeFile = fs.readFileSync(hxFolderPath + '\\' + fileName + '.hx', 'utf8')

haxeFile = haxeFile.replaceAll(";", ' ;')
haxeFile = haxeFile.replaceAll("'", '"')
haxeFile = haxeFile.replaceAll(" ->", '->')
haxeFile = haxeFile.replaceAll("-> ", '->')
haxeFile = haxeFile.replaceAll(" inline", '')
haxeFile = haxeFile.replaceAll("@:publicFields ", '')

haxeFile = haxeFile.replaceAll("Std.Int", 'Math.Floor')
haxeFile = haxeFile.replaceAll("Std.int", 'Math.Floor')

haxeFile = haxeFile.replaceAll("final", 'var')

haxeFile = capitalizeFunctions(haxeFile)


const primitivesMapping = {
    'Float': 'double',
    'Int': 'int',
    'Bool': 'bool',
    'String': 'string'
}
allFoundTypeNames.push('double', 'int', 'bool', 'string', 'double[]', 'int[]', 'bool[]', 'string[]')



const haxeLines = haxeFile.split('\n')

let csLines = []
for (let line of haxeLines) {

    if (
        line.includes('import') ||
        line.includes('package scripts') ||
        line.includes('using')
    ) {
        continue;
    }

    if (line.trim().length == 0) {
        csLines.push(line)
        continue
    }

    if (line.startsWith('class')) {
        line = "public " + line
    }
    if (line.includes('switch')) {
        line = fixSwitch(line)
    }
    if (line.includes('...')) {
        line = replaceFor(line)
    }
    if (line.includes('<')) {
        line = replaceGenerics(line)
    }
    if (line.includes('->')) {
        line = replaceLambdas(line)
    }
    if (line.includes('var')) {
        line = replaceConstants(line)
    }
    
    while (line.includes(':')) {
        const oldLine = line
        line = replaceOneType(line)
        if (oldLine == line) {
            break
        }
    }

    for (const hxPrimitive of Object.keys(primitivesMapping)) {
        line = replacePrimitive(line, hxPrimitive, primitivesMapping[hxPrimitive])
    }

    csLines.push(line)
}

csLines = replaceConstructorCS(csLines)

let csFile = csLines.join('\n')

csFile = 'using System;\n\n' + csFile

csFile = csFile.replaceAll(" ;", ';')
csFile = csFile.replaceAll("= []", '= { }')

for (const hxPrimitive of Object.keys(primitivesMapping)) {
    const csPrimitive = primitivesMapping[hxPrimitive]
    csFile = csFile.replaceAll(`function ${csPrimitive}`, csPrimitive)
}
for (const csType of allFoundTypeNames) {
    csFile = csFile.replaceAll(`function ${csType}`, csType)
    csFile = csFile.replaceAll(`var ${csType}`, csType)
}

// Function names
csFile = csFile.replaceAll("function Set", 'void Set')
csFile = csFile.replaceAll("function Is", 'bool Is')
csFile = csFile.replaceAll("function Has", 'bool Has')
csFile = csFile.replaceAll("function Add", 'void Add')
csFile = csFile.replaceAll("function Subtract", 'void Subtract')
csFile = csFile.replaceAll("function Keys", 'string[] Keys')

// Small conversions
csFile = csFile.replaceAll('return ["', 'return new string[] { "')
csFile = csFile.replaceAll('= [', '= { ')
csFile = csFile.replaceAll('"]', '" }')
csFile = csFile.replaceAll('];', ' };')

// Fixes
csFile = csFile.replaceAll('return default', 'default: return')

const finalFileName = csFolderPath + '\\' + folderName + '\\' + fileName + '.cs'
fs.writeFileSync(finalFileName, csFile, { encoding:'utf8' })