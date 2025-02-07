
/*
    If a Node has children, it's an expression
    Otherwise, it's a node

    The type of an expression looks like: EXPRESSION:GENERIC or EXPRESSION or SCOPE

    All Expression types:
        SCOPE
        EXPRESSION
        EXPRESSION:PARENTHESIS
        EXPRESSION:GENERIC
        EXPRESSION:INDEX
        EXPRESSION:LINE


*/



String.prototype.toJsonObject = function() { return this }

import { spaces } from './Utils.mjs'
import * as Grammar from './Grammar.mjs'

function assertTypeAndContentCorrect(givenType, content, msg) {
    const singleTypes = ['NODE', 'OPERATOR']
    const arrayContentTypes = ['EXPRESSION', 'SCOPE']
    const expressionSubtypes = ['PARENTHESIS', 'GENERIC', 'INDEX', 'LINE', 'BINARY']
    const binaryExpressionTypes = ['+', '-', '*', '/', '.']
    const typeParts = givenType.split(':')
    if (![...singleTypes, ...arrayContentTypes].includes(typeParts[0])) throw `${msg}: Type ${givenType} is illegal.`
    if (typeParts.length > 1 && !expressionSubtypes.includes(typeParts[1])) throw `${msg}: Type ${givenType} is illegal.`
    if (typeParts.length > 2 && !binaryExpressionTypes.includes(typeParts[2])) throw `${msg}: Type ${givenType} is illegal.`
    if (Array.isArray(content) && singleTypes.includes(givenType)) throw `${msg}: Type ${givenType} can not have children.`
    if (!Array.isArray(content) && arrayContentTypes.includes(givenType)) throw `${msg}: Type ${givenType} must have children (it has ${content}).`    
}

class Node {

    content             // A String or an array of Node
    type                // A normal type or EXPRESSION or EXPRESSION:SUBTYPE or SCOPE
    parent              // A Node or a Scope
    accessModifiers     // List of String
    isTuple = false

    constructor({content, type, parent, accessModifiers = [], isTuple=false}) {
        assertTypeAndContentCorrect(type, content, 'in Node constructor')
        this.content = content
        this.type = type
        this.parent = parent
        this.accessModifiers = accessModifiers
        this.isTuple = isTuple
    }

    hasChildren() { return Array.isArray(this.content) }    // Is expression
    isExpression() { return this.type.split(':')[0] == 'EXPRESSION' }
    isEmptyExpression() { return this.isExpression() && this.content.length == 0 }
    isBinaryExpression() { return this.type.split(':')[1] == 'BINARY' }
    isScope() { return this.type == 'SCOPE' }
    getBaseType() { return this.type.split(':')[0] }
    getSubtype() {
        if (this.hasChildren() == false) return null
        let typeParts = this.type.split(':')
        if (typeParts.length == 1) return null
        return typeParts[1]
    }

    // Only for binary expressions
    getLeft = () => this.content[0]
    setLeft = left => { if (this.content.length == 0) this.content.push(left); else throw `Can't set left; already set!` } 
    getRight = () => this.content[1]
    setRight = right => { if (this.content.length == 1) this.content.push(right); else throw `Can't set right; already set or left not set!` } 
    getBinaryOperatorPriority() {
        if (this.isBinaryExpression()) {
            let operator = this.type.split(':')[2]
            return Grammar.binaryOperatorPriority[operator]
        } else {
            throw `This expression is not a binary expression, but ${this.type}`
        }
    }


    clone() {
        let theClone = new Node({
            parent: this.parent,
            content: this.hasChildren()?
                this.content.map(elem => elem.clone()):
                this.content,
            type: this.type,
            accessModifiers: this.accessModifiers.map(x => x),
            isTuple: this.isTuple
        })
        return theClone
    }

    toString(indentLevel=0, details=false) {
        if (this.isScope()) {
            let rest = spaces(indentLevel) + '{'
                rest += details? ` // ${this.content.length} elements\n` : '\n'
                rest += this.content.map(elem => elem.toString(indentLevel + 4)).join('\n')
                rest += '\n' + spaces(indentLevel) + '}'
            return rest
        } else if (this.isExpression()) {
            let content
            if (this.isTuple)
                content = this.content.map(elem => elem.toString()).join(', ')
            else
                content = this.content.map(elem => elem.toString()).join(' ')
            let wrappedContent
            let subtype = this.getSubtype()
            if (subtype == null) wrappedContent = this.type + '(' + content + ')'
            else switch (subtype) {
                case 'GENERIC': wrappedContent = this.type + '<' + content + '>'; break
                case 'INDEX': wrappedContent = this.type + '[' + content + ']'; break
                case 'LINE': wrappedContent = content; break
                case 'BINARY': wrappedContent = this.type.split(':')[2] + '(' + content + ')'; break
                case 'PARENTHESIS':
                default: wrappedContent = this.type + '(' + content + ')'; break
            }
            if (this.accessModifiers.length > 0) {
                let accessModifiers = this.accessModifiers.join(' ')
                wrappedContent = accessModifiers + ' ' + wrappedContent
            }
            return spaces(indentLevel) + wrappedContent
        } else {
            return this.content
        }
    }
}

function createMockNodes(nodesList, isRootLine=true) {
    function makeNodeFromString(nodeString, parent) {
        const parts = nodeString.split(' ')
        const content = parts[0]
        const type = parts.length > 1 ? parts[1] : Grammar.getTokenType(content)
        return new Node({type, content, parent})
    }
    let baseExpression = new Node({type: isRootLine? 'EXPRESSION:LINE' : 'EXPRESSION:PARENTHESIS', parent: null, content: []})
    for (let node of nodesList) {
        if (typeof(node) === 'string')
            baseExpression.content.push(makeNodeFromString(node))
        else if (Array.isArray(node)) {
            baseExpression.content.push(createMockNodes(node), false)
        } else {
            const { type, content } = node
            let childExpression = createMockNodes(content, false)
            if (type != null) childExpression.type = type
            baseExpression.content.push(childExpression)
        }
    }
    return baseExpression
}

export { Node, createMockNodes }