
window.h = createElement;

export function createElement(tag, props, ...children) {
    return {
        type: tag, props: { children: children, ...props }
    };
}

function indent(level) {
    return '  '.repeat(level);
}

export function _render(vnode, level) {
    if (typeof vnode === 'string') {
        return document.createTextNode(vnode);
    } else if (typeof vnode.type === 'function') {
        console.log(indent(level) + "apply", vnode.type.name, vnode.props)
        return _render(vnode.type(vnode.props), level + 1)
    } else {
        console.log(indent(level) + "node", vnode.type, vnode.props)
        const el = document.createElement(vnode.type);
        for (let name in vnode.props) {
            if (name === 'children') {
                continue;
            } else if (name.startsWith('on')) {
                console.log('event', name)
                el.addEventListener(name.replace('on', '').toLowerCase(), vnode.props[name]);
            } else {
                el.setAttribute(name, vnode.props[name]);
            }
        }
        vnode.props.children.map(child => {
            if (Array.isArray(child)) {
                for (let c of child) {
                    el.appendChild(_render(c, level + 1));
                }
            } else {
                el.appendChild(_render(child, level + 1));
            }
        });
        return el;
    }
}
export function render(vnode, container) {
    container.innerHTML = '';
    container.appendChild(_render(vnode, 0));
}