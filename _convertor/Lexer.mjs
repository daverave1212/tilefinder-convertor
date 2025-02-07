
import * as Grammar from './Grammar.mjs'

function isAnySubstringAt(subs, str, start) {   // Returns the index of the sub
    for (let i = 0; i < subs.length; i++) {
        let sub = subs[i]
        let result = str.startsWith(sub, start)
        if (result == true) {
            return i
        }
    }
    return null
}
function isOperator(text, position, operators) {
    let result = isAnySubstringAt(operators, text, position)
    if (result != null) {
        return operators[result]
    }
    return null
}
// Checks if text[position:] starts with any of the possible separators
// Returns the openSeparators as a string, or None
function startsSeparator(text, position, allSeparators) {
    let startSeparators = Object.keys(allSeparators)
    let separatorIndex  = isAnySubstringAt(startSeparators, text, position)    // All 'operators' that start a string
    if (separatorIndex != null) {
        return startSeparators[separatorIndex]
    }
    return null
}
// Checks if text[position:] is equal to the given separator
function endsString(text, position, closeSeparator) {
    let result = text.startsWith(closeSeparator, position)
    //let result = isSubstringAt(separator, text, position)
    if (result != null) return result
    return null
}

// Takes a string and counts how many spaces it has in front of it
function findIndentation(text) {
    let indentation = 0
    let firstCharPos = 0
    for (let char of text) {
        if (char == '\t') {
            indentation += 4
            firstCharPos += 1
        }
        else if (char == ' ' ) {
            indentation += 1
            firstCharPos += 1
        }
        else break
    }
    return { indentation, firstCharPos }
}


class Lexer {

    tokens = []
    currentCharIndex = 0
    state = 'blanks'
    setState(newState) {
        if (!['blanks', 'words', 'string'].includes(newState)) throw `State ${newState} not valid.`
        this.state = newState
    }

    start = 0   // The start of the current token, used below
    markStartHere() { this.start = this.currentCharIndex }

    stringOpener = null // Used to remember the string opener

    constructor(code, operators, separators) {
        this.code = code
        this.operators = operators
        this.separators = separators
    }

    split() {
        while (this.currentCharIndex < this.code.length) {
            switch (this.state) {
                case 'blanks'   : this.stepBlank(); break
                case 'words'    : this.stepOther(); break
                case 'string'   : this.stepString(); break
                default         : throw `Lexer Error: state ${this.state} not handled!`
            }
            this.currentCharIndex ++
        }
        if (this.state == 'words') {
            this.pushWord()
        }
        return this.tokens
    }

    getLastPushedToken() { return this.tokens[this.tokens.length - 1] }
    getCurrentChar() { return this.code[this.currentCharIndex] }
    getCurrentOpenSeparator() { return startsSeparator(this.code, this.currentCharIndex, this.separators) }
    isAtStringEnd() { return endsString(this.code, this.currentCharIndex, this.separators[this.stringOpener]) }

    pushWord(type) {    // Pushes the current word from 'start' to 'currentWordIndex'
        let theWord = this.code.substring(this.start, this.currentCharIndex)
        this.tokens.push({
            value: theWord,
            type: type == null? Grammar.getTokenType(theWord) : type
        })
    }
    pushUpcomingOperatorAndAdvance() {    // Will only be called if an it's at an operator
        let theOperator = isOperator(this.code, this.currentCharIndex, this.operators)
        this.tokens.push({
            value: theOperator,
            type: Grammar.getTokenType(theOperator)
        })
        this.currentCharIndex += theOperator.length - 1 // Move the cursor at the end position of the operator
    }

    getCharMeaning() {  // 'blank', 'newline', 'operator-start', 'string-start', 'other'
        const isBlank = () => this.getCurrentChar() == ' ' || this.getCurrentChar() == '\n' || this.getCurrentChar() == '\t'
        const isOperatorStart = () => isOperator(this.code, this.currentCharIndex, this.operators) != null
        const isStringStart = () => startsSeparator(this.code, this.currentCharIndex, this.separators) != null
        if (this.getCurrentChar() == '\n') return 'newline'
        if (isBlank()) return 'blank'
        if (isOperatorStart()) return 'operator-start'
        if (isStringStart()) return 'string-start'
        return 'other'
    }


    // States
    stepBlank() {
        switch (this.getCharMeaning()) {
            case 'blank': break
            case 'newline':
                if (this.getLastPushedToken().value != '\n')
                    this.tokens.push({
                        value: '\n',
                        type: 'NEWLINE'
                    })
                break
            case 'operator-start':
                this.pushUpcomingOperatorAndAdvance()
                break
            case 'string-start':
                this.stringOpener = this.getCurrentOpenSeparator()
                this.markStartHere()
                this.setState('string')
                break
            case 'other':
                this.markStartHere()
                this.setState('words')
                break
            default:
                throw `Unknown char meaning ${this.getCharMeaning()}`
        }
    }
    stepOther() {   // Aka words or keywords
        switch (this.getCharMeaning()) {
            case 'blank':
            case 'newline':
                this.pushWord()
                this.stepBlank()
                this.setState('blanks')
                break
            case 'operator-start':
                this.pushWord()
                this.pushUpcomingOperatorAndAdvance()
                this.setState('blanks')
                break
            case 'string-start':
                this.stringOpener = this.getCurrentOpenSeparator()
                this.markStartHere()
                this.setState('string')
                break
            case 'other':
                break
        }
    }
    stepString() {
        if (this.isAtStringEnd()) {
            this.currentCharIndex += this.separators[this.stringOpener].length
            this.pushWord()
            this.currentCharIndex --
            this.setState('blanks')
        }
    }
}


export function splitCodeIntoTokens(code, operators, separators) {
    return (new Lexer(code, operators, separators)).split()
}
