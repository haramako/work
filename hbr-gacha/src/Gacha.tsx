import { useRecoilState, useRecoilValue } from 'recoil'
import { GachaParam, GachaStat, rootState, TableDesc } from './stat'
import { Bar, BarChart, CartesianGrid, Legend, Line, LineChart, Tooltip, XAxis, YAxis } from 'recharts'
import { create200renCampaign, GachaCampaign, GachaDraw } from './GachaSimulator'
import { sum } from './util'

export function GachaStatView({ stat, onChange }: { stat: GachaStat, onChange: (newValue: GachaStat) => void }) {
    return (
        <div>
            {stat.name} &nbsp;
            確率 <input type="number" step="0.1" min="0" max="1.0" value={stat.prob} onChange={e => onChange({ ...stat, prob: Number.parseFloat(e.target.value) })} />
            価値 (初) <input type="number" step="0.1" min="0" value={stat.value} onChange={e => onChange({ ...stat, value: Number.parseFloat(e.target.value) })} />
            価値（かぶり）<input type="number" step="0.1" min="0" value={stat.duplicatedValue} onChange={e => onChange({ ...stat, duplicatedValue: Number.parseFloat(e.target.value) })} />
        </div>
    )
}

function makePickup200(gp: GachaParam) {
    const kinds = [
        { name: 'SS', prob: gp.ssProb / 100, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
        { name: 'Pickup', prob: gp.pickupProb / 100, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
    ]
    const kindsTicket = [
        { name: 'SS', prob: 1.0, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
    ]
    const totalProb = sum(kinds, k => k.prob)
    const kindsWithNonSS = [...kinds, { name: 'NonSS', prob: 1.0 - totalProb, value: 0, duplicatedValue: 0 }]
    const kindsTenjo = kinds.filter(k => k.name == "Pickup")
    const kindsPiece = [{ name: 'Piece', prob: 1.0, value: gp.pieceValue, duplicatedValue: gp.pieceValue }]

    const draw = new GachaDraw(3000, 10, kindsWithNonSS)
    const _20ren = new GachaDraw(0, 1, kindsPiece)
    const _50ren = new GachaDraw(0, 1, kindsTicket)
    const _100ren = new GachaDraw(0, 2, kindsPiece)
    const _200ren = new GachaDraw(0, 1, kindsTenjo)
    const campaign = create200renCampaign(draw, _20ren, _50ren, _100ren, [_50ren, _200ren])
    const owns = new Map<string, number>([['SS', gp.ssOwnRate / 100]])
    const result = campaign.drawWhile(20, owns)
    const result10 = campaign.drawWhile(1, owns)
    const result50 = campaign.drawWhile(5, owns)
    const resultAfterPickup = campaign.drawWhile(20, new Map<string, number>([['SS', gp.ssOwnRate / 100], ['Pickup', 0.5]]))

    return {
        campaign,
        result,
        result10,
        result50,
        resultAfterPickup,
    }
}

function makeSelect(gp: GachaParam) {
    // セレクトガチャ
    const kindsSelect = [
        { name: 'Select', prob: gp.selectProb / 100, value: gp.selectValue, duplicatedValue: gp.selectDuplicatedValue },
    ]
    const kindsSelectWithNonSS = [...kindsSelect, { name: 'NonSS', prob: 1 - gp.selectProb / 100, value: 0, duplicatedValue: 0 }]
    const drawSelect = new GachaDraw(3000, 9, kindsSelectWithNonSS)
    const drawSelect10 = new GachaDraw(0, 1, kindsSelect)
    const campaignSelect = new GachaCampaign([[drawSelect, drawSelect10]])
    const resultSelect = campaignSelect.drawWhile(1, new Map<string, number>([['SS', gp.ssOwnRate / 100], ['Select', gp.selectOwnRate / 100]]))

    return { campaignSelect, resultSelect }
}

function makeStepup(gp: GachaParam) {
    // ステップアップ
    const kinds = [
        { name: 'SS', prob: gp.ssProb / 100, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
        { name: 'Pickup', prob: gp.pickupProb / 100, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
    ]
    const totalProb = sum(kinds, k => k.prob)
    const kindsWithNonSS = [...kinds, { name: 'NonSS', prob: 1.0 - totalProb, value: 0, duplicatedValue: 0 }]
    const kindsStepupKakutei = [
        { name: 'SS', prob: 0.9, value: gp.ssValue, duplicatedValue: gp.ssDuplicatedValue },
        { name: 'Pickup', prob: 0.1, value: gp.pickupValue, duplicatedValue: gp.pickupDuplicatedValue },
    ]

    const drawStepupKakutei = new GachaDraw(0, 1, kindsStepupKakutei)
    const drawStep1 = new GachaDraw(100, 1, kindsWithNonSS)
    const drawStep2 = new GachaDraw(1500, 10, kindsWithNonSS)
    const drawStep3 = new GachaDraw(2000, 10, kindsWithNonSS)
    const drawStep4 = new GachaDraw(3000, 9, kindsWithNonSS)
    const campaignStepup = new GachaCampaign([[drawStep1], [drawStep2], [drawStep3], [drawStep4, drawStepupKakutei]])
    const resultStepup = campaignStepup.drawWhile(4, new Map<string, number>([['SS', gp.ssOwnRate / 100], ['Pickup', 0]]))

    return { campaignStepup, resultStepup }
}

function GachaChart() {
    const stat = useRecoilValue(rootState)
    const gp = stat.gachaParam
    const { result, result50, resultAfterPickup } = makePickup200(gp)

    function restValue(result: number[][], i: number) {
        if (i >= result.length) {
            return undefined
        } else {
            return sum(result.slice(i, result.length), n => n[1]) / (result.length - i)
        }
    }
    const data = result.map((r, i) => ({
        cost: ((i + 1) * 10),
        value: r[1],
        draw200: restValue(result, i),
        draw50: restValue(result50, i),
        draw200AfterPickup: restValue(resultAfterPickup, i),
    }))

    return <>
        <LineChart width={600} height={300} data={data} >
            <XAxis dataKey="cost" />
            <YAxis />
            <Tooltip />
            <Legend />
            <CartesianGrid stroke="#eee" strokeDasharray="5 5" />
            <Line type="monotone" dataKey='value' stroke="#8884d8" name='その回の価値' strokeDasharray="4 4" />
            <Line type="monotone" dataKey='draw200' stroke="#ff0000" name='200連' />
            <Line type="monotone" dataKey='draw50' stroke="#ffff00" name='50連' />
            <Line type="monotone" dataKey='draw200AfterPickup' stroke="#00ff00" name='200連(PU取得後)' />
        </LineChart>
    </>
}

function GachaBar() {
    const [stat, setStat] = useRecoilState(rootState)
    const gp = stat.gachaParam
    const { campaign, result, result10, result50 } = makePickup200(gp)

    const { campaignSelect, resultSelect } = makeSelect(gp)
    const { campaignStepup, resultStepup } = makeStepup(gp)

    function totalValu(result: number[][]) {
        return parseFloat((sum(result, n => n[1]) / sum(result, n => n[0]) * 3000).toFixed(2))
    }

    const data = [
        {
            name: 'PU200連',
            value: totalValu(result),
            campaign: campaign,
            limit: 20,
        },
        {
            name: 'PU50連',
            value: totalValu(result50),
            campaign: campaign,
            limit: 5,
        },
        {
            name: 'PU10連',
            value: totalValu(result10),
            campaign: campaign,
            limit: 1,
        },
        {
            name: '★セレチケ10連',
            value: totalValu(resultSelect),
            campaign: campaignSelect,
            limit: 1,
        },
        {
            name: '★ステップ31連',
            value: totalValu(resultStepup),
            campaign: campaignStepup,
            limit: 4,
        },
    ]

    function onClickChart(label: string) {
        const payload = data.find(d => d.name == label)
        if (payload != undefined) {
            const campaign = payload.campaign
            setStat({
                ...stat,
                selectedTable: {
                    label: payload.name,
                    drawTable: campaign.expectedNums(payload.limit),
                    totalCost: campaign.totalCost(payload.limit)
                }
            })
        }
    }

    return <>
        <BarChart width={600} height={300} data={data} onClick={e => e.activeLabel && onClickChart(e.activeLabel)}>
            <XAxis dataKey="name" />
            <YAxis />
            <Legend />
            <Tooltip />
            <Bar dataKey="value" fill="#8884d8" name='3000クォーツあたりの価値' />
        </BarChart>
    </>
}

const PickupNames = ['PU200連', 'PU50連', 'PU10連']

const KindNames: { [_: string]: string } = {
    'SS': 'SS（対象以外)',
    'Pickup': 'ピックアップ',
    'Select': 'セレクト',
    'NonSS': 'SS以外',
    'Piece': '万能SSピース'
}

function GachaTable({ desc }: { desc: TableDesc }) {
    return (<>
        <h3>{desc.label}</h3>
        <p>コスト: {desc.totalCost}</p>
        <table className="tbl">
            <thead>
                <tr><th className="w80">種類</th><th className="w40">平均取得数</th></tr>
            </thead>
            <tbody>
                {Object.entries(desc.drawTable).map(([k, v]) => {
                    return <tr key={k}><td>{KindNames[k]}</td><td>{v.toFixed(2)}</td></tr>
                })}
            </tbody>
        </table>
        {PickupNames.includes(desc.label!) && <><h4>期待値グラフ</h4><GachaChart /></>}
    </>)
}

export function GachaList() {
    const [stat, setStat] = useRecoilState(rootState)
    const gp = stat.gachaParam

    /*
    function onClickAddButton() {
        const empty = {
            key: stat.gacha.map(g => g.key).reduce((acc, n) => Math.max(acc, n)) + 1,
            name: '',
            prob: 0,
            value: 1.0,
            duplicatedValue: 0.1
        }
        setStat({ ...stat, gacha: [...stat.gacha, empty] })
    }
        */

    function onChange(name: string, value: string) {
        setStat({ ...stat, gachaParam: { ...stat.gachaParam, [name]: parseFloat(value) } })
    }

    return (
        <>
            <GachaBar />
            {/*
            stat.gacha.map(s => <GachaStatView key={s.key} stat={s} onChange={onChangeStat(s.key)} />)
            <button onClick={onClickAddButton}>追加</button>
            */}
            <hr />
            <table>
                <thead>
                    <tr><th></th><th>価値</th><th>価値（かぶり）</th></tr>
                </thead>
                <tbody>
                    <tr>
                        <td>万能SSピース</td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.pieceValue} onChange={e => onChange('pieceValue', e.target.value)} /></td>
                    </tr>
                    <tr><td>SS(ピックアップ以外)</td>
                        {/*<td>確率</td><td><input type="number" step="1" min="0" max="100" value={gp.ssProb} onChange={e => onChange('ssProb', e.target.value)} /></td>*/}
                        <td><input className="inp" type="number" step="10" min="0" value={gp.ssValue} onChange={e => onChange('ssValue', e.target.value)} /></td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.ssDuplicatedValue} onChange={e => onChange('ssDuplicatedValue', e.target.value)} /></td>
                        <td>　所持率</td><td><input className="inp" type="number" step="10" min="0" max="100" value={gp.ssOwnRate} onChange={e => onChange('ssOwnRate', e.target.value)} />%</td>
                        <td>　完凸率</td><td><input className="inp" type="number" step="10" min="0" max="100" value={gp.ssMaxRate} onChange={e => onChange('ssMaxRate', e.target.value)} />%</td>
                    </tr>
                    <tr>
                        <td>ピックアップ</td>
                        {/*<td>確率</td><td><input type="number" step="1" min="0" max="100" value={gp.pickupProb} onChange={e => onChange('pickupProb', e.target.value)} /></td>*/}
                        <td><input className="inp" type="number" step="10" min="0" value={gp.pickupValue} onChange={e => onChange('pickupValue', e.target.value)} /></td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.pickupDuplicatedValue} onChange={e => onChange('pickupDuplicatedValue', e.target.value)} /></td>
                    </tr>
                    <tr>
                        <td>セレクト</td>
                        {/*<td>確率</td><td><input type="number" step="1" min="0" max="100" value={gp.pickupProb} onChange={e => onChange('pickupProb', e.target.value)} /></td>*/}
                        <td><input className="inp" type="number" step="10" min="0" value={gp.selectValue} onChange={e => onChange('selectValue', e.target.value)} /></td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.selectDuplicatedValue} onChange={e => onChange('selectDuplicatedValue', e.target.value)} /></td>
                        <td>　所持率</td><td><input className="inp" type="number" step="10" min="0" max="100" value={gp.selectOwnRate} onChange={e => onChange('selectOwnRate', e.target.value)} />%</td>
                    </tr>
                </tbody>
            </table>
            <hr />
            {stat.selectedTable && <GachaTable desc={stat.selectedTable} />}
        </>
    )
}
