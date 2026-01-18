import * as fs from 'node:fs'
import * as path from 'node:path'
import * as vscode from 'vscode'

type HxxComponentDef = {
  dotTag: string
  functionName: string
  moduleTypePath: string
  nativeModuleName: string | null
  props: Record<string, string>
  requiredProps: string[]
  slots: Record<
    string,
    {
      required: boolean
      props: Record<string, string>
      requiredProps: string[]
      letBinding: null | {
        props: Record<string, string>
        requiredProps: string[]
        typeName: string | null
      }
    }
  >
}

type LiveViewIndexEntry = {
  moduleTypePath: string
  nativeModuleName: string | null
  templateComponents?: string[]
  templateSlots?: string[]
  usedComponents?: Record<string, HxxComponentDef[]>
}

type HxxRegistryIndex = {
  schemaVersion: number
  components?: HxxComponentDef[]
  liveViews?: LiveViewIndexEntry[]
}

function readJsonFile<T>(filePath: string): T | null {
  try {
    const raw = fs.readFileSync(filePath, 'utf8')
    return JSON.parse(raw) as T
  } catch {
    return null
  }
}

function getIndexPath(): string {
  const configured = vscode.workspace.getConfiguration('hxx').get<string>('indexPath')
  if (configured && configured.length > 0) return configured

  const folder = vscode.workspace.workspaceFolders?.[0]
  return folder ? path.join(folder.uri.fsPath, 'tmp', 'hxx-registry.json') : 'tmp/hxx-registry.json'
}

function typePathForHaxeDocument(doc: vscode.TextDocument): string | null {
  const text = doc.getText()
  const pkgMatch = text.match(/^\s*package\s+([a-zA-Z0-9_.]+)\s*;/m)
  const pkg = pkgMatch ? pkgMatch[1] : null

  // Prefer the first `@:liveview class X` in the file; otherwise fall back to the first `class X`.
  const liveViewClassMatch = text.match(/@:liveview[\s\r\n]*class\s+([A-Za-z0-9_]+)/m)
  const classMatch = liveViewClassMatch ?? text.match(/^\s*class\s+([A-Za-z0-9_]+)/m)
  const name = classMatch ? classMatch[1] : null
  if (!name) return null
  return pkg && pkg.length > 0 ? `${pkg}.${name}` : name
}

function isInsideHxxString(doc: vscode.TextDocument, pos: vscode.Position): null | { stringStart: number; stringEnd: number } {
  // Best-effort: locate the nearest quote boundaries on the current line (or nearby lines if the string is multiline).
  // Then ensure there is an `HXX.hxx(` or `hxx(` between the start of the document and the cursor, and that the cursor
  // is within the first argument string.
  const full = doc.getText()
  const offset = doc.offsetAt(pos)

  // Scan backwards for opening quote.
  let quote: "'" | '"' | null = null
  let start = -1
  for (let i = offset; i >= 0; i--) {
    const ch = full[i]
    if (ch === "'" || ch === '"') {
      quote = ch as "'" | '"'
      start = i
      break
    }
  }
  if (!quote || start < 0) return null

  // Scan forward for closing quote.
  let end = -1
  for (let i = offset; i < full.length; i++) {
    const ch = full[i]
    if (ch === quote) {
      end = i
      break
    }
  }
  if (end < 0) return null
  if (!(start < offset && offset <= end)) return null

  const beforeStart = full.slice(0, start)
  const callIndexQualified = beforeStart.lastIndexOf('HXX.hxx(')
  const callIndexUnqualified = beforeStart.lastIndexOf('hxx(')
  const callIndex = Math.max(callIndexQualified, callIndexUnqualified)
  if (callIndex < 0) return null

  // Ensure the quote we found is inside the argument list for that call (not a previous string).
  const between = full.slice(callIndex, start)
  if (!(between.includes('HXX.hxx(') || between.includes('hxx('))) return null

  return { stringStart: start, stringEnd: end }
}

function isInsideStringOnLine(line: string, col: number): boolean {
  // Best-effort: count unescaped single/double quotes on the current line.
  // This avoids offering inline-markup completions inside arbitrary string literals.
  let inSingle = false
  let inDouble = false
  for (let i = 0; i < Math.min(col, line.length); i++) {
    const ch = line[i]
    if (ch === '\\\\') {
      i++
      continue
    }
    if (!inDouble && ch === "'") inSingle = !inSingle
    else if (!inSingle && ch === '"') inDouble = !inDouble
  }
  return inSingle || inDouble
}

function isLikelyInlineMarkupContext(doc: vscode.TextDocument, pos: vscode.Position): boolean {
  // Inline markup is source-level `<tag ...>` (not inside quotes). Use cheap heuristics:
  // - must be in a tag-name/attr context (so we know we're after a `<`)
  // - must not be inside a normal string literal on this line
  const line = doc.lineAt(pos.line).text
  if (isInsideStringOnLine(line, pos.character)) return false
  return true
}

