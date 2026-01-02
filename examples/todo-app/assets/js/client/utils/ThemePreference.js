import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const ThemePreference = Register.global("$hxClasses")["client.utils._ThemePreference.ThemePreference"] = 
class ThemePreference {
	static parse(value) {
		if (value == null) {
			return null;
		} else {
			switch (value) {
				case "dark":
					return "dark";
					break
				case "light":
					return "light";
					break
				case "system":
					return "system";
					break
				default:
				return null;
				
			};
		};
	}
	static get __name__() {
		return "client.utils._ThemePreference.ThemePreference_Impl_"
	}
	get __class__() {
		return ThemePreference
	}
}

