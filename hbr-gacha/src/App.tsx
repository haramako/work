import { RecoilRoot } from 'recoil'

import './App.css'

import { GachaList } from './Gacha'

function App() {
  return (
    <>
      <RecoilRoot>
        <h1>ヘブバン ガチャ期待値計算</h1>
        <div className="card">
          <GachaList />
        </div>
      </RecoilRoot>
    </>
  )
}

export default App
