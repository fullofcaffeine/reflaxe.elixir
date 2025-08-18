/**
 * Temporary patch for Reflaxe 4.0.0-beta OutputManager bug
 * 
 * Problem: Some modules (like EReg) get malformed module names starting with "/"
 * This causes OutputManager to attempt writing to filesystem root: "/e_reg.ex"
 * 
 * Solution: Patch the moduleId() function in BaseTypeHelper to sanitize paths
 */

// This would be the fix to apply to BaseTypeHelper.hx:
// 
// public static function moduleId(self: BaseType): String {
//     var module = self.module;
//     
//     // Fix for malformed module paths starting with "/"
//     if (StringTools.startsWith(module, "/")) {
//         module = module.substr(1); // Remove leading slash
//     }
//     
//     return StringTools.replace(module, ".", "_");
// }

// Alternative fix in OutputManager.hx saveFile method:
//
// public function saveFile(path: String, content: StringOrBytes) {
//     // Sanitize path to prevent writing to filesystem root
//     var sanitizedPath = path;
//     if (StringTools.startsWith(path, "/") && !StringTools.startsWith(path, "/Users/") && !StringTools.startsWith(path, "/tmp/")) {
//         // This looks like a malformed relative path, remove leading slash
//         sanitizedPath = path.substr(1);
//     }
//     
//     // Get full path
//     final p = if(haxe.io.Path.isAbsolute(sanitizedPath)) {
//         sanitizedPath;
//     } else if(outputDir != null) {
//         joinPaths(outputDir, sanitizedPath);
//     } else {
//         sanitizedPath;
//     }
//     // ... rest of method
// }