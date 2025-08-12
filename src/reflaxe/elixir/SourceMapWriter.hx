// =======================================================
// * SourceMapWriter
// 
// Elixir source mapping implementation adapted from Haxe's
// source mapping system for generating .ex.map files.
// =======================================================

package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr.Position;
import sys.io.File;
import haxe.Json;

using StringTools;
using reflaxe.helpers.PositionHelper;

/**
 * Source Map v3 specification implementation for Elixir target.
 * Generates .ex.map files that map generated Elixir code back to Haxe source.
 * 
 * Follows Source Map v3 specification:
 * https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k
 */
class SourceMapWriter {
    
    // Base64 VLQ characters for source map encoding
    private static var VLQ_CHARS = [
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
        'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
        'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
        'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
    ];
    
    // Generated Elixir file this source map describes
    private var generatedFile: String;
    
    // Output buffer for VLQ mappings
    private var mappingsBuffer: StringBuf;
    
    // Source Haxe files referenced by this source map
    private var sources: Array<String>;
    
    // Map of source file paths to their indexes in sources array
    private var sourceIndexes: Map<String, Int>;
    
    // Position tracking for delta encoding
    private var lastSourceIndex: Int = 0;
    private var lastSourceLine: Int = 0;
    private var lastSourceColumn: Int = 0;
    private var lastGeneratedColumn: Int = 0;
    
    // Current position in generated file
    private var currentGeneratedColumn: Int = 0;
    
    // Whether to print comma before next mapping
    private var printComma: Bool = false;
    
    // Last position that was mapped (for debugging)
    private var lastMappedPos: Null<Position> = null;
    
    /**
     * Create a new source map writer for the specified generated file
     * @param generatedFile Path to the generated .ex file
     */
    public function new(generatedFile: String) {
        this.generatedFile = generatedFile;
        this.mappingsBuffer = new StringBuf();
        this.sources = [];
        this.sourceIndexes = new Map<String, Int>();
    }
    
    /**
     * Map a Haxe position to the current location in generated output.
     * Call this method right before writing Haxe code to the generated file.
     * 
     * @param pos Haxe Position to map
     */
    public function mapPosition(pos: Position): Void {
        if (pos == null) return;
        
        lastMappedPos = pos;
        
        var sourceFile = pos.getFile();
        var sourceIndex = getOrCreateSourceIndex(sourceFile);
        var sourceLine = pos.line() - 1; // Convert to 0-based
        var sourceColumn = pos.column();
        
        // Add comma separator if not the first mapping
        if (printComma) {
            mappingsBuffer.add(',');
        } else {
            printComma = true;
        }
        
        // Write VLQ deltas according to Source Map v3 specification:
        // [generated_column_delta, source_index_delta, source_line_delta, source_column_delta]
        
        // Generated column delta (always relative to last position on this line)
        writeVLQ(currentGeneratedColumn - lastGeneratedColumn);
        
        // Source file index delta
        writeVLQ(sourceIndex - lastSourceIndex);
        
        // Source line delta
        writeVLQ(sourceLine - lastSourceLine);
        
        // Source column delta  
        writeVLQ(sourceColumn - lastSourceColumn);
        
        // Update tracking variables
        lastSourceIndex = sourceIndex;
        lastSourceLine = sourceLine;
        lastSourceColumn = sourceColumn;
        lastGeneratedColumn = currentGeneratedColumn;
    }
    
    /**
     * Notify the source map that a string was written to the generated file.
     * This updates the current column position for accurate mapping.
     * 
     * @param str String that was written to generated file
     */
    public function stringWritten(str: String): Void {
        var length = str.length;
        var lastNewlineIndex = str.lastIndexOf('\n');
        
        if (lastNewlineIndex >= 0) {
            // String contains newlines - update line/column tracking
            printComma = false;
            currentGeneratedColumn = length - lastNewlineIndex - 1;
            lastGeneratedColumn = 0;
            
            // Add semicolons for each new line in mappings
            var newlineCount = str.split('\n').length - 1;
            for (i in 0...newlineCount) {
                mappingsBuffer.add(';');
            }
        } else {
            // No newlines - just update column position
            currentGeneratedColumn += length;
        }
    }
    
