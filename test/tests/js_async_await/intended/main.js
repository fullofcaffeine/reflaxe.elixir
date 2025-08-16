var $_, $hxClasses = $hxClasses || {}, $estr = function() { return js.Boot.__string_rec(this,''); };
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $global.$haxeUID++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = m.bind(o); o.hx__closures__[m.__id__] = f; } return f; };
HxOverrides = $hxClasses['HxOverrides'] = function() { };
HxOverrides.__name__ = "HxOverrides";
HxOverrides.cca = function(s,index) {
	let x = s.charCodeAt(index);
	if(x != x) {
		return undefined;
	}
	return x;
};
HxOverrides.substr = function(s,pos,len) {
	if(len == null) {
		len = s.length;
	} else if(len < 0) {
		if(pos == 0) {
			len = s.length + len;
		} else {
			return "";
		}
	}
	return s.substr(pos,len);
};
HxOverrides.now = function() {
	return Date.now();
};
HxOverrides.prototype.__class__ = HxOverrides;
Main = $hxClasses['Main'] = function() { };
Main.__name__ = "Main";
Main.simpleAsync = async function() {
	let greeting = await Promise.resolve("Hello");
	return Promise.resolve(greeting + " World");
};
Main.multipleAwaits = async function() {
	let first = await Promise.resolve("First");
	let second = await Promise.resolve("Second");
	let third = await Promise.resolve("Third");
	return Promise.resolve(first + "-" + second + "-" + third);
};
Main.errorHandling = async function() {
	try {
		let result = await Promise.reject("Test Error");
		return Promise.resolve("Should not reach here");
	} catch( _g ) {
		let error = haxe.Exception.caught(_g).unwrap();
		return Promise.resolve("Caught: " + Std.string(error));
	}
};
Main.conditionalAsync = async function(useAsync) {
	if(useAsync) {
		let result = await Promise.resolve("Async path");
		return Promise.resolve(result);
	} else {
		return Promise.resolve("Sync path");
	}
};
Main.regularFunction = function() {
	return "Not async";
};
Main.main = function() {
};
Main.prototype.__class__ = Main;
Std = $hxClasses['Std'] = function() { };
Std.__name__ = "Std";
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
};
Std.prototype.__class__ = Std;
StringTools = $hxClasses['StringTools'] = function() { };
StringTools.__name__ = "StringTools";
StringTools.isSpace = function(s,pos) {
	if(pos < 0 || pos >= s.length) {
		return false;
	}
	let c = HxOverrides.cca(s,pos);
	if(!(c > 8 && c < 14)) {
		return c == 32;
	} else {
		return true;
	}
};
StringTools.ltrim = function(s) {
	let l = s.length;
	let r = 0;
	while(r < l && StringTools.isSpace(s,r)) ++r;
	if(r > 0) {
		return HxOverrides.substr(s,r,l - r);
	} else {
		return s;
	}
};
StringTools.rtrim = function(s) {
	let l = s.length;
	let r = 0;
	while(r < l && StringTools.isSpace(s,l - r - 1)) ++r;
	if(r > 0) {
		return HxOverrides.substr(s,0,l - r);
	} else {
		return s;
	}
};
StringTools.trim = function(s) {
	return StringTools.ltrim(StringTools.rtrim(s));
};
StringTools.urlEncode = function(s) {
	return s;
};
StringTools.urlDecode = function(s) {
	return s;
};
StringTools.htmlEscape = function(s,quotes) {
	s = s.split("&").join("&amp;");
	s = s.split("<").join("&lt;");
	s = s.split(">").join("&gt;");
	if(quotes) {
		s = s.split("\"").join("&quot;");
		s = s.split("'").join("&#039;");
	}
	return s;
};
StringTools.htmlUnescape = function(s) {
	return s.split("&gt;").join(">").split("&lt;").join("<").split("&quot;").join("\"").split("&#039;").join("'").split("&amp;").join("&");
};
StringTools.startsWith = function(s,start) {
	if(s.length >= start.length) {
		return HxOverrides.substr(s,0,start.length) == start;
	} else {
		return false;
	}
};
StringTools.endsWith = function(s,end) {
	let elen = end.length;
	let slen = s.length;
	if(slen >= elen) {
		return HxOverrides.substr(s,slen - elen,elen) == end;
	} else {
		return false;
	}
};
StringTools.replace = function(s,sub,by) {
	return s.split(sub).join(by);
};
StringTools.lpad = function(s,c,l) {
	if(c.length <= 0) {
		return s;
	}
	let buf = "";
	l -= s.length;
	while(buf.length < l) buf += c;
	return buf + s;
};
StringTools.rpad = function(s,c,l) {
	if(c.length <= 0) {
		return s;
	}
	let buf = s;
	while(buf.length < l) buf += c;
	return buf;
};
StringTools.contains = function(s,value) {
	return s.indexOf(value) != -1;
};
StringTools.fastCodeAt = function(s,index) {
	return HxOverrides.cca(s,index);
};
StringTools.unsafeCodeAt = function(s,index) {
	return HxOverrides.cca(s,index);
};
StringTools.isEof = function(c) {
	return false;
};
StringTools.hex = function(n,digits) {
	let s = "";
	let hexChars = "0123456789ABCDEF";
	if(n < 0) {
		n = -n;
		s = "-";
	}
	if(n == 0) {
		s = "0";
	} else {
		let result = "";
		while(n > 0) {
			result = hexChars.charAt(n & 15) + result;
			n >>>= 4;
		}
		s += result;
	}
	if(digits != null) {
		while(s.length < digits) s = "0" + s;
	}
	return s;
};
StringTools.iterator = function(s) {
	return new haxe.iterators.StringIterator(s);
};
StringTools.keyValueIterator = function(s) {
	return new haxe.iterators.StringKeyValueIterator(s);
};
StringTools.quoteUnixArg = function(argument) {
	if(argument == "") {
		return "''";
	}
	return "'" + StringTools.replace(argument,"'","'\"'\"'") + "'";
};
StringTools.quoteWinArg = function(argument,escapeMetaCharacters) {
	if(argument.indexOf(" ") != -1 || argument == "") {
		argument = "\"" + StringTools.replace(argument,"\"","\\\"") + "\"";
	}
	return argument;
};
StringTools.utf16CodePointAt = function(s,index) {
	let c = StringTools.fastCodeAt(s,index);
	if(c >= 55296 && c <= 56319) {
		c = c - 55296 << 10 | StringTools.fastCodeAt(s,index + 1) & 1023 | 65536;
	}
	return c;
};
StringTools.prototype.__class__ = StringTools;
if(typeof haxe=='undefined') haxe = {};
haxe.Exception = $hxClasses['haxe.Exception'] = function(message,previous,native) {
	super(message);
	this.message = message;
	this.__previousException = previous;
	this.__nativeException = native != null ? native : this;
};
haxe.Exception.__name__ = "haxe.Exception";
haxe.Exception.__super__ = Error;
for(var k in Error.prototype ) haxe.Exception.prototype[k] = Error.prototype[k];
haxe.Exception.caught = function(value) {
	if(((value) instanceof haxe.Exception)) {
		return value;
	} else if(((value) instanceof Error)) {
		return new haxe.Exception(value.message,null,value);
	} else {
		return new haxe.ValueException(value,null,value);
	}
};
haxe.Exception.prototype.__skipStack = null;
haxe.Exception.prototype.__nativeException = null;
haxe.Exception.prototype.__previousException = null;
haxe.Exception.prototype.unwrap = function() {
	return this.__nativeException;
};
haxe.Exception.prototype.__class__ = haxe.Exception;
haxe.ValueException = $hxClasses['haxe.ValueException'] = function(value,previous,native) {
	super(String(value),previous,native);
	this.value = value;
};
haxe.ValueException.__name__ = "haxe.ValueException";
haxe.ValueException.__super__ = haxe.Exception;
for(var k in haxe.Exception.prototype ) haxe.ValueException.prototype[k] = haxe.Exception.prototype[k];
haxe.ValueException.prototype.value = null;
haxe.ValueException.prototype.unwrap = function() {
	return this.value;
};
haxe.ValueException.prototype.__class__ = haxe.ValueException;
if(!haxe.iterators) haxe.iterators = {};
haxe.iterators.StringIterator = $hxClasses['haxe.iterators.StringIterator'] = function(s) {
	this.s = s;
};
haxe.iterators.StringIterator.__name__ = "haxe.iterators.StringIterator";
haxe.iterators.StringIterator.prototype.s = null;
haxe.iterators.StringIterator.prototype.__class__ = haxe.iterators.StringIterator;
haxe.iterators.StringKeyValueIterator = $hxClasses['haxe.iterators.StringKeyValueIterator'] = function(s) {
	this.s = s;
};
haxe.iterators.StringKeyValueIterator.__name__ = "haxe.iterators.StringKeyValueIterator";
haxe.iterators.StringKeyValueIterator.prototype.s = null;
haxe.iterators.StringKeyValueIterator.prototype.__class__ = haxe.iterators.StringKeyValueIterator;
if(typeof js=='undefined') js = {};
js.Boot = $hxClasses['js.Boot'] = function() { };
js.Boot.__name__ = "js.Boot";
js.Boot.__string_rec = function(o,s) {
	if(o == null) {
		return "null";
	}
	if(s.length >= 5) {
		return "<...>";
	}
	let t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) {
		t = "object";
	}
	switch(t) {
	case "function":
		return "<function>";
	case "object":
		if(((o) instanceof Array)) {
			let str = "[";
			s += "\t";
			let _g = 0;
			let _g1 = o.length;
			while(_g < _g1) {
				let i = _g++;
				str += (i > 0 ? "," : "") + js.Boot.__string_rec(o[i],s);
			}
			str += "]";
			return str;
		}
		let tostr;
		try {
			tostr = o.toString;
		} catch( _g ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			let s2 = o.toString();
			if(s2 != "[object Object]") {
				return s2;
			}
		}
		let str = "{\n";
		s += "\t";
		let hasp = o.hasOwnProperty != null;
		let k = null;
		for( k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) {
			str += ", \n";
		}
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "string":
		return o;
	default:
		return String(o);
	}
};
js.Boot.__toStr = null;
js.Boot.prototype.__class__ = js.Boot;
if(typeof reflaxe=='undefined') reflaxe = {};
if(!reflaxe.js) reflaxe.js = {};
reflaxe.js.Async = $hxClasses['reflaxe.js.Async'] = function() { };
reflaxe.js.Async.__name__ = "reflaxe.js.Async";
reflaxe.js.Async.resolve = function(value) {
	return Promise.resolve(value);
};
reflaxe.js.Async.reject = function(error) {
	return Promise.reject(error);
};
reflaxe.js.Async.delay = function(value,delayMs) {
	return new Promise(function(resolve,reject) {
		window.setTimeout(function() {
			resolve(value);
		},delayMs);
	});
};
reflaxe.js.Async.fromCallback = function(fn) {
	return new Promise(function(resolve,reject) {
		try {
			fn(resolve);
		} catch( _g ) {
			let error = haxe.Exception.caught(_g).unwrap();
			reject(error);
		}
	});
};
reflaxe.js.Async.prototype.__class__ = reflaxe.js.Async;
(typeof(performance) != "undefined" ? typeof(performance.now) == "function" : false) ? HxOverrides.now = performance.now.bind(performance) : null;
;
;
{
	String.__name__ = true;
	Array.__name__ = true;
};
js.Boot.__toStr = ({ }).toString;
StringTools.winMetaCharacters = [40,41,37,33,94,34,60,62,38,124];
;
StringTools.MIN_SURROGATE_CODE_POINT = 65536;
;
Main.main();