function completionIsInTagNameContext(doc: vscode.TextDocument, pos: vscode.Position): null | { prefix: string; startCol: number } {
  const line = doc.lineAt(pos.line).text
  const col = pos.character
  const upto = line.slice(0, col)

  // Find the last `<` on the line and ensure we haven't hit `>` yet.
  const lt = upto.lastIndexOf('<')
  if (lt < 0) return null
  if (upto.slice(lt).includes('>')) return null

  const afterLt = upto.slice(lt + 1)
  const cleaned = afterLt.startsWith('/') ? afterLt.slice(1) : afterLt
  // Tag name is from `<` to first whitespace or `>` or `/`.
  const match = cleaned.match(/^([.:A-Za-z0-9_\\-]*)$/)
  if (!match) return null

  return { prefix: match[1], startCol: lt + 1 + (afterLt.startsWith('/') ? 1 : 0) }
}

function completionIsInAttrNameContext(doc: vscode.TextDocument, pos: vscode.Position): null | { tagName: string; prefix: string } {
  const line = doc.lineAt(pos.line).text
  const col = pos.character
  const upto = line.slice(0, col)
  const lt = upto.lastIndexOf('<')
  if (lt < 0) return null
  if (upto.slice(lt).includes('>')) return null

  const afterLt = upto.slice(lt + 1)
  const cleaned = afterLt.startsWith('/') ? afterLt.slice(1) : afterLt
  const parts = cleaned.split(/\s+/)
  if (parts.length < 2) return null
  const tagName = parts[0]
  const lastPart = parts[parts.length - 1]
  if (lastPart.includes('=')) return null

  return { tagName, prefix: lastPart }
}

function buildLiveViewScope(index: HxxRegistryIndex, moduleTypePath: string | null): LiveViewIndexEntry | null {
  if (!index.liveViews || !moduleTypePath) return null
  return index.liveViews.find((lv) => lv.moduleTypePath === moduleTypePath) ?? null
}

export function activate(context: vscode.ExtensionContext) {
  const indexPath = getIndexPath()
  let registry = readJsonFile<HxxRegistryIndex>(indexPath)

  const watcher = fs.existsSync(indexPath)
    ? vscode.workspace.createFileSystemWatcher(indexPath)
    : null

  const reload = () => {
    registry = readJsonFile<HxxRegistryIndex>(indexPath)
  }

  watcher?.onDidChange(reload)
  watcher?.onDidCreate(reload)
  watcher?.onDidDelete(() => {
    registry = null
  })

  const provider: vscode.CompletionItemProvider = {
    provideCompletionItems(document, position) {
      if (!registry) return
      const inHxxString = !!isInsideHxxString(document, position)

      const moduleTypePath = typePathForHaxeDocument(document)
      const scope = buildLiveViewScope(registry, moduleTypePath)

      const tagCtx = completionIsInTagNameContext(document, position)
      if (tagCtx) {
        if (!inHxxString && !isLikelyInlineMarkupContext(document, position)) return
        const items: vscode.CompletionItem[] = []
        const tags = new Set<string>()

        // Prefer scoped tags (what this template uses), fall back to global dot-components.
        if (scope?.templateComponents) scope.templateComponents.forEach((t) => tags.add(t))
        if (scope?.templateSlots) scope.templateSlots.forEach((s) => tags.add(`:${s}`))
        if (registry.components) registry.components.forEach((c) => tags.add(c.dotTag))

        for (const t of tags) {
          if (tagCtx.prefix && !t.startsWith(tagCtx.prefix)) continue
          const item = new vscode.CompletionItem(t, vscode.CompletionItemKind.Snippet)
          item.insertText = t
          items.push(item)
        }
        return items
      }

      const attrCtx = completionIsInAttrNameContext(document, position)
      if (attrCtx) {
        if (!inHxxString && !isLikelyInlineMarkupContext(document, position)) return
        const items: vscode.CompletionItem[] = []
        const { tagName, prefix } = attrCtx

        // Component props.
        if (scope?.usedComponents && scope.usedComponents[tagName] && scope.usedComponents[tagName].length > 0) {
          const def = scope.usedComponents[tagName][0]
          const propNames = Object.keys(def.props || {})
          for (const p of propNames) {
            if (prefix && !p.startsWith(prefix)) continue
            const item = new vscode.CompletionItem(p, vscode.CompletionItemKind.Property)
            item.detail = def.props[p]
            items.push(item)
          }
        }

        // Slot props: if we are in a `<:slot ...>` tag, suggest props from any component that declares that slot.
        if (tagName.startsWith(':') && scope?.usedComponents) {
          const slotName = tagName.slice(1)
          for (const usedTag of Object.keys(scope.usedComponents)) {
            const defs = scope.usedComponents[usedTag]
            if (!defs || defs.length === 0) continue
            const def = defs[0]
            const slotDef = def.slots?.[slotName]
            if (!slotDef) continue
            for (const p of Object.keys(slotDef.props || {})) {
              if (prefix && !p.startsWith(prefix)) continue
              const item = new vscode.CompletionItem(p, vscode.CompletionItemKind.Property)
              item.detail = slotDef.props[p]
              items.push(item)
            }
          }
        }

        return items.length > 0 ? items : undefined
      }

      return
    }
  }

  context.subscriptions.push(
    vscode.languages.registerCompletionItemProvider({ language: 'haxe', scheme: 'file' }, provider, '.', ':', '-', '_')
  )
}

export function deactivate() {}
