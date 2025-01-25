import { render } from './minireact'

export function List({ children, name }) {
    return (
        <ul>
            <li>{name}</li>
            {children.map(c => <li>{c}</li>)}
        </ul>
    )
}

export function Btn({ onclick, children }) {
    return <button onclick={onclick}>{children}</button>

}

var count = 1;

function onclick() {
    count += 1;
    console.log('clicked')
    renderApp();
}

export function App() {
    return <div>
        <h1>App</h1>
        <div>{count}</div>
        <List name="Button List">
            <Btn onclick={onclick}>hoge</Btn>
            <Btn onclick={onclick}>fuga</Btn>
        </List>
    </div >
}

export function renderApp() {
    render(<App count={count} />, document.querySelector('#app'))
}