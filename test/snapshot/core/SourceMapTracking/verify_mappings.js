#!/usr/bin/env node

/**
 * Verify source map mappings are correct
 * This script decodes the VLQ mappings and shows what they actually map to
 */

const fs = require('fs');
const path = require('path');

// Base64 VLQ decoder
const VLQ_BASE_SHIFT = 5;
const VLQ_BASE = 1 << VLQ_BASE_SHIFT;
const VLQ_BASE_MASK = VLQ_BASE - 1;
const VLQ_CONTINUATION_BIT = VLQ_BASE;

const BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const BASE64_MAP = {};
for (let i = 0; i < BASE64_CHARS.length; i++) {
    BASE64_MAP[BASE64_CHARS[i]] = i;
}

function decodeVLQ(string, start = 0) {
    const result = [];
    let shift = 0;
    let value = 0;
    
    for (let i = start; i < string.length; i++) {
        const digit = BASE64_MAP[string[i]];
        if (digit === undefined) {
            throw new Error(`Invalid base64 digit: ${string[i]}`);
        }
        
        value += (digit & VLQ_BASE_MASK) << shift;
        
        if (digit & VLQ_CONTINUATION_BIT) {
            shift += VLQ_BASE_SHIFT;
        } else {
            // Sign bit is least significant bit
            const shouldNegate = value & 1;
            value >>= 1;
            if (shouldNegate) {
                value = -value;
            }
            result.push(value);
            
            // Reset for next value
            value = 0;
            shift = 0;
        }
    }
    
    return result;
}

// Read the source map
const sourceMapPath = path.join(__dirname, 'out/main.ex.map');
const sourceMap = JSON.parse(fs.readFileSync(sourceMapPath, 'utf8'));

// Read the generated file to compare
const generatedPath = path.join(__dirname, 'out/main.ex');
const generatedLines = fs.readFileSync(generatedPath, 'utf8').split('\n');

// Read the source file
const sourcePath = path.join(__dirname, 'Main.hx');
const sourceLines = fs.readFileSync(sourcePath, 'utf8').split('\n');

console.log('=== Source Map Mapping Analysis ===\n');
console.log(`Source file: ${sourceMap.sources[0]}`);
console.log(`Generated file: ${sourceMap.file}`);
console.log(`Mappings string: ${sourceMap.mappings}\n`);

function decodeMappings(mappings, sources) {
    const lines = mappings.split(';');

    const decodedLines = [];

    // Delta state across the whole file (generated_column resets per line)
    let sourceFileIndex = 0;
    let sourceLine = 0;
    let sourceColumn = 0;

    for (let genLine = 0; genLine < lines.length; genLine++) {
        const line = lines[genLine];
        let generatedColumn = 0;
        const segments = line.split(',');
        const decodedSegments = [];

        for (const segment of segments) {
            if (!segment) continue;
            const decoded = decodeVLQ(segment);
            if (decoded.length === 0) continue;

            generatedColumn += decoded[0] || 0;

            if (decoded.length >= 4) {
                sourceFileIndex += decoded[1] || 0;
                sourceLine += decoded[2] || 0;
                sourceColumn += decoded[3] || 0;

                decodedSegments.push({
                    generated_line: genLine,
                    generated_column: generatedColumn,
                    source_file: sources[sourceFileIndex] || 'unknown.hx',
                    source_line: sourceLine,
                    source_column: sourceColumn,
                });
            }
        }

        decodedLines.push(decodedSegments);
    }

    return decodedLines;
}

// Decode the mappings
const mappings = sourceMap.mappings;
const lines = mappings.split(';');
const decodedLines = decodeMappings(mappings, sourceMap.sources);

console.log(`Total lines in mapping: ${lines.length}`);
console.log(`Total lines in generated file: ${generatedLines.length}\n`);

console.log('=== Decoded Mappings (first 10 non-empty) ===\n');

let nonEmptyCount = 0;
for (let genLine = 0; genLine < lines.length && nonEmptyCount < 10; genLine++) {
    const mappingsForLine = decodedLines[genLine] || [];
    if (mappingsForLine.length === 0) continue;

    const mapping = mappingsForLine[0];
    console.log(`Generated Line ${genLine + 1}:`);
    console.log(`  Maps to: ${mapping.source_file}:${mapping.source_line + 1}:${mapping.source_column + 1}`);
    console.log(`  Generated code: "${generatedLines[genLine]?.substring(0, 60)}..."`);
    console.log(`  Source code:    "${sourceLines[mapping.source_line]?.substring(0, 60)}..."`);
    console.log('');

    nonEmptyCount++;
}

// Analyze the mapping pattern
console.log('=== Mapping Pattern Analysis ===\n');

let emptyLines = 0;
let mappedLines = 0;
for (const lineMappings of decodedLines) {
    if (!lineMappings || lineMappings.length === 0) emptyLines++;
    else mappedLines++;
}

console.log(`Empty lines: ${emptyLines}`);
console.log(`Mapped lines: ${mappedLines}`);
const coverage = ((mappedLines / decodedLines.length) * 100);
console.log(`Mapping coverage: ${coverage.toFixed(1)}%`);

// === Assertions (fail the snapshot test if source maps regress) ===
//
// We want source maps to be a dependable debugging aid:
// - Every generated line should have at least one mapping (line coverage)
// - At least some lines should have multiple segments (column fidelity)
const hasColumnMappings = decodedLines.some(lineMappings =>
    (lineMappings || []).some(m => (m.generated_column || 0) > 0)
);
const hasMultiSegmentLine = decodedLines.some(lineMappings => (lineMappings || []).length >= 2);

if (coverage < 95) {
    console.error(`\n[ASSERT] Low mapping coverage: ${coverage.toFixed(1)}% (< 95%)`);
    process.exit(1);
}

if (!hasColumnMappings || !hasMultiSegmentLine) {
    console.error(`\n[ASSERT] Source map granularity too low (need column-level segments on at least one line).`);
    process.exit(1);
}

// Check if we're tracking the Main class correctly
const mainClassLine = sourceLines.findIndex(line => line.includes('class Main'));
const calculatorClassLine = sourceLines.findIndex(line => line.includes('class Calculator'));

console.log('\n=== Expected vs Actual Mappings ===\n');
console.log(`Main class defined at line ${mainClassLine + 1} in Main.hx`);
console.log(`Calculator class defined at line ${calculatorClassLine + 1} in Main.hx`);

// Check what the actual mapping points to
if (mappedLines > 0) {
    // Decode the first non-empty mapping to see where it points
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].length > 0) {
            const decoded = decodeVLQ(lines[i]);
            console.log(`\nFirst mapping at generated line ${i + 1}:`);
            console.log(`  Points to source line: ${(decoded[2] || 0) + 1}`);
            console.log(`  Expected: Should be near line ${mainClassLine + 1} for Main class`);
            break;
        }
    }
}
