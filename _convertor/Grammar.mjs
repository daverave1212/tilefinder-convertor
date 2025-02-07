

export let operators = ['!=', '?.', '->', '=>', '!', '.', ',', '==', '<=', '>=', '=', '+', '-', '*', '/', ';', ':', '<', '>', '(', ')', '[', ']', '{', '}', '|']
export let specialOperators = ['(', ')', '[', ']', '{', '}', '|']
export const getAllOperators = () => [...operators, ...specialOperators]

export let binaryOperatorPriority = {
    '+': 10,
    '-': 10,
    '*': 15,
    '/': 15,
    '.': 20,
    '=': 0,
    ':': 2.5,
    ',': 2.5,
    '==': 5,
    '!=': 5,
}
export const isOperatorBinary = operatorString => operators.includes(operatorString) && Object.keys(binaryOperatorPriority).includes(operatorString)

export let keywordTypeMapping = {
    '[': '[',
    ']': ']',
    '(': '(',
    ')': ')',
    ':': ':',
    ',': ',',
    '|': '|',
    '{': '{',
    '}': '}',
    '\n': 'NEWLINE',
    'if':           'FLOWCONTROL',
    'elif':         'FLOWCONTROL',
    'while':        'FLOWCONTROL',
    'for':          'FLOWCONTROL',
    'switch':       'FLOWCONTROL',
    'public':       'MODIFIER',
    'private':      'MODIFIER',
    'protected':    'MODIFIER',
    'inline':       'MODIFIER',
    'final':        'MODIFIER',
    'static':       'MODIFIER',
    'override':     'MODIFIER',
    'o':            'VAR',
    'overhead':     'OVERHEAD',
    'class':        'CLASS',
    'data':         'DATA',
    'func':         'FUNC',
    'yaml':         'YAML',
    'else':         'ELSE',
    'constructor':  null
}

export let parenthesisOpposites = {
    '[': ']',
    '(': ')',
    '{': '}'
}

export let separators = {
    '"': '"',
    "'": "'",
    '`': '`',
    '/*': '*/'
}

export function isStringOperator(string){ return this.operators.includes(string) }

export function tokenTypeExists(typeString) {
    const keywordTypeMappingValues = [...new Set(Object.values(keywordTypeMapping))]
    const someTypes = [...keywordTypeMappingValues, ...Object.keys(separators), ...Object.values(separators)]
    const alsoTypes = ['OPERATOR', 'STRING', 'NATIVECODE']
    const allowedTypes = [...someTypes, ...alsoTypes]
    return allowedTypes.includes(typeString)
}


let isString = (str) => str[0] == '"' || str[0] == "'"
let isNativeCode = (str) => str[0] == "`"

export function getTokenType(string) {
    if (string == null || string.length == 0)        throw `Error: string is ${ string==null? 'null' : 'empty' }`
    if (keywordTypeMapping[string] != null)          return keywordTypeMapping[string]
    if (isString(string))                            return 'STRING'
    if (isNativeCode(string))                        return 'NATIVECODE'
    if (this.operators.includes(string))             return 'OPERATOR'
    return 'NODE'
}
