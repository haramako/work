import { atom, DefaultValue, selectorFamily } from 'recoil'

export type GachaStat = {
    key: number,
    name: string,
    prob: number,
    value: number,
    duplicatedValue: number,
}

export type GachaParam = {
    pieceValue: number, // SS万能ピースの価値
    ssOwnRate: number, // SS所持率
    ssMaxRate: number, // SS所持率
    ssProb: number, // SSの確率
    ssValue: number, // SSの価値
    ssDuplicatedValue: number, // SSの価値（かぶり）
    pickupProb: number, // ピックアップの確率
    pickupValue: number, // ピックアップの価値
    pickupDuplicatedValue: number, // ピックアップの価値（かぶり）
    selectProb: number,
    selectValue: number, // セレクトの価値
    selectDuplicatedValue: number, // セレクトの価値（かぶり）
    selectOwnRate: number, // セレクトの所持率
}

const defaultGachaParam: GachaParam = {
    pieceValue: 5,
    ssOwnRate: 30,
    ssMaxRate: 0,
    ssProb: 1.5,
    ssValue: 100,
    ssDuplicatedValue: 20,
    pickupProb: 1.5,
    pickupValue: 300,
    pickupDuplicatedValue: 50,
    selectProb: 3,
    selectValue: 200,
    selectDuplicatedValue: 30,
    selectOwnRate: 50,
}

const defaultGachaState: GachaStat[] = [
    {
        key: 1,
        name: 'SS',
        prob: 0.15,
        value: 1.0,
        duplicatedValue: 0.1
    },
    {
        key: 2,
        name: 'ピックアップ',
        prob: 0.15,
        value: 3.0,
        duplicatedValue: 0.3
    },
]

export type TableDesc = {
    label: string
    drawTable: { [key: string]: number }
    totalCost: number
}

export type RootStat = {
    gachaParam: GachaParam
    gacha: GachaStat[]
    selectedTable?: TableDesc
}

export const rootState = atom<RootStat>({
    key: 'rootState',
    default: {
        gachaParam: defaultGachaParam,
        gacha: defaultGachaState,
        selectedTable: undefined
    }
})

export const gachaState = selectorFamily({
    key: 'gachaState',
    get: (key: number) => ({ get }) => {
        return get(rootState).gacha.find(item => item.key == key)
    },
    set: (key: number) => ({ get, set }, newValue) => {
        const root = get(rootState)
        const newValue2 = newValue instanceof DefaultValue ? { key, name: '', prob: 0, value: 0, duplicatedValue: 0 } : newValue as GachaStat
        set(rootState, { ...root, gacha: root.gacha.map(item => item.key == key ? newValue2 : item) })
    }
})

