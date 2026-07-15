/*
 * Copyright (C)2005-2018 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

import haxe.macro.Context;
import haxe.macro.Compiler;
import sys.FileSystem;
import haxe.io.Path;

/**
	Loads the pinned standard library so Haxe can emit its typed JSON API.

	This is a deliberately narrower adaptation of Haxe 4.3.7's
	`extra/ImportAll.hx`. It scans only the canonical `std` directory, never the
	consumer project's classpath. Scheduling the scan once also avoids the
	repeated initialization-macro warning produced by the upstream recursive
	callback.
**/
class StdlibApiImportAll {
	public static function run():Void {
		Compiler.define("doc_gen");
		if (Context.defined("interp"))
			Compiler.define("macro");

		Context.onAfterInitMacros(function() {
			var stdRoot = findStdRoot();
			scanDirectory(stdRoot, "");
		});
	}

	static function findStdRoot():String {
		for (candidate in Context.getClassPath()) {
			var normalized = Path.addTrailingSlash(candidate);
			if (FileSystem.exists(normalized + "Std.hx")
				&& FileSystem.isDirectory(normalized + "haxe")
				&& FileSystem.isDirectory(normalized + "sys"))
				return normalized;
		}

		Context.fatalError("Could not find the pinned Haxe std directory", Context.currentPos());
		return "";
	}

	static function isSysTarget():Bool {
		return Context.defined("neko") || Context.defined("php") || Context.defined("cpp") || Context.defined("java") || Context.defined("cs")
			|| Context.defined("python") || Context.defined("lua") || Context.defined("hl") || Context.defined("eval");
	}

	static function packageApplies(pack:String):Bool {
		return switch pack {
			case "sys": isSysTarget();
			case "sys.thread": Context.defined("target.threaded");
			case "js": Context.defined("js");
			case "php": Context.defined("php");
			case "neko": Context.defined("neko");
			case "cpp": Context.defined("cpp");
			case "java": Context.defined("java");
			case "cs": Context.defined("cs");
			case "python": Context.defined("python");
			case "hl": Context.defined("hl");
			case "lua": Context.defined("lua");
			case "eval": Context.defined("eval");
			case "mt", "mtwin", "tools", "build-tool", "jar-tool": false;
			case _: true;
		};
	}

	static function moduleApplies(module:String):Bool {
		return switch module {
			case "Sys": isSysTarget();
			case "haxe.TimerQueue": !(Context.defined("neko") || Context.defined("php") || Context.defined("cpp"));
			case "haxe.web.Request": Context.defined("neko") || Context.defined("php") || Context.defined("js");
			case "haxe.macro.ExampleJSGenerator", "haxe.macro.Context", "haxe.macro.Compiler": Context.defined("eval");
			case "haxe.remoting.SocketWrapper": Context.defined("flash");
			case "haxe.remoting.SyncSocketConnection": Context.defined("neko") || Context.defined("php") || Context.defined("cpp");
			case "neko.db.MacroManager": false;
			case "neko.vm.Ui", "sys.db.Sqlite", "sys.db.Mysql" if (Context.defined("interp")): false;
			case "sys.db.Sqlite", "sys.db.Mysql", "cs.db.AdoNet" if (Context.defined("cs")): false;
			case "haxe.atomic.AtomicBool", "haxe.atomic.AtomicInt": Context.defined("target.atomics");
			case "haxe.atomic.AtomicObject": Context.defined("target.atomics") && !Context.defined("js") && !Context.defined("cpp");
			case _: true;
		};
	}

	static function scanDirectory(stdRoot:String, pack:String):Void {
		if (!packageApplies(pack))
			return;

		var directory = pack == "" ? stdRoot : stdRoot + pack.split(".").join("/") + "/";
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
			return;

		var entries = FileSystem.readDirectory(directory);
		entries.sort(Reflect.compare);
		for (entry in entries) {
			if (entry == ".svn" || entry == "_std")
				continue;

			var path = directory + entry;
			var qualified = pack == "" ? entry : pack + "." + entry;
			if (FileSystem.isDirectory(path)) {
				// The inventory contract covers top-level, haxe.*, and sys.* only.
				if (pack != "" || entry == "haxe" || entry == "sys")
					scanDirectory(stdRoot, qualified);
				continue;
			}

			if (!StringTools.endsWith(entry, ".hx"))
				continue;
			var basename = entry.substr(0, entry.length - 3);
			if (basename.indexOf(".") >= 0)
				continue;

			var module = pack == "" ? basename : pack + "." + basename;
			if (module != "StdlibApiImportAll" && moduleApplies(module))
				Context.getModule(module);
		}
	}
}
