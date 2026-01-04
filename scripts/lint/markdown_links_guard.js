#!/usr/bin/env node
/**
 * Markdown link guard (local, filesystem-only)
 *
 * WHAT
 * - Scans all `docs/` markdown (excluding `docs/09-history/archive/`) and checks that relative links
 *   point to existing files/directories in the repo.
 *
 * WHY
 * - Docs cleanup often leaves broken relative links (especially case-only mismatches that fail on CI).
 * - This guard keeps public-facing docs navigable and accurate.
 *
 * HOW
 * - Parses Markdown in a lightweight way:
 *   - Ignores fenced code blocks
 *   - Extracts `(...)` targets from Markdown links/images
 *   - Ignores external URLs and pure anchors
 *   - Resolves paths relative to the document (or repo root for `/...` links)
 */

const fs = require("fs");
const path = require("path");

const repoRoot = process.cwd();
const docsRoot = path.join(repoRoot, "docs");
const archiveRoot = path.join(docsRoot, "09-history", "archive");

function isMarkdownFile(filePath) {
  return filePath.endsWith(".md");
}

function walkDir(dirPath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  const results = [];
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (fullPath.startsWith(archiveRoot + path.sep)) continue;
    if (entry.isDirectory()) results.push(...walkDir(fullPath));
    else if (entry.isFile() && isMarkdownFile(fullPath)) results.push(fullPath);
  }
  return results;
}

function stripFencedCodeBlocks(markdown) {
  const lines = markdown.split("\n");
  const out = [];
  let inFence = false;

  for (const line of lines) {
    const trimmed = line.trimStart();
    if (trimmed.startsWith("```")) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) out.push(line);
  }
  return out.join("\n");
}

function extractLinkTargets(markdown) {
  // Handles both links and images: [text](target) / ![alt](target)
  // Not a full markdown parser; deliberately conservative.
  const targets = [];
  const re = /!?\[[^\]]*\]\(([^)]+)\)/g;
  let match = null;
  while ((match = re.exec(markdown)) !== null) {
    targets.push({ raw: match[1], index: match.index });
  }
  return targets;
}

function isExternalLink(target) {
  return (
    target.startsWith("http://") ||
    target.startsWith("https://") ||
    target.startsWith("mailto:") ||
    target.startsWith("tel:") ||
    target.startsWith("javascript:")
  );
}

function resolveTargetPath(docPath, target) {
  const targetNoAnchor = target.split("#")[0].trim();
  if (targetNoAnchor.length === 0) return null;

  if (targetNoAnchor.startsWith("/")) {
    return path.resolve(repoRoot, targetNoAnchor.slice(1));
  }

  return path.resolve(path.dirname(docPath), targetNoAnchor);
}

function checkPathCase(absolutePath) {
  const resolved = path.resolve(absolutePath);
  if (!fs.existsSync(resolved)) return { exists: false, exact: false, corrected: resolved };

  const parsed = path.parse(resolved);
  const rest = resolved.slice(parsed.root.length);
  const parts = rest.split(path.sep).filter(Boolean);

  let current = parsed.root;
  const correctedParts = [];
  let exact = true;

  for (const part of parts) {
    let entries = [];
    try {
      entries = fs.readdirSync(current);
    } catch {
      // If we can't list entries (unexpected within a repo), fall back to trusting existsSync.
      correctedParts.push(part);
      current = path.join(current, part);
      continue;
    }

    if (entries.includes(part)) {
      correctedParts.push(part);
      current = path.join(current, part);
      continue;
    }

    const match = entries.find((entry) => entry.toLowerCase() === part.toLowerCase());
    if (match) {
      exact = false;
      correctedParts.push(match);
      current = path.join(current, match);
      continue;
    }

    // If existsSync said the path exists but we can't find a matching entry, keep going.
    correctedParts.push(part);
    current = path.join(current, part);
  }

  return {
    exists: true,
    exact,
    corrected: path.join(parsed.root, ...correctedParts),
  };
}

function checkTargetExists(resolvedPath) {
  const candidates = [
    resolvedPath,
    // Common convenience: allow linking to a directory's README implicitly
    resolvedPath + ".md",
    path.join(resolvedPath, "README.md"),
  ];

  for (const candidate of candidates) {
    const caseCheck = checkPathCase(candidate);
    if (!caseCheck.exists) continue;

    if (!caseCheck.exact) {
      return { exists: false, caseMismatch: true, corrected: caseCheck.corrected };
    }

    return { exists: true, caseMismatch: false, corrected: caseCheck.corrected };
  }

  return { exists: false, caseMismatch: false, corrected: resolvedPath };
}

function lineNumberAt(text, index) {
  // 1-based line number for error output
  let line = 1;
  for (let i = 0; i < index && i < text.length; i++) {
    if (text[i] === "\n") line++;
  }
  return line;
}

function main() {
 if (!fs.existsSync(docsRoot) || !fs.statSync(docsRoot).isDirectory()) {
    console.error("Docs directory not found:", docsRoot);
    process.exit(2);
  }

  const files = walkDir(docsRoot);
  // README.md is public-facing and should obey the same link hygiene as docs/.
  const rootReadme = path.join(repoRoot, "README.md");
  if (fs.existsSync(rootReadme) && fs.statSync(rootReadme).isFile()) {
    files.push(rootReadme);
  }
  const missing = [];

  for (const file of files) {
    const raw = fs.readFileSync(file, "utf8");
    const text = stripFencedCodeBlocks(raw);
    const targets = extractLinkTargets(text);

    for (const t of targets) {
      const target = t.raw.trim();
      if (target.length === 0) continue;
      if (target.startsWith("#")) continue; // in-page anchor
      if (isExternalLink(target)) continue;

      const resolved = resolveTargetPath(file, target);
      if (!resolved) continue;

      const check = checkTargetExists(resolved);
      if (!check.exists) {
        missing.push({
          file: path.relative(repoRoot, file),
          line: lineNumberAt(text, t.index),
          target,
          resolved: path.relative(repoRoot, resolved),
          caseMismatch: check.caseMismatch,
          corrected: check.caseMismatch ? path.relative(repoRoot, check.corrected) : null,
        });
      }
    }
  }

  if (missing.length > 0) {
    console.error(`Markdown link guard failed (${missing.length} broken link(s)):\n`);
    for (const m of missing) {
      const extra = m.caseMismatch && m.corrected ? ` (case mismatch; expected: ${m.corrected})` : "";
      console.error(`- ${m.file}:${m.line} -> ${m.target} (resolved: ${m.resolved})${extra}`);
    }
    process.exit(1);
  }

  console.log(`Docs link guard: OK (${files.length} files scanned)`);
}

main();
