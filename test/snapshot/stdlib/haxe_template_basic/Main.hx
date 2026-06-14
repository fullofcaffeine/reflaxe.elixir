package;

import haxe.Template;

class Main {
	static function main() {
		var basic = new Template("Hello ::name::!");
		trace(basic.execute({name: "BEAM"}));

		var conditional = new Template("::if enabled::on::else::off::end::");
		trace(conditional.execute({enabled: true}));
		trace(conditional.execute({enabled: false}));

		var loop = new Template("::foreach items::::label::=::value::;::end::");
		trace(loop.execute({
			items: [{label: "a", value: 1}, {label: "b", value: 2}]
		}));

		var macroTemplate = new Template("$$upper(name)");
		trace(macroTemplate.execute({name: "beam"}, {
			upper: function(resolve:String->Dynamic, name:String) {
				return name.toUpperCase();
			}
		}));
	}
}
