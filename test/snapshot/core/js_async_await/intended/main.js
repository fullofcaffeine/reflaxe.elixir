var $_, $hxClasses = $hxClasses || {}, $estr = function() { return js.Boot.__string_rec(this,''); };
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $global.$haxeUID++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = m.bind(o); o.hx__closures__[m.__id__] = f; } return f; };
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
haxe.iterators.ArrayIterator = $hxClasses['haxe.iterators.ArrayIterator'] = function(array) {
	this.current = 0;
	this.array = array;
};
haxe.iterators.ArrayIterator.__name__ = "haxe.iterators.ArrayIterator";
haxe.iterators.ArrayIterator.prototype.array = null;
haxe.iterators.ArrayIterator.prototype.current = null;
haxe.iterators.ArrayIterator.prototype.hasNext = function() {
	return this.current < this.array.length;
};
haxe.iterators.ArrayIterator.prototype.next = function() {
	return this.array[this.current++];
};
haxe.iterators.ArrayIterator.prototype.__class__ = haxe.iterators.ArrayIterator;
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
;
;
{
	String.__name__ = true;
	Array.__name__ = true;
};
js.Boot.__toStr = ({ }).toString;
Main.main();
