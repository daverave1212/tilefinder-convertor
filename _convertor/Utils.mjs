



const capitalize = (s) => {
    if (typeof s !== 'string') return ''
    return s.charAt(0).toUpperCase() + s.slice(1)
  }

function dashCaseToCamelCase(dashCase) {    // Ex: my-nice-function = myNiceFunction
    let parts = dashCase.split('-')
    if (parts.length == 1) return dashCase
    let firstWord = parts[0]
    parts = parts.slice(1)
    return firstWord + parts.map( str => capitalize(str) ).join('')
}

function spaces(nSpaces) {
    let ret = ''
    for(let i = 1; i<=nSpaces; i++){
        ret += ' '
    }
    return ret
}

function isSpace(text) {
    return (text.trim().length == 0)
}

function isRunningInBrowser() {
    try {
        let x = window
        return true
    } catch (e) {
        return false
    }
}

function doTimes(times, func) {
    for (let i = 1; i<=times; i++) {
        func()
    }
}

function splitArrayByIndicesExclusive(array, indices) {
    if (indices.length == 0) {
        console.log('No indices given.')
        return [array]
    }
    let parts = []
    let start = 0
    for (let index of indices) {
        let part = array.slice(start, index)
        if (part != null && part.length > 0) parts.push(part)
        start = index + 1
    }
    let finalPart = array.slice(start, array.length)
    if (finalPart != null && finalPart.length > 0) parts.push(finalPart)
    return parts
}

const last = array => array[array.length - 1]

export { spaces, dashCaseToCamelCase, capitalize, isSpace, splitArrayByIndicesExclusive, isRunningInBrowser, doTimes, last }