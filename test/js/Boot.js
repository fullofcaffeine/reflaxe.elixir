import {Register} from "../genes/Register.js"

export const Boot = Register.global("$hxClasses")["js.Boot"] = 
class Boot {
	static __string_rec(o, s) {
		if (o == null) {
			return "null";
		};
		if (s.length >= 5) {
			return "<...>";
		};
		let t = typeof(o);
		if (t == "function" && (o.__name__ || o.__ename__)) {
			t = "object";
		};
		switch (t) {
			case "function":
				return "<function>";
				break
			case "object":
				if (((o) instanceof Array)) {
					let str = "[";
					s += "\t";
					let _g = 0;
					let _g1 = o.length;
					while (_g < _g1) {
						let i = _g++;
						str += ((i > 0) ? "," : "") + Boot.__string_rec(o[i], s);
					};
					str += "]";
					return str;
				};
				let tostr;
				try {
					tostr = o.toString;
				}catch (_g) {
					return "???";
				};
				if (tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
					let s2 = o.toString();
					if (s2 != "[object Object]") {
						return s2;
					};
				};
				let str = "{\n";
				s += "\t";
				let hasp = o.hasOwnProperty != null;
				let k = null;
				for( k in o ) {;
				if (hasp && !o.hasOwnProperty(k)) {
					continue;
				};
				if (k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
					continue;
				};
				if (str.length != 2) {
					str += ", \n";
				};
				str += s + k + " : " + Boot.__string_rec(o[k], s);
				};
				s = s.substring(1);
				str += "\n" + s + "}";
				return str;
				break
			case "string":
				return o;
				break
			default:
			return String(o);
			
		};
	}
	static get __name__() {
		return "js.Boot"
	}
	get __class__() {
		return Boot
	}
}


;Boot.__toStr = ({}).toString
