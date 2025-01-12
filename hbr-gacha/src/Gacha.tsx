import { useRecoilState, useRecoilValue } from 'recoil'
import { defaultGachaParam, GachaParam, GachaStat, rootState, TableDesc } from './stat'
import { Bar, BarChart, CartesianGrid, Legend, Line, LineChart, Tooltip, XAxis, YAxis } from 'recharts'
import { copyToClipboard, sum, unparseSearch } from './util'
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
            <Line type="monotone" dataKey='value' stroke="#8884d8" name='その10連の価値' strokeDasharray="4 4" />
            <Line type="monotone" dataKey='draw50' stroke="#ffff00" name='50連' />
            <Line type="monotone" dataKey='draw200' stroke="#ff0000" name='200連' />
            <Line type="monotone" dataKey='draw200AfterPickup' stroke="#00ff00" name='200連(PU1取得後)' />
            <Line type="monotone" dataKey='draw200AfterPickup2' stroke="#00ffff" name='200連(PU2取得後)' />
        </LineChart>
        <div>
            ※このグラフは、200連もしくは50連を「最後まで引く前提」の期待値の変化を表しています。<br />
            あくまで「最後まで引く前提」なので、途中でやめる場合にはこれより低い期待値になりますし、引き始めるかどうかは「一番左の10連の時の値」が重要になります。<br />
            <br />
            このグラフからは、ピックアップを引いたときに続行すべきかどうかを読み取ります。<br />
            例えば、ピックアップの１枚目を引いたら、その時点で赤の線から緑の線に期待値が変わります。<br />
            ２枚目なら、緑の線から水色の線に代わります。<br />
            現在のガチャ連数の一つ下の線（赤→緑→水色）の期待値が一定以上であれば、続行したほうがよいという目安になります。
        </div>
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
            name: '★PUステップ',
            value: totalValu(resultStepup),
            campaign: campaignStepup,
            limit: 4,
        },
        {
            name: '★セレチケ',
            value: totalValu(resultSelect),
            campaign: campaignSelect,
            limit: 1,
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
        <BarChart width={720} height={300} data={data} onClick={e => e.activeLabel && onClickChart(e.activeLabel)}>
            <XAxis dataKey="name" />
            <YAxis domain={[0, 300]} />
            <CartesianGrid strokeDasharray="3 3" vertical={false} />
            <Legend />
            <Tooltip />
            <Bar dataKey="value" fill="#da4" name='3000クォーツあたりの価値' />
        </BarChart>
    </>
}

const PickupNames = ['PU200連', 'PU50連', 'PU10連']

const PickupGachaDesc = "ピックアップの出現率は0.75%ずつで合計で1.5%。その他のSSが1.5%。価値パラメーターは、ピックアップ、ピックアップ（２つめ）の値が使われます。ピックアップは、新スタイルを想定しているので所持済みのものはない想定になります。"
const PickupOneGachaDesc = "ピックアップの出現率は1.0%。その他のSSが2.0%。価値パラメーターは、ピックアップの値が使われます。"
const ZokuseiGachaDesc = "属性PUの出現率は合計1.5%。その他のSSが1.5%。価値パラメーターは、属性PUの値が使われます。属性PUの所持率の確率でかぶりとなります。"

const GachaDescs: { [_: string]: string } = {
    'PU200連': "２つのSSスタイルのピックアップを200連で引いたとき。天井は選択式。" + PickupGachaDesc,
    'PU50連': "２つのSSスタイルのピックアップを50連まで引いたとき。" + PickupGachaDesc,
    'PU10連': "２つのSSスタイルのピックアップを10連だけ引いたとき。" + PickupGachaDesc,
    'PU(1SS)': "１つのSSスタイルのピックアップを200連で引いたとき。天井は選択式。" + PickupOneGachaDesc,
    '★PUステップ': "２つのSSスタイルがピックアップされた、有料ステップガチャをステップ４まで31連で引いたとき。最後の一回は、ピックアップの出現率は5%ずつで,その他のSSが90%。それ以外は、ピックアップ200連と同様です。",
    '★セレチケ': "選択できる有料のセレクトチケットを10連で引いたとき。SSはセレクトのみが排出され、出現率は3%で、10連目のみ100%。価値パラメーターは、セレクトの値が使われます。セレクトの所持率の確率でかぶりとなります。",
    '★属性ステップ': "複数のSSスタイルがピックアップされた、有料ステップガチャをステップ４まで31連で引いたとき。" + ZokuseiGachaDesc,
}

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
        <p>説明: {GachaDescs[desc.label]}</p>
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

    // locationに現在の設定を反映する
    /*
    useEffect(() => {
        history.replaceState({}, "", "/?" + unparseSearch(gp))
    }, [gp])
    */

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

    function onClickCopyURL() {
        const loc = window.location
        copyToClipboard(loc.protocol + "://" + loc.host + loc.pathname + "?" + unparseSearch(gp))
        alert("URLをクリップボードにコピーしました")
    }

    return (
        <>
            <h2>ガチャ期待値</h2>
            <GachaBar />
            {/*
            stat.gacha.map(s => <GachaStatView key={s.key} stat={s} onChange={onChangeStat(s.key)} />)
            <button onClick={onClickAddButton}>追加</button>
            */}
            <hr />
            <h2>設定</h2>
            <div>
                プリセット:
                <button className="btn-inline" onClick={() => onClickPreset(0)}>初心者</button>
                <button className="btn-inline" onClick={() => onClickPreset(1)}>中級者</button>
                <button className="btn-inline" onClick={() => onClickPreset(2)}>上級者</button>
                <button className="btn-inline" onClick={() => onClickPreset(3)}>超上級者</button>
            </div>
            <br />
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
                        {/*<td>　完凸率</td><td><input className="inp" type="number" step="10" min="0" max="100" value={gp.ssMaxRate} onChange={e => onChange('ssMaxRate', e.target.value)} />%</td> */}
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
            <br />
            <div><button onClick={onClickCopyURL}>共有用のURLをコピー</button></div>
            <hr />
            {stat.selectedTable && <GachaTable desc={stat.selectedTable} />}
            <div style={{ marginBottom: "80px" }} />
        </>
    )
}
