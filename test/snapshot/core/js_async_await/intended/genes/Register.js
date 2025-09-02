
export class Register {
	static global(name) {
		if (Register.globals[name]) {
			return Register.globals[name];
		} else {
			return Register.globals[name] = {};
		};
	}
	static createStatic(obj, name, get) {
		let value = null;
		Object.defineProperty(obj, name, {"enumerable": true, "get": function () {
			if (get != null) {
				value = get();
				get = null;
			};
			return value;
		}, "set": function (v) {
			if (get != null) {
				value = get();
				get = null;
			};
			value = v;
		}});
	}
	static iterator(a) {
		if (!Array.isArray(a)) {
			return typeof a.iterator === "function" ? a.iterator.bind(a) : a.iterator;
		} else {
			let a1 = a;
			return function () {
				return Register.mkIter(a1);
			};
		};
	}
	static getIterator(a) {
		if (!Array.isArray(a)) {
			return a.iterator();
		} else {
			return Register.mkIter(a);
		};
	}
	static mkIter(a) {
		return new ArrayIterator(a);
	}
	static extend(superClass) {
		
      function res() {
        this[Register.new].apply(this, arguments)
      }
      Object.setPrototypeOf(res.prototype, superClass.prototype)
      return res
    ;
	}
	static inherits(resolve, defer) {
		if (defer == null) {
			defer = false;
		};
		
      function res() {
        if (defer && resolve && res[Register.init]) res[Register.init]()
        this[Register.new].apply(this, arguments)
      }
      if (!defer) {
        if (resolve && resolve[Register.init]) {
          defer = true
          res[Register.init] = () => {
            if (resolve[Register.init]) resolve[Register.init]()
            Object.setPrototypeOf(res.prototype, resolve.prototype)
            res[Register.init] = undefined
          } 
        } else if (resolve) {
          Object.setPrototypeOf(res.prototype, resolve.prototype)
        }
      } else {
        res[Register.init] = () => {
          const superClass = resolve()
          if (superClass[Register.init]) superClass[Register.init]()
          Object.setPrototypeOf(res.prototype, superClass.prototype)
          res[Register.init] = undefined
        } 
      }
      return res
    ;
	}
	static bind(o, m) {
		if (m == null) {
			return null;
		};
		if (m.__id__ == null) {
			m.__id__ = Register.fid++;
		};
		let f = null;
		if (o.hx__closures__ == null) {
			o.hx__closures__ = {};
		} else {
			f = o.hx__closures__[m.__id__];
		};
		if (f == null) {
			f = m.bind(o);
			o.hx__closures__[m.__id__] = f;
		};
		return f;
	}
	static get __name__() {
		return "genes.Register"
	}
	get __class__() {
		return Register
	}
}


Register.$global = typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : undefined
Register.globals = {}
Register["new"] = Symbol()
Register.init = Symbol()
Register.fid = 0
export const ArrayIterator = Register.global("$hxClasses")["genes._Register.ArrayIterator"] = 
class ArrayIterator extends Register.inherits() {
	[Register.new](array) {
		this.current = 0;
		this.array = array;
	}
	hasNext() {
		return this.current < this.array.length;
	}
	next() {
		return this.array[this.current++];
	}
	static get __name__() {
		return "genes._Register.ArrayIterator"
	}
	get __class__() {
		return ArrayIterator
	}
}
ArrayIterator.prototype.array = null;
ArrayIterator.prototype.current = null;

