package test;

using StringTools;

/**
 * Common testing utilities shared between TestRunner and ParallelTestRunner
 * 
 * This module contains shared functionality to reduce code duplication and
 * ensure consistent behavior between sequential and parallel test execution.
 */
class TestCommon {
    
    /**
     * Get all files from a directory recursively
     * @param dir Directory to scan
     * @param prefix Prefix for relative paths (optional)
     * @return Array of relative file paths
     */
    public static function getAllFiles(dir: String, prefix: String = ""): Array<String> {
        if (!sys.FileSystem.exists(dir)) return [];
        
        final files = [];
        for (item in sys.FileSystem.readDirectory(dir)) {
            final path = haxe.io.Path.join([dir, item]);
            final relPath = prefix.length > 0 ? haxe.io.Path.join([prefix, item]) : item;
            
            if (sys.FileSystem.isDirectory(path)) {
                // Recursively get files from subdirectories
                for (subFile in getAllFiles(path, relPath)) {
                    files.push(subFile);
                }
            } else {
                files.push(relPath);
            }
        }
        return files;
    }
    
    /**
     * Normalize file content for comparison
     * @param content File content to normalize
     * @param fileName Optional filename for special handling
     * @return Normalized content
     */
    public static function normalizeContent(content: String, fileName: String = ""): String {
        // Normalize line endings and trim whitespace
        var normalized = StringTools.trim(StringTools.replace(content, "\r\n", "\n"));
        normalized = StringTools.replace(normalized, "\r", "\n");
        
        // Special handling for _GeneratedFiles.json - ignore the id field which increments on each build
        if (fileName == "_GeneratedFiles.json") {
            // Parse as JSON and remove the id field for comparison
            try {
                var lines = normalized.split("\n");
                var filteredLines = [];
                var idRegex = ~/^\s*"id"\s*:\s*\d+,?$/;
                for (line in lines) {
                    // Skip the id line (with or without trailing comma)
                    if (!idRegex.match(line)) {
                        filteredLines.push(line);
                    }
                }
                normalized = filteredLines.join("\n");
            } catch (e: Dynamic) {
                // If parsing fails, use original normalized content
            }
        }
        
        // Remove trailing whitespace from each line and trailing empty lines
        var lines = normalized.split("\n");
        lines = lines.map(line -> StringTools.rtrim(line));
        
        // Remove trailing empty lines
        while (lines.length > 0 && lines[lines.length - 1] == "") {
            lines.pop();
        }
        
        return lines.join("\n");
    }
    
    /**
     * Compare two directories and return list of differences
     * @param actualDir Directory with actual output
     * @param intendedDir Directory with intended/expected output
     * @return Array of difference descriptions (empty if no differences)
     */
    public static function compareDirectoriesDetailed(actualDir: String, intendedDir: String): Array<String> {
        final differences = [];
        
        // Get all files from intended directory
        final intendedFiles = getAllFiles(intendedDir);
        final actualFiles = getAllFiles(actualDir);
        
        // Check each intended file exists and matches
        for (file in intendedFiles) {
            final intendedPath = haxe.io.Path.join([intendedDir, file]);
            final actualPath = haxe.io.Path.join([actualDir, file]);
            
            if (!sys.FileSystem.exists(actualPath)) {
                differences.push('Missing file: $file');
                continue;
            }
            
            // Compare file contents
            final intendedContent = normalizeContent(sys.io.File.getContent(intendedPath), file);
            final actualContent = normalizeContent(sys.io.File.getContent(actualPath), file);
            
            if (intendedContent != actualContent) {
                differences.push('Content differs: $file');
            }
        }
        
        // Check for extra files in actual output
        for (file in actualFiles) {
            if (!intendedFiles.contains(file)) {
                differences.push('Extra file: $file');
            }
        }
        
        return differences;
    }
    
    /**
     * Compare two directories and return boolean result
     * @param actualDir Directory with actual output
     * @param intendedDir Directory with intended/expected output
     * @return True if directories match, false otherwise
     */
    public static function compareDirectoriesSimple(actualDir: String, intendedDir: String): Bool {
        // Check if intended directory exists - this is required
        if (!sys.FileSystem.exists(intendedDir)) {
            return false;
        }
        
        // Get all files from both directories
        // Note: getAllFiles handles non-existent directories by returning empty array
        final intendedFiles = getAllFiles(intendedDir);
        final actualFiles = getAllFiles(actualDir);
        
        // Quick check: same number of files
        if (intendedFiles.length != actualFiles.length) {
            return false;
        }
        
        // Check each intended file exists and matches
        for (file in intendedFiles) {
            final intendedPath = haxe.io.Path.join([intendedDir, file]);
            final actualPath = haxe.io.Path.join([actualDir, file]);
            
            if (!sys.FileSystem.exists(actualPath)) {
                return false;
            }
            
            // Compare file contents
            final intendedContent = normalizeContent(sys.io.File.getContent(intendedPath), file);
            final actualContent = normalizeContent(sys.io.File.getContent(actualPath), file);
            
            if (intendedContent != actualContent) {
                return false;
            }
        }
        
        return true;
    }
}