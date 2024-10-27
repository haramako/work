import { CardKind, GachaCampaign, GachaDraw } from "./GachaSimulator"
import { GachaParam } from "./stat"
import { sum } from "./util"

export function create200renCampaign(normal: GachaDraw, _20ren: GachaDraw | undefined, _50ren: GachaDraw | undefined, _100ren: GachaDraw | undefined, _tenjo: GachaDraw[]): GachaCampaign {
    const repeat = (n: number, item: GachaDraw[]) => Array(n).fill(0).map(() => item)
    const exist = (item: GachaDraw | undefined) => (item == undefined ? [] : [item])
    const draws = [
        ...repeat(1, [normal]),
        [normal, ...exist(_20ren)],
        ...repeat(2, [normal]),
        [normal, ...exist(_50ren)],
        ...repeat(4, [normal]),
        [normal, ...exist(_100ren)],
        ...repeat(9, [normal]),
        [normal, ..._tenjo]
    ]
    return new GachaCampaign(draws)
}

export function makePickup200(gp: GachaParam, pickupOne: boolean) {
    let kinds: CardKind[]
    if (pickupOne) {
        kinds = [
            { name: 'SS', prob: 0.02, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
            { name: 'Pickup', prob: 0.01, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
        ]
    } else {
        kinds = [
            { name: 'SS', prob: gp.ssProb / 100, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
            { name: 'Pickup', prob: gp.pickupProb / 100 / 2, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
            { name: 'Pickup2', prob: gp.pickupProb / 100 / 2, value: gp.pickup2Value, duplicatedValue: gp.pickup2DuplicatedValue },
        ]
    }

    const kindsTicket = [
        { name: 'SS', prob: 1.0, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
    ]
    const totalProb = sum(kinds, k => k.prob)
    const kindsWithNonSS = [...kinds, { name: 'NonSS', prob: 1.0 - totalProb, value: 0, duplicatedValue: 0 }]
    const kindsTenjo = kinds.filter(k => k.name == "Pickup" || k.name == 'Pickup2')
    const kindsPiece = [{ name: 'Piece', prob: 1.0, value: gp.pieceValue, duplicatedValue: gp.pieceValue }]

    const draw = new GachaDraw(3000, 10, kindsWithNonSS)
    const _20ren = new GachaDraw(0, 1, kindsPiece)
    const _ssTicket = new GachaDraw(0, 1, kindsTicket)
    const _100ren = new GachaDraw(0, 2, kindsPiece)
    const _200ren = new GachaDraw(0, 1, kindsTenjo, true)
    const campaign = create200renCampaign(draw, _20ren, _ssTicket, _100ren, [_ssTicket, _200ren])

    return campaign
}

export function makeSelect(gp: GachaParam) {
    // セレクトガチャ
    const kindsSelect = [
        { name: 'Select', prob: gp.selectProb / 100, value: gp.selectValue, duplicatedValue: gp.selectDuplicatedValue },
    ]
    const kindsSelectWithNonSS = [...kindsSelect, { name: 'NonSS', prob: 1 - gp.selectProb / 100, value: 0, duplicatedValue: 0 }]
    const drawSelect = new GachaDraw(3000, 9, kindsSelectWithNonSS)
    const drawSelect10 = new GachaDraw(0, 1, kindsSelect)
    const campaignSelect = new GachaCampaign([[drawSelect, drawSelect10]])

    return campaignSelect
}

// ステップアップ
export function makeStepup(gp: GachaParam, zokusei: boolean) {
    let kinds: CardKind[]
    let kindsStepupKakutei: CardKind[]
    if (zokusei) {
        kinds = [
            { name: 'SS', prob: 0.015, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
            { name: 'Zokusei', prob: 0.015, value: gp.zokuseiValue, duplicatedValue: gp.zokuseiDuplicatedValue },
        ]
        kindsStepupKakutei = [
            { name: 'SS', prob: 0.9, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
            { name: 'Zokusei', prob: 0.1, value: gp.zokuseiValue, duplicatedValue: gp.zokuseiDuplicatedValue },
        ]
    } else {
        kinds = [
            { name: 'SS', prob: gp.ssProb / 100, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
            { name: 'Pickup', prob: gp.pickupProb / 100 / 2, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
            { name: 'Pickup2', prob: gp.pickupProb / 100 / 2, value: gp.pickup2Value, duplicatedValue: gp.pickup2DuplicatedValue },
        ]
        kindsStepupKakutei = [
            { name: 'SS', prob: 0.9, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
            { name: 'Pickup', prob: 0.05, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
            { name: 'Pickup2', prob: 0.05, value: gp.pickup2Value, duplicatedValue: gp.pickup2DuplicatedValue },
        ]
    }
    const totalProb = sum(kinds, k => k.prob)
    const kindsWithNonSS = [...kinds, { name: 'NonSS', prob: 1.0 - totalProb, value: 0, duplicatedValue: 0 }]

    const drawStepupKakutei = new GachaDraw(0, 1, kindsStepupKakutei)
    const drawStep1 = new GachaDraw(100, 1, kindsWithNonSS)
    const drawStep2 = new GachaDraw(1500, 10, kindsWithNonSS)
    const drawStep3 = new GachaDraw(2000, 10, kindsWithNonSS)
    const drawStep4 = new GachaDraw(3000, 9, kindsWithNonSS)
    const campaignStepup = new GachaCampaign([[drawStep1], [drawStep2], [drawStep3], [drawStep4, drawStepupKakutei]])

    return campaignStepup
}

