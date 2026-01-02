import {Register} from "../../genes/Register.js"
import {ThemePreference} from "./ThemePreference.js"

const $global = Register.$global

export const Theme = Register.global("$hxClasses")["client.utils.Theme"] = 
class Theme {
	static getMediaQuery() {
		if (window != null) {
			return window.matchMedia("(prefers-color-scheme: dark)");
		} else {
			return null;
		};
	}
	static prefersDark() {
		let media = Theme.getMediaQuery();
		if (media != null) {
			return media.matches;
		} else {
			return false;
		};
	}
	static getStored() {
		try {
			let storage = (window != null) ? window.localStorage : null;
			if (storage == null) {
				return null;
			};
			return ThemePreference.parse(storage.getItem("todo_app_theme"));
		}catch (_g) {
			return null;
		};
	}
	static getStoredOrDefault() {
		let tmp = Theme.getStored();
		if (tmp != null) {
			return tmp;
		} else {
			return "system";
		};
	}
	static store(preference) {
		try {
			let storage = (window != null) ? window.localStorage : null;
			if (storage == null) {
				return;
			};
			storage.setItem("todo_app_theme", preference);
		}catch (_g) {
		};
	}
	static apply(preference) {
		let root = (window.document != null) ? window.document.documentElement : null;
		if (root == null) {
			return;
		};
		let dark;
		switch (preference) {
			case "dark":
				dark = true;
				break
			case "light":
				dark = false;
				break
			case "system":
				dark = Theme.prefersDark();
				break
			
		};
		if (dark) {
			root.classList.add("dark");
		} else {
			root.classList.remove("dark");
		};
		root.setAttribute("data-theme", preference);
	}
	static applyStoredOrDefault() {
		let preference = Theme.getStoredOrDefault();
		Theme.apply(preference);
		return preference;
	}
	static cycle(preference) {
		switch (preference) {
			case "dark":
				return "system";
				break
			case "light":
				return "dark";
				break
			case "system":
				return "light";
				break
			
		};
	}
	static get __name__() {
		return "client.utils.Theme"
	}
	get __class__() {
		return Theme
	}
}

