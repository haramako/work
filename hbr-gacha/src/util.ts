export function sum<T>(arr: T[], filter: (item: T) => number) {
    return arr.map(filter).reduce((a, b) => a + b)
}

