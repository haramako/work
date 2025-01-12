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

// See: https://stackoverflow.com/questions/51805395/navigator-clipboard-is-undefined
export async function copyToClipboard(textToCopy: string) {
    // Navigator clipboard api needs a secure context (https)
    if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(textToCopy);
    } else {
        // Use the 'out of viewport hidden text area' trick
        const textArea = document.createElement("textarea");
        textArea.value = textToCopy;

        // Move textarea out of the viewport so it's not visible
        textArea.style.position = "absolute";
        textArea.style.left = "-999999px";

        document.body.prepend(textArea);
        textArea.select();

        try {
            document.execCommand('copy');
        } catch (error) {
            console.error(error);
        } finally {
            textArea.remove();
        }
    }
}