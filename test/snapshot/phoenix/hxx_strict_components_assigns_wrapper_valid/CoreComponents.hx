package;

import HXX;
import phoenix.types.Assigns;

typedef CardAssigns = {
	var title:String;
	var inner_content:String;
}

@:native("AppWeb.CoreComponents")
@:component
@:hxx_mode("balanced")
class CoreComponents {
	@:component
	public static function card(assigns:Assigns<CardAssigns>):String {
		return HXX.hxx('<div><h2>${assigns.title}</h2>${assigns.inner_content}</div>');
	}
}
