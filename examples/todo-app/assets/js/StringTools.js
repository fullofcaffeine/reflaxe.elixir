import {HxOverrides} from "./HxOverrides.js"
import {Register} from "./genes/Register.js"

const $global = Register.$global

/**
 * This class provides advanced methods on Strings. It is ideally used with
 * `using StringTools` and then acts as an [extension](https://haxe.org/manual/lf-static-extension.html)
 * to the `String` class.
 *
 * If the first argument to any of the methods is null, the result is
 * unspecified.
 */
export const StringTools = Register.hxClasses()["StringTools"] =
class StringTools {

	/**
	 * Tells if the character in the string `s` at position `pos` is a space.
	 *
	 * A character is considered to be a space character if its character code
	 * is 9,10,11,12,13 or 32.
	 *
	 * If `s` is the empty String `""`, or if pos is not a valid position within
	 * `s`, the result is false.
	 */
	static isSpace(s, pos) {
		let c = HxOverrides.cca(s, pos);
		if (!(c > 8 && c < 14)) {
			return c == 32;
		} else {
			return true;
		};
	}

	/**
	 * Removes leading space characters of `s`.
	 *
	 * This function internally calls `isSpace()` to decide which characters to
	 * remove.
	 *
	 * If `s` is the empty String `""` or consists only of space characters, the
	 * result is the empty String `""`.
	 */
	static ltrim(s) {
		let l = s.length;
		let r = 0;
		while (r < l && StringTools.isSpace(s, r)) ++r;
		if (r > 0) {
			return HxOverrides.substr(s, r, l - r);
		} else {
			return s;
		};
	}

	/**
	 * Removes trailing space characters of `s`.
	 *
	 * This function internally calls `isSpace()` to decide which characters to
	 * remove.
	 *
	 * If `s` is the empty String `""` or consists only of space characters, the
	 * result is the empty String `""`.
	 */
	static rtrim(s) {
		let l = s.length;
		let r = 0;
		while (r < l && StringTools.isSpace(s, l - r - 1)) ++r;
		if (r > 0) {
			return HxOverrides.substr(s, 0, l - r);
		} else {
			return s;
		};
	}

	/**
	 * Removes leading and trailing space characters of `s`.
	 *
	 * This is a convenience function for `ltrim(rtrim(s))`.
	 */
	static trim(s) {
		return StringTools.ltrim(StringTools.rtrim(s));
	}
	static get __name__() {
		return "StringTools"
	}
	get __class__() {
		return StringTools
	}
}
