package phoenix_chat_hx.live;

import phoenix_chat_hx.frontend.PreferenceDensity;

/** Native LiveView assigns for the project-local Crema invitation proof. */
typedef CremaInviteAssigns = {
	page_title:String,
	name:String,
	email:String,
	project:String,
	request_state:String,
	request_status:Null<String>,
	preference_density:PreferenceDensity,
	preference_status:Null<String>,
}
