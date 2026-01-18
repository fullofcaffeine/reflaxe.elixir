"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const fs = __importStar(require("node:fs"));
const path = __importStar(require("node:path"));
const vscode = __importStar(require("vscode"));
function readJsonFile(filePath) {
    try {
        const raw = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(raw);
    }
    catch {
        return null;
    }
}
function getIndexPath() {
    const configured = vscode.workspace.getConfiguration('hxx').get('indexPath');
    if (configured && configured.length > 0)
        return configured;
    const folder = vscode.workspace.workspaceFolders?.[0];
    return folder ? path.join(folder.uri.fsPath, 'tmp', 'hxx-registry.json') : 'tmp/hxx-registry.json';
}
function typePathForHaxeDocument(doc) {
    const text = doc.getText();
    const pkgMatch = text.match(/^\s*package\s+([a-zA-Z0-9_.]+)\s*;/m);
    const pkg = pkgMatch ? pkgMatch[1] : null;
    // Prefer the first `@:liveview class X` in the file; otherwise fall back to the first `class X`.
    const liveViewClassMatch = text.match(/@:liveview[\s\r\n]*class\s+([A-Za-z0-9_]+)/m);
    const classMatch = liveViewClassMatch ?? text.match(/^\s*class\s+([A-Za-z0-9_]+)/m);
    const name = classMatch ? classMatch[1] : null;
    if (!name)
        return null;
    return pkg && pkg.length > 0 ? `${pkg}.${name}` : name;
}
function isInsideHxxString(doc, pos) {
    // Best-effort: locate the nearest quote boundaries on the current line (or nearby lines if the string is multiline).
    // Then ensure there is an `HXX.hxx(` between the start of the document and the cursor, and that the cursor is
    // within the first argument string.
    const full = doc.getText();
    const offset = doc.offsetAt(pos);
    // Scan backwards for opening quote.
    let quote = null;
    let start = -1;
    for (let i = offset; i >= 0; i--) {
        const ch = full[i];
        if (ch === "'" || ch === '"') {
            quote = ch;
            start = i;
            break;
        }
    }
    if (!quote || start < 0)
        return null;
    // Scan forward for closing quote.
    let end = -1;
    for (let i = offset; i < full.length; i++) {
        const ch = full[i];
        if (ch === quote) {
            end = i;
            break;
        }
    }
    if (end < 0)
        return null;
    if (!(start < offset && offset <= end))
        return null;
    const beforeStart = full.slice(0, start);
    const callIndex = beforeStart.lastIndexOf('HXX.hxx(');
    if (callIndex < 0)
        return null;
    // Ensure the quote we found is inside the argument list for that call (not a previous string).
    const between = full.slice(callIndex, start);
    if (!between.includes('HXX.hxx('))
        return null;
    return { stringStart: start, stringEnd: end };
}
function completionIsInTagNameContext(doc, pos) {
    const line = doc.lineAt(pos.line).text;
    const col = pos.character;
    const upto = line.slice(0, col);
    // Find the last `<` on the line and ensure we haven't hit `>` yet.
    const lt = upto.lastIndexOf('<');
    if (lt < 0)
        return null;
    if (upto.slice(lt).includes('>'))
        return null;
    const afterLt = upto.slice(lt + 1);
    const cleaned = afterLt.startsWith('/') ? afterLt.slice(1) : afterLt;
    // Tag name is from `<` to first whitespace or `>` or `/`.
    const match = cleaned.match(/^([.:A-Za-z0-9_\\-]*)$/);
    if (!match)
        return null;
    return { prefix: match[1], startCol: lt + 1 + (afterLt.startsWith('/') ? 1 : 0) };
}
function completionIsInAttrNameContext(doc, pos) {
    const line = doc.lineAt(pos.line).text;
    const col = pos.character;
    const upto = line.slice(0, col);
    const lt = upto.lastIndexOf('<');
    if (lt < 0)
        return null;
    if (upto.slice(lt).includes('>'))
        return null;
    const afterLt = upto.slice(lt + 1);
    const cleaned = afterLt.startsWith('/') ? afterLt.slice(1) : afterLt;
    const parts = cleaned.split(/\s+/);
    if (parts.length < 2)
        return null;
    const tagName = parts[0];
    const lastPart = parts[parts.length - 1];
    if (lastPart.includes('='))
        return null;
    return { tagName, prefix: lastPart };
}
function buildLiveViewScope(index, moduleTypePath) {
    if (!index.liveViews || !moduleTypePath)
        return null;
    return index.liveViews.find((lv) => lv.moduleTypePath === moduleTypePath) ?? null;
}
function activate(context) {
    const indexPath = getIndexPath();
    let registry = readJsonFile(indexPath);
    const watcher = fs.existsSync(indexPath)
        ? vscode.workspace.createFileSystemWatcher(indexPath)
        : null;
    const reload = () => {
        registry = readJsonFile(indexPath);
    };
    watcher?.onDidChange(reload);
    watcher?.onDidCreate(reload);
    watcher?.onDidDelete(() => {
        registry = null;
    });
    const provider = {
        provideCompletionItems(document, position) {
            if (!registry)
                return;
            if (!isInsideHxxString(document, position))
                return;
            const moduleTypePath = typePathForHaxeDocument(document);
            const scope = buildLiveViewScope(registry, moduleTypePath);
            const tagCtx = completionIsInTagNameContext(document, position);
            if (tagCtx) {
                const items = [];
                const tags = new Set();
                // Prefer scoped tags (what this template uses), fall back to global dot-components.
                if (scope?.templateComponents)
                    scope.templateComponents.forEach((t) => tags.add(t));
                if (scope?.templateSlots)
                    scope.templateSlots.forEach((s) => tags.add(`:${s}`));
                if (registry.components)
                    registry.components.forEach((c) => tags.add(c.dotTag));
                for (const t of tags) {
                    if (tagCtx.prefix && !t.startsWith(tagCtx.prefix))
                        continue;
                    const item = new vscode.CompletionItem(t, vscode.CompletionItemKind.Snippet);
                    item.insertText = t;
                    items.push(item);
                }
                return items;
            }
            const attrCtx = completionIsInAttrNameContext(document, position);
            if (attrCtx) {
                const items = [];
                const { tagName, prefix } = attrCtx;
                // Component props.
                if (scope?.usedComponents && scope.usedComponents[tagName] && scope.usedComponents[tagName].length > 0) {
                    const def = scope.usedComponents[tagName][0];
                    const propNames = Object.keys(def.props || {});
                    for (const p of propNames) {
                        if (prefix && !p.startsWith(prefix))
                            continue;
                        const item = new vscode.CompletionItem(p, vscode.CompletionItemKind.Property);
                        item.detail = def.props[p];
                        items.push(item);
                    }
                }
                // Slot props: if we are in a `<:slot ...>` tag, suggest props from any component that declares that slot.
                if (tagName.startsWith(':') && scope?.usedComponents) {
                    const slotName = tagName.slice(1);
                    for (const usedTag of Object.keys(scope.usedComponents)) {
                        const defs = scope.usedComponents[usedTag];
                        if (!defs || defs.length === 0)
                            continue;
                        const def = defs[0];
                        const slotDef = def.slots?.[slotName];
                        if (!slotDef)
                            continue;
                        for (const p of Object.keys(slotDef.props || {})) {
                            if (prefix && !p.startsWith(prefix))
                                continue;
                            const item = new vscode.CompletionItem(p, vscode.CompletionItemKind.Property);
                            item.detail = slotDef.props[p];
                            items.push(item);
                        }
                    }
                }
                return items.length > 0 ? items : undefined;
            }
            return;
        }
    };
    context.subscriptions.push(vscode.languages.registerCompletionItemProvider({ language: 'haxe', scheme: 'file' }, provider, '.', ':', '-', '_'));
}
function deactivate() { }
