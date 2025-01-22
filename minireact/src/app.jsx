
export function List({ children }) {
    return (
        <ul>
            <li>item 1</li>
            {children.map(c => <li>{c}</li>)}
        </ul>
    )
}

export function Btn({ onclick, children }) {
    return <button onclick={onclick}>{children}</button>

}

function onclick() {
    console.log('clicked')
}

export function App() {
    return <div>
        <h11>App</h11>
        <List >
            <Btn onclick={onclick}>hoge</Btn>
            <Btn onclick={onclick}>fuga</Btn>
        </List>
    </div >
}
