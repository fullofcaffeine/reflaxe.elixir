import {Register} from "./genes/Register.js"

const $global = Register.$global

export const HxOverrides = Register.global("$hxClasses")["HxOverrides"] = 
class HxOverrides {
	static cca(s, index) {
		let x = s.charCodeAt(index);
		if (x != x) {
			return undefined;
		};
		return x;
	}
	static substr(s, pos, len) {
		if (len == null) {
			len = s.length;
		} else if (len < 0) {
			if (pos == 0) {
				len = s.length + len;
			} else {
				return "";
			};
		};
		return s.substr(pos, len);
	}
	static now() {
		return Date.now();
	}
	static get __name__() {
		return "HxOverrides"
	}
	get __class__() {
		return HxOverrides
	}
}


;((typeof(performance) != "undefined") ? typeof(performance.now) == "function" : false) ? HxOverrides.now = performance.now.bind(performance) : null
