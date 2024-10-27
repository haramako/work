export function sum<T>(arr: T[], filter: (item: T) => number) {
    return arr.map(filter).reduce((a, b) => a + b)
}

export function parseSearch(location: Location) {
    const params = new URLSearchParams(location.search)
    const result: { [key: string]: number } = {}
    for (const [key, val] of params.entries()) {
        result[key] = parseFloat(val)
    }
    return result
}

export function unparseSearch(v: { [key: string]: number }) {
    return Object.entries(v).map(([k, v]) => `${k}=${v}`).join("&")
}

