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

// Decode the mappings
const mappings = sourceMap.mappings;
const lines = mappings.split(';');

console.log(`Total lines in mapping: ${lines.length}`);
console.log(`Total lines in generated file: ${generatedLines.length}\n`);

// Track current position
let sourceFileIndex = 0;
let sourceLine = 0;
let sourceColumn = 0;
let nameIndex = 0;

console.log('=== Decoded Mappings (first 10 non-empty) ===\n');

let nonEmptyCount = 0;
for (let genLine = 0; genLine < lines.length && nonEmptyCount < 10; genLine++) {
    const line = lines[genLine];
    if (line.length === 0) continue;
    
    const segments = line.split(',');
    for (const segment of segments) {
        if (segment.length === 0) continue;
        
        const decoded = decodeVLQ(segment);
        
        // VLQ fields are relative to previous position
        const genColumn = decoded[0] || 0;
        sourceFileIndex += decoded[1] || 0;
        sourceLine += decoded[2] || 0;
        sourceColumn += decoded[3] || 0;
        
        if (decoded.length > 4) {
            nameIndex += decoded[4];
        }
        
        console.log(`Generated Line ${genLine + 1}:`);
        console.log(`  Maps to: ${sourceMap.sources[sourceFileIndex] || 'unknown'}:${sourceLine + 1}:${sourceColumn + 1}`);
        console.log(`  Generated code: "${generatedLines[genLine]?.substring(0, 60)}..."`);
        console.log(`  Source code:    "${sourceLines[sourceLine]?.substring(0, 60)}..."`);
        console.log('');
        
        nonEmptyCount++;
        break; // Only show first segment of each line for clarity
    }
}

// Analyze the mapping pattern
console.log('=== Mapping Pattern Analysis ===\n');

let emptyLines = 0;
let mappedLines = 0;
for (const line of lines) {
    if (line.length === 0) {
        emptyLines++;
    } else {
        mappedLines++;
    }
}

console.log(`Empty lines: ${emptyLines}`);
console.log(`Mapped lines: ${mappedLines}`);
console.log(`Mapping coverage: ${((mappedLines / lines.length) * 100).toFixed(1)}%`);

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