    /**
     * Generate the complete source map JSON and save to .ex.map file.
     * Call this after all code generation is complete.
     * 
     * @return Path to the generated source map file
     */
    public function generateSourceMap(): String {
        var sourceMapPath = generatedFile + '.map';
        
        // Ensure output directory exists
        var dir = haxe.io.Path.directory(sourceMapPath);
        if (dir != "" && !sys.FileSystem.exists(dir)) {
            sys.FileSystem.createDirectory(dir);
        }
        
        var sourceMap = {
            version: 3,
            file: extractFileName(generatedFile),
            sourceRoot: "",
            sources: sources,
            names: [], // Not used for basic mapping
            mappings: mappingsBuffer.toString()
        };
        
        var sourceMapJson = Json.stringify(sourceMap, null, "  ");
        File.saveContent(sourceMapPath, sourceMapJson);
        
        return sourceMapPath;
    }
    
    /**
     * Get or create source file index for VLQ encoding
     */
    private function getOrCreateSourceIndex(sourceFile: String): Int {
        // Normalize the source file path to be environment-independent
        var normalizedPath = normalizeSourcePath(sourceFile);
        
        if (sourceIndexes.exists(normalizedPath)) {
            return sourceIndexes.get(normalizedPath);
        }
        
        var index = sources.length;
        sources.push(normalizedPath);
        sourceIndexes.set(normalizedPath, index);
        return index;
    }
    
    /**
     * Normalize source file paths to be environment-independent.
     * Converts absolute paths to relative paths from a common base.
     */
    private function normalizeSourcePath(sourceFile: String): String {
        // If it's a standard library file, make it relative to std/
        if (sourceFile.indexOf('/std/') >= 0) {
            var stdIndex = sourceFile.indexOf('/std/');
            return sourceFile.substring(stdIndex + 1); // Keep "std/" prefix
        }
        
        // For non-std files, try to make relative to common project patterns
        if (sourceFile.indexOf('/src/') >= 0) {
            var srcIndex = sourceFile.indexOf('/src/');
            return sourceFile.substring(srcIndex + 1); // Keep "src/" prefix
        }
        
        // As fallback, just use the filename if we can't determine a good base
        var lastSlash = sourceFile.lastIndexOf('/');
        if (lastSlash >= 0) {
            return sourceFile.substring(lastSlash + 1);
        }
        
        return sourceFile;
    }
    
    /**
     * Encode a signed integer using Variable Length Quantity (VLQ) Base64 encoding.
     * This is the standard encoding used in Source Map v3 specification.
     * 
     * @param value Signed integer to encode
     */
    private function writeVLQ(value: Int): Void {
        // Convert to VLQ format: move sign bit to LSB
        var vlq = if (value < 0) {
            ((-value) << 1) | 1;
        } else {
            value << 1;
        };
        
        // Encode using Base64 VLQ
        do {
            var digit = vlq & 31; // Bottom 5 bits
            vlq >>>= 5;
            
            if (vlq > 0) {
                digit |= 32; // Set continuation bit
            }
            
            mappingsBuffer.add(VLQ_CHARS[digit]);
        } while (vlq > 0);
    }
    
    /**
     * Extract filename from full path for source map file field
     */
    private function extractFileName(filePath: String): String {
        var lastSlash = filePath.lastIndexOf('/');
        if (lastSlash >= 0) {
            return filePath.substring(lastSlash + 1);
        }
        return filePath;
    }
    
    /**
     * Get debug information about current mapping state
     */
    public function getDebugInfo(): String {
        return 'SourceMapWriter Debug Info:\n' +
               '  Generated file: $generatedFile\n' +
               '  Sources: ${sources.length} files\n' +
               '  Current position: line unknown, column $currentGeneratedColumn\n' +
               '  Last mapped: ${lastMappedPos != null ? lastMappedPos.getFile() + ":" + lastMappedPos.line() : "none"}\n' +
               '  Mappings length: ${mappingsBuffer.length}';
    }
}

#end