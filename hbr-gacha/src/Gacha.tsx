import { useRecoilState, useRecoilValue } from 'recoil'
import { defaultGachaParam, GachaParam, GachaStat, rootState, TableDesc } from './stat'
import { Bar, BarChart, CartesianGrid, Legend, Line, LineChart, Tooltip, XAxis, YAxis } from 'recharts'
import { sum } from './util'
import { makePickup200, makeSelect, makeStepup } from './Campaigns'

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

function GachaChart() {
    const stat = useRecoilValue(rootState)
    const gp = stat.gachaParam
    const campaign = makePickup200(gp, false)
    const owns = new Map<string, number>([['SS', gp.ssOwnRate / 100]])
    const result200 = campaign.drawWhile(20, owns)
    const result50 = campaign.drawWhile(5, owns)
    const resultAfterPickup = campaign.drawWhile(20, new Map<string, number>([...owns, ['Pickup', 1.0]]))
    const resultAfterPickup2 = campaign.drawWhile(20, new Map<string, number>([...owns, ['Pickup', 1.0], ['Pickup2', 1.0]]))

    function restValue(result: number[][], i: number) {
        if (i >= result.length) {
            return undefined
        } else {
            return sum(result.slice(i, result.length), n => n[1]) / (result.length - i)
        }
    }
    const data = result200.map((r, i) => ({
        cost: ((i + 1) * 10),
        value: r[1],
        draw200: restValue(result200, i),
        draw50: restValue(result50, i),
        draw200AfterPickup: restValue(resultAfterPickup, i),
        draw200AfterPickup2: restValue(resultAfterPickup2, i),
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
            <Line type="monotone" dataKey='draw200AfterPickup' stroke="#00ff00" name='200連(PU1取得後)' />
            <Line type="monotone" dataKey='draw200AfterPickup2' stroke="#00ffff" name='200連(PU2取得後)' />
        </LineChart>
    </>
}

function GachaBar() {
    const [stat, setStat] = useRecoilState(rootState)
    const gp = stat.gachaParam

    const campaign = makePickup200(gp, false)
    const campaignPickupOne = makePickup200(gp, true)
    const campaignSelect = makeSelect(gp)
    const campaignStepup = makeStepup(gp, false)
    const campaignStepupOne = makeStepup(gp, true)

    const owns = new Map<string, number>([['SS', gp.ssOwnRate / 100], ['Zokusei', gp.zokuseiOwnRate / 100], ['Select', gp.selectOwnRate / 100]])
    const result = campaign.drawWhile(20, owns)
    const result10 = campaign.drawWhile(1, owns)
    const result50 = campaign.drawWhile(5, owns)
    const resultPickupOne = campaignPickupOne.drawWhile(20, owns)
    //const resultAfterPickup = campaign.drawWhile(20, new Map<string, number>([...owns, ['Pickup', 0.5]]))
    const resultSelect = campaignSelect.drawWhile(1, owns)
    const resultStepup = campaignStepup.drawWhile(4, owns)
    const resultStepupOne = campaignStepupOne.drawWhile(4, owns)

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
            name: 'PU(1SS)',
            value: totalValu(resultPickupOne),
            campaign: campaignPickupOne,
            limit: 20,
        },
        {
            name: '★セレチケ10',
            value: totalValu(resultSelect),
            campaign: campaignSelect,
            limit: 1,
        },
        {
            name: '★ステップ',
            value: totalValu(resultStepup),
            campaign: campaignStepup,
            limit: 4,
        },
        {
            name: '★属性ステップ',
            value: totalValu(resultStepupOne),
            campaign: campaignStepupOne,
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
        <BarChart width={800} height={300} data={data} onClick={e => e.activeLabel && onClickChart(e.activeLabel)}>
            <XAxis dataKey="name" />
            <YAxis domain={[0, 300]} />
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
    'Pickup2': 'ピックアップ(2)',
    'Select': 'セレクト',
    'Zokusei': '属性ピックアップ',
    'NonSS': 'SS以外',
    'Piece': '万能SSピース'
}

function GachaTable({ desc }: { desc: TableDesc }) {
    return (<>
        <h2>ガチャ詳細</h2>
        <p>対象： {desc.label}</p>
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

    const newbeeParam: Partial<GachaParam> = {
        ssOwnRate: 10,
        selectOwnRate: 10,
        zokuseiOwnRate: 10,
    }

    const veteranParam: Partial<GachaParam> = {
        ssOwnRate: 70,
        selectOwnRate: 70,
        zokuseiOwnRate: 70,
    }

    const godParam: Partial<GachaParam> = {
        ssOwnRate: 95,
        selectOwnRate: 90,
        zokuseiOwnRate: 90,
    }

    function onClickPreset(n: number) {
        let gachaParam: GachaParam
        switch (n) {
            case 0:
                gachaParam = { ...defaultGachaParam, ...newbeeParam }
                break;
            default:
            case 1:
                gachaParam = { ...defaultGachaParam }
                break;
            case 2:
                gachaParam = { ...defaultGachaParam, ...veteranParam }
                break;
            case 3:
                gachaParam = { ...defaultGachaParam, ...godParam }
                break;
        }
        setStat({ ...stat, gachaParam: gachaParam })
    }

    return (
        <>
            <div>
                プリセット:
                <button className="btn-inline" onClick={() => onClickPreset(0)}>初心者</button>
                <button className="btn-inline" onClick={() => onClickPreset(1)}>中級者</button>
                <button className="btn-inline" onClick={() => onClickPreset(2)}>上級者</button>
                <button className="btn-inline" onClick={() => onClickPreset(3)}>超上級者</button>
            </div>
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
                        <td>ピックアップ(2つめ)</td>
                        {/*<td>確率</td><td><input type="number" step="1" min="0" max="100" value={gp.pickupProb} onChange={e => onChange('pickupProb', e.target.value)} /></td>*/}
                        <td><input className="inp" type="number" step="10" min="0" value={gp.pickup2Value} onChange={e => onChange('pickup2Value', e.target.value)} /></td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.pickup2DuplicatedValue} onChange={e => onChange('pickup2DuplicatedValue', e.target.value)} /></td>
                    </tr>
                    <tr>
                        <td>セレクト</td>
                        {/*<td>確率</td><td><input type="number" step="1" min="0" max="100" value={gp.pickupProb} onChange={e => onChange('pickupProb', e.target.value)} /></td>*/}
                        <td><input className="inp" type="number" step="10" min="0" value={gp.selectValue} onChange={e => onChange('selectValue', e.target.value)} /></td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.selectDuplicatedValue} onChange={e => onChange('selectDuplicatedValue', e.target.value)} /></td>
                        <td>　所持率</td><td><input className="inp" type="number" step="10" min="0" max="100" value={gp.selectOwnRate} onChange={e => onChange('selectOwnRate', e.target.value)} />%</td>
                    </tr>
                    <tr>
                        <td>属性PU</td>
                        {/*<td>確率</td><td><input type="number" step="1" min="0" max="100" value={gp.pickupProb} onChange={e => onChange('pickupProb', e.target.value)} /></td>*/}
                        <td><input className="inp" type="number" step="10" min="0" value={gp.zokuseiValue} onChange={e => onChange('zokuseiValue', e.target.value)} /></td>
                        <td><input className="inp" type="number" step="10" min="0" value={gp.zokuseiDuplicatedValue} onChange={e => onChange('zokuseiDuplicatedValue', e.target.value)} /></td>
                        <td>　所持率</td><td><input className="inp" type="number" step="10" min="0" max="100" value={gp.zokuseiOwnRate} onChange={e => onChange('zokuseiOwnRate', e.target.value)} />%</td>
                    </tr>
                </tbody>
            </table>
            <hr />
            {stat.selectedTable && <GachaTable desc={stat.selectedTable} />}
        </>
    )
}
