package;

import phoenix.Phoenix.Form;

typedef User = {
	var id:Int;
	var name:String;
}

typedef UserParams = {
	var name:String;
}

typedef SearchParams = {
	var query:String;
}

typedef AppAssigns = {
	var form:Form<User>;
	var searchForm:Form<SearchParams>;
	var userId:Null<Int>;
}
