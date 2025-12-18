package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * File module extern definitions for Elixir standard library
 * Provides type-safe interfaces for file system operations
 * 
 * Maps to Elixir's File module functions with proper type signatures
 * Essential for file I/O, directory operations, and file system management
 */
@:native("File")
extern class File {
    
    // File reading operations
    @:native("File.read")
    public static function read(path: String): {_0: String, _1: Term}; // {:ok, binary} | {:error, reason}
    
    @:native("File.read!")
    public static function readBang(path: String): String; // Returns content or raises
    
    @:native("File.open")
    public static function open(path: String): {_0: String, _1: Term}; // {:ok, file} | {:error, reason}
    
    @:native("File.open")
    public static function openWithModes(path: String, modes: Array<String>): {_0: String, _1: Term};
    
    @:native("File.open")
    public static function openWithFunction<T>(path: String, modes: Array<String>, func: Term -> T): {_0: String, _1: T};
    
    @:native("File.close")
    public static function close(file: Term): Term; // Returns :ok
    
    // File writing operations
    @:native("File.write")
    public static function write(path: String, content: Term): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.write")
    public static function writeWithModes(path: String, content: Term, modes: Array<String>): {_0: String, _1: Term};
    
    @:native("File.write!")
    public static function writeBang(path: String, content: Term): Term; // Returns :ok or raises
    
    @:native("File.write!")
    public static function writeBangWithModes(path: String, content: Term, modes: Array<String>): Term;
    
    // File streaming operations
    @:native("File.stream!")
    public static function stream(path: String): Term; // File stream
    
    @:native("File.stream!")
    public static function streamWithModes(path: String, modes: Array<String>): Term;
    
    @:native("File.stream!")
    public static function streamWithOptions(path: String, modes: Array<String>, lineOrBytes: Term): Term;
    
    // File information and status
    @:native("File.stat")
    public static function stat(path: String): {_0: String, _1: Term}; // {:ok, stat} | {:error, reason}
    
    @:native("File.stat")
    public static function statWithOptions(path: String, options: Map<String, Term>): {_0: String, _1: Term};
    
    @:native("File.stat!")
    public static function statBang(path: String): Map<String, Term>; // Returns stat or raises
    
    @:native("File.lstat")
    public static function lstat(path: String): {_0: String, _1: Term}; // Like stat but for symlinks
    
    @:native("File.lstat!")
    public static function lstatBang(path: String): Map<String, Term>;
    
    // File existence and type checking
    @:native("File.exists?")
    public static function exists(path: String): Bool;
    
    @:native("File.regular?")
    public static function regular(path: String): Bool;
    
    @:native("File.dir?")
    public static function dir(path: String): Bool;
    
    @:native("File.symlink?")
    public static function symlink(path: String): Bool;
    
    // File operations
    @:native("File.copy")
    public static function copy(source: String, destination: String): {_0: String, _1: Term}; // {:ok, bytes_copied} | {:error, reason}
    
    @:native("File.copy")
    public static function copyWithOptions(source: String, destination: String, options: Map<String, Term>): {_0: String, _1: Term};
    
    @:native("File.copy!")
    public static function copyBang(source: String, destination: String): Int; // Returns bytes copied or raises
    
    @:native("File.cp")
    public static function cp(source: String, destination: String): {_0: String, _1: Term}; // Alias for copy
    
    @:native("File.cp!")
    public static function cpBang(source: String, destination: String): Term; // Returns :ok or raises
    
    @:native("File.cp_r")
    public static function cpRecursive(source: String, destination: String): {_0: String, _1: Term}; // Recursive copy
    
    @:native("File.cp_r!")
    public static function cpRecursiveBang(source: String, destination: String): Array<String>; // Returns copied files
    
    // File renaming and moving
    @:native("File.rename")
    public static function rename(source: String, destination: String): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.rename!")
    public static function renameBang(source: String, destination: String): Term; // Returns :ok or raises
    
    // File deletion
    @:native("File.rm")
    public static function rm(path: String): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.rm!")
    public static function rmBang(path: String): Term; // Returns :ok or raises
    
    @:native("File.rm_rf")
    public static function rmRecursive(path: String): {_0: String, _1: Term}; // Recursive remove
    
    @:native("File.rm_rf!")
    public static function rmRecursiveBang(path: String): Array<String>; // Returns removed files
    
    // Directory operations
    @:native("File.mkdir")
    public static function mkdir(path: String): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.mkdir!")
    public static function mkdirBang(path: String): Term; // Returns :ok or raises
    
    @:native("File.mkdir_p")
    public static function mkdirRecursive(path: String): {_0: String, _1: Term}; // Create with parents
    
    @:native("File.mkdir_p!")
    public static function mkdirRecursiveBang(path: String): Term;
    
    @:native("File.rmdir")
    public static function rmdir(path: String): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.rmdir!")
    public static function rmdirBang(path: String): Term;
    
    @:native("File.ls")
    public static function ls(path: String): {_0: String, _1: Term}; // {:ok, filenames} | {:error, reason}
    
    @:native("File.ls!")
    public static function lsBang(path: String): Array<String>; // Returns filenames or raises
    
    // File permissions and ownership
    @:native("File.chmod")
    public static function chmod(path: String, mode: Int): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.chmod!")
    public static function chmodBang(path: String, mode: Int): Term;
    
    @:native("File.chown")
    public static function chown(path: String, uid: Int, gid: Int): {_0: String, _1: Term};
    
    @:native("File.chown!")
    public static function chownBang(path: String, uid: Int, gid: Int): Term;
    
    @:native("File.chgrp")
    public static function chgrp(path: String, gid: Int): {_0: String, _1: Term};
    
    @:native("File.chgrp!")
    public static function chgrpBang(path: String, gid: Int): Term;
    
    // Symbolic links
    @:native("File.ln")
    public static function ln(existing: String, newLink: String): {_0: String, _1: Term}; // Hard link
    
    @:native("File.ln!")
    public static function lnBang(existing: String, newLink: String): Term;
    
    @:native("File.ln_s")
    public static function lnSymbolic(existing: String, newLink: String): {_0: String, _1: Term}; // Symbolic link
    
    @:native("File.ln_s!")
    public static function lnSymbolicBang(existing: String, newLink: String): Term;
    
    @:native("File.readlink")
    public static function readlink(path: String): {_0: String, _1: Term}; // Read symbolic link
    
    @:native("File.readlink!")
    public static function readlinkBang(path: String): String;
    
    // File timestamps
    @:native("File.touch")
    public static function touch(path: String): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.touch")
    public static function touchWithTime(path: String, time: Term): {_0: String, _1: Term};
    
    @:native("File.touch!")
    public static function touchBang(path: String): Term;
    
    @:native("File.touch!")
    public static function touchBangWithTime(path: String, time: Term): Term;
    
    // Working directory
    @:native("File.cwd")
    public static function cwd(): {_0: String, _1: String}; // {:ok, cwd} | {:error, reason}
    
    @:native("File.cwd!")
    public static function cwdBang(): String; // Returns cwd or raises
    
    @:native("File.cd")
    public static function cd(path: String): {_0: String, _1: Term}; // {:ok} | {:error, reason}
    
    @:native("File.cd!")
    public static function cdBang(path: String): Term;
    
    @:native("File.cd")
    public static function cdWithFunction<T>(path: String, func: Void -> T): T; // Execute function in directory
    
    // Common file modes
    public static inline var READ: String = "read";
    public static inline var WRITE: String = "write";
    public static inline var APPEND: String = "append";
    public static inline var EXCLUSIVE: String = "exclusive";
    public static inline var BINARY: String = "binary";
    public static inline var UTF8: String = "utf8";
    public static inline var COMPRESSED: String = "compressed";
    public static inline var DELAYED_WRITE: String = "delayed_write";
    public static inline var READ_AHEAD: String = "read_ahead";
    
    // Helper functions for common operations
    public static inline function readText(path: String): Null<String> {
        var result = read(path);
        return result._0 == "ok" ? cast result._1 : null;
    }
    
    public static inline function writeText(path: String, content: String): Bool {
        var result = write(path, content);
        return result._0 == "ok";
    }
    
    public static inline function appendText(path: String, content: String): Bool {
        var result = writeWithModes(path, content, [APPEND]);
        return result._0 == "ok";
    }
    
    public static inline function readLines(path: String): Null<Array<String>> {
        var content = readText(path);
        return content != null ? content.split("\n") : null;
    }
    
    public static inline function writeLines(path: String, lines: Array<String>): Bool {
        return writeText(path, lines.join("\n"));
    }
    
    public static inline function createDir(path: String, recursive: Bool = false): Bool {
        var result = recursive ? mkdirRecursive(path) : mkdir(path);
        return result._0 == "ok";
    }
    
    public static inline function deleteFile(path: String, recursive: Bool = false): Bool {
        var result = recursive ? rmRecursive(path) : rm(path);
        return result._0 == "ok";
    }
    
    public static inline function listFiles(path: String): Null<Array<String>> {
        var result = ls(path);
        return result._0 == "ok" ? cast result._1 : null;
    }
    
    public static inline function fileSize(path: String): Int {
        var result = stat(path);
        if (result._0 == "ok") {
            var statMap: Map<String, Term> = cast result._1;
            return cast statMap.get("size");
        }
        return -1;
    }
    
    public static inline function isFile(path: String): Bool {
        return exists(path) && regular(path);
    }
    
    public static inline function isDirectory(path: String): Bool {
        return exists(path) && dir(path);
    }
}

#end
