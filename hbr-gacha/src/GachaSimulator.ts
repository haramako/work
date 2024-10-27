import { sum } from "./util"

export type CardKind = {
    name: string,
    prob: number,
    value: number,
    duplicatedValue: number
}

function sample(kinds: CardKind[]): CardKind {
    const totalProb = kinds.map(kind => kind.prob).reduce((acc, n) => acc + n)
    const n = Math.random() * totalProb
    let sum = 0
    for (const kind of kinds) {
        if (n <= sum + kind.prob) {
            return kind
        } else {
            sum += kind.prob
        }
    }
    return kinds[kinds.length - 1]
}

export class GachaDraw {
    cost: number
    num: number
    kinds: CardKind[]
    selectable: boolean

    constructor(_cost: number, _num: number, _kinds: CardKind[], _selectable: boolean = false) {
        this.cost = _cost
        this.num = _num
        this.kinds = _kinds
        this.selectable = _selectable
    }

    draw(): CardKind {
        return sample(this.kinds)
    }

    expectedValue(duplication: Map<string, number>): number {
        if (this.selectable) {
            // 選択の場合
            let maxValue = 0
            let maxDuplicatedValue = 0
            for (const k of this.kinds) {
                const dupRate = duplication.get(k.name) ?? 0
                if (dupRate < 1.0) {
                    maxValue = Math.max(maxValue, k.value)
                }
                maxDuplicatedValue = Math.max(maxDuplicatedValue, k.duplicatedValue)
            }
            //console.log([this.kinds, duplication, maxValue, maxDuplicatedValue])
            return Math.max(maxValue, maxDuplicatedValue)
        } else {
            // ガチャの場合
            let value = 0
            let prob = 0
            for (const k of this.kinds) {
                const dupRate = duplication.get(k.name) ?? 0
                value += (1 - dupRate) * k.prob * k.value + dupRate * k.prob * k.duplicatedValue
                prob += k.prob
            }
            return value / prob * this.num
        }
    }

    toJSON() {
        return { ...this }
    }

    expectedTable() {
        if (this.selectable) {
            // 選択の場合
            let maxKind: CardKind = { name: '(Unknown', prob: 0, value: 0, duplicatedValue: 0 }
            for (const k of this.kinds) {
                if (k.value > maxKind.value) {
                    maxKind = k
                }
            }
            return { [maxKind.name]: 1.0 }
        } else {
            // ガチャの場合
            const totalProb = sum(this.kinds, k => k.prob)
            const result: { [key: string]: number } = {}
            for (const k of this.kinds) {
                if (result[k.name] == undefined) {
                    result[k.name] = 0
                }
                result[k.name] += k.prob / totalProb * this.num
            }
            return result
        }
    }
}

function sumTable(table: { [key: string]: number }, sum: { [key: string]: number }) {
    for (const key in sum) {
        table[key] ||= 0
        table[key] += sum[key]
    }
}

export class GachaCampaign {
    draws: GachaDraw[][]

    constructor(_draws: GachaDraw[][]) {
        this.draws = _draws
    }

    toJSON() {
        return this.draws.flat().map(draw => draw.toJSON()).flat()
    }

    totalCost(limit: number = this.draws.length) {
        return sum(this.draws.slice(0, limit).flat(), d => d.cost)
    }

    expectedNums(limit: number = this.draws.length) {
        const result: { [key: string]: number } = {}
        for (const drawList of this.draws.slice(0, limit)) {
            for (const draw of drawList) {
                sumTable(result, draw.expectedTable())
            }
        }
        return result
    }

    drawWhile(limit: number, duplication: Map<string, number>): number[][] {
        //let totalValue = 0
        //let totalCost = 0
        let result = []
        for (let i = 0; i < limit; i++) {
            var draw = this.draws[i]
            const totalCost = sum(draw, d => d.cost)
            const totalValue = sum(draw, d => d.expectedValue(duplication))
            //result.push([totalCost, totalValue])
            result.push([totalCost, totalValue])
        }
        return result
    }
}

