
import { last } from './Utils.mjs'
import { Node, createMockNodes } from './Expressions.mjs'
import * as Grammar from './Grammar.mjs'


class ExpressizerStates {

    states = {
        '$line': {
            'default':      () => {}
        },
        '$binary-expression-left': {
            'NODE':         () => {
                this.push(this.currentNode)
                this.setState('$binary-expression-operator')
            },
            'default':      () => this.error(`Bad token type recieved.`)
        },
        '$binary-expression-operator': {
            'OPERATOR':     () => {
                if (this.currentExpression.getLeft().isBinaryExpression()) {
                    const thisOperatorPriority = Grammar.binaryOperatorPriority[this.currentNode.content]
                    const leftOperatorPriority = this.currentExpression.getLeft().getBinaryOperatorPriority()
                    if (thisOperatorPriority == leftOperatorPriority) {
                        this.wrapLeftAndGoIn('EXPRESSION:BINARY:' + this.currentNode.content)
                        this.setState('$binary-expression-right')
                    } else if (thisOperatorPriority > leftOperatorPriority) {
                        this.goLeft()
                        const rightIsBinary = () => this.currentExpression.getRight().isBinaryExpression()
                        const rightIsLowerPrio = () => thisOperatorPriority > this.currentExpression.getRight().getBinaryOperatorPriority()
                        while (rightIsBinary() && rightIsLowerPrio()) {
                            this.goRight()
                        }
                        this.wrapRightAndGoIn('EXPRESSION:BINARY:' + this.currentNode.content)
                        this.setState('$binary-expression-right')
                    }
                } else {
                    this.wrapLeftAndGoIn('EXPRESSION:BINARY:' + this.currentNode.content)
                    this.setState('$binary-expression-right')
                }
            },
            'default':      () => this.error(`Bad token type recieved.`)
        },
        '$binary-expression-right': {
            'NODE':         () => {
                this.push(this.currentNode)
                while (this.currentExpression.content.length >= 2) {
                    this.branchBack()
                }
                this.setState('$binary-expression-operator')
            },
            'default':      () => this.error(`Bad token type recieved.`)
        }
    }

}


class Expressizer extends ExpressizerStates {

    givenExpression     // Given expression as argument
    baseExpression      // Base expression
    currentExpression   // Iteration expression
    stateStack = ['$binary-expression-left']

    
    getCurrentState = () => last(this.stateStack)
    setState = state => this.stateStack[this.stateStack.length - 1] = state
    addAccessModifier = modifierString => this.currentExpression.addAccessModifier.push(modifierString)
    error(msg) {
        throw `Error in state "${this.getCurrentState()}", at node type "${this.currentNode.type}": ${msg};\n Node content: ${this.currentNode.content}`
    }

    constructor(givenExpression) {
        super()
        this.givenExpression = givenExpression
        this.currentExpression = new Node({
            type: givenExpression.type,
            content: [],
            parent: givenExpression.parent
        })
        this.baseExpression = this.currentExpression
    }

    push(node) {
        node.parent = this.currentExpression
        this.currentExpression.content.push(node)
    }
    goLeft() { this.currentExpression = this.currentExpression.getLeft() }
    goRight() { this.currentExpression = last(this.currentExpression.content) }
    branchOut(type, newState) {
        let newExpression = new Node({
            parent: this.currentExpression,
            content: [],
            type: type
        })
        this.stateStack.push(newState)
        this.currentExpression = newExpression
    }
    branchBack() { this.currentExpression = this.currentExpression.parent }
    wrapLeftAndGoIn(wrapperType) {
        let lastAddedNode = this.currentExpression.content.pop()
        let wrapperNode = new Node({
            parent: this.currentExpression,
            content: [lastAddedNode],
            type: wrapperType
        })
        this.currentExpression.content.push(wrapperNode)
        lastAddedNode.parent = wrapperNode
        this.currentExpression = wrapperNode
    }
    wrapRightAndGoIn(wrapperType) { this.wrapLeftAndGoIn(wrapperType) }
    redirectToState(toWhichState) { this.states[toWhichState][this.currentNode.getBaseType()]() }
    redirectToSymbol(symbol) { this.states[this.getCurrentState()][symbol]() }


    expressize() {
        // console.log(`> Starting at state stack: ${this.stateStack}`)
        for (let node of this.givenExpression.content) {
            this.currentNode = node
            if (this.states[this.getCurrentState()] == null)
                throw `State ${currentState} does not exist`
            const stateSymbol = this.states[this.getCurrentState()][node.getBaseType()] == null ? 'default' : node.getBaseType()
            // console.log(`> Entering state "${this.getCurrentState()}" with "${stateSymbol}"`)
            this.states[this.getCurrentState()][stateSymbol]()
        }
        return this.baseExpression
    }
}


let testExpression = createMockNodes([ 'a', '+', 'b', '+', 'c', '*', 'd', '.', 'e' ])

// testExpression = createMockNodes([ 'a', '.', 'b', '.', 'c' ])
// console.log(testExpression.toString())

let newExpression = (new Expressizer(testExpression).expressize())
console.log(newExpression.toString())