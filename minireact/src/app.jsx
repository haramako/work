import { Didact } from './minireact'

export function List({ children, name }) {
    return (
        <ul>
            <li>{name}</li>
            {children.map(c => <li>{c}</li>)}
        </ul>
    )
}

export function Btn({ onclick, children }) {
    return <button onclick={onclick}>{...children}</button>

}

export function App() {
    const [count, setCount] = Didact.useState(2)

    return <div>
        <h1>App</h1>
        <div>{count}</div>
        <Btn onclick={() => setCount((c) => c + 1)}>hoge</Btn>
    </div >
}

export function renderApp() {
    Didact.render(<App />, document.querySelector('#app'))
}