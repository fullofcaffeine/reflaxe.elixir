#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const { zipSync } = require('fflate')

// ZIP stores a timezone-free DOS date. Use the same local wall-clock value in every TZ.
const FIXED_MTIME = new Date(2000, 0, 1, 0, 0, 0)
const FILE_ATTRIBUTES = 0o644 << 16

function compareEntryNames(left, right) {
  return Buffer.compare(Buffer.from(left, 'utf8'), Buffer.from(right, 'utf8'))
}

function validateEntryNames(names) {
  const seen = new Set()
  for (const name of names) {
    if (
      typeof name !== 'string' ||
      name.length === 0 ||
      name.includes('\0') ||
      name.includes('\\') ||
      name.startsWith('/') ||
      /^[A-Za-z]:/.test(name) ||
      name.endsWith('/') ||
      path.posix.normalize(name) !== name ||
      name
        .split('/')
        .some(
          (segment) => segment === '' || segment === '.' || segment === '..'
        )
    ) {
      throw new Error(`unsafe archive entry: ${String(name)}`)
    }
    if (seen.has(name)) throw new Error(`duplicate archive entry: ${name}`)
    seen.add(name)
  }
  return [...names]
}

function collectFiles(root) {
  const files = []

  function visit(directory, segments) {
    const entries = fs
      .readdirSync(directory, { withFileTypes: true })
      .sort((left, right) => compareEntryNames(left.name, right.name))
    for (const entry of entries) {
      const absolute = path.join(directory, entry.name)
      const next = [...segments, entry.name]
      const stat = fs.lstatSync(absolute)
      if (stat.isSymbolicLink()) {
        throw new Error(
          `symbolic link is not allowed in release archive: ${next.join('/')}`
        )
      }
      if (stat.isDirectory()) {
        visit(absolute, next)
      } else if (stat.isFile()) {
        files.push({ absolute, name: next.join('/') })
      } else {
        throw new Error(
          `special file is not allowed in release archive: ${next.join('/')}`
        )
      }
    }
  }

  visit(root, [])
  files.sort((left, right) => compareEntryNames(left.name, right.name))
  validateEntryNames(files.map(({ name }) => name))
  return files
}

/** Encode named file bytes using the release archive's one canonical ZIP representation. */
function createDeterministicZipBytes(files) {
  const names = Object.keys(files).sort(compareEntryNames)
  validateEntryNames(names)
  const entries = Object.create(null)
  for (const name of names) {
    Object.defineProperty(entries, name, {
      enumerable: true,
      value: [
        files[name],
        { level: 9, mtime: FIXED_MTIME, os: 3, attrs: FILE_ATTRIBUTES },
      ],
    })
  }
  return Buffer.from(
    zipSync(entries, {
      level: 9,
      mtime: FIXED_MTIME,
      os: 3,
      attrs: FILE_ATTRIBUTES,
    })
  )
}

/** Create a canonical ZIP independent of filesystem order, timestamps, modes, locale, and TZ. */
function createDeterministicZip(sourceDirectory, outputPath) {
  const root = path.resolve(sourceDirectory)
  if (!fs.statSync(root).isDirectory())
    throw new Error(`ZIP source is not a directory: ${sourceDirectory}`)

  const files = Object.create(null)
  for (const file of collectFiles(root)) {
    Object.defineProperty(files, file.name, {
      enumerable: true,
      value: fs.readFileSync(file.absolute),
    })
  }

  const output = path.resolve(outputPath)
  fs.mkdirSync(path.dirname(output), { recursive: true })
  fs.writeFileSync(output, createDeterministicZipBytes(files))
  return output
}

if (require.main === module) {
  try {
    const [source, output, ...rest] = process.argv.slice(2)
    if (!source || !output || rest.length > 0) {
      throw new Error(
        'usage: deterministic-zip.js <source-directory> <output.zip>'
      )
    }
    createDeterministicZip(source, output)
    console.log(`[deterministic-zip] wrote ${output}`)
  } catch (error) {
    console.error(`[deterministic-zip] ERROR: ${error.message}`)
    process.exit(1)
  }
}

module.exports = {
  collectFiles,
  compareEntryNames,
  createDeterministicZip,
  createDeterministicZipBytes,
  validateEntryNames,
}
