package server.services;

/**
 * InviteEmail
 *
 * Thin extern wrapper for the hand-written Elixir module `TodoApp.InviteEmail`.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoApp.InviteEmail")
extern class InviteEmail {
	public static function deliverInvite(toEmail:String, orgSlug:String, orgName:String, role:String, inviterName:Null<String>):Bool;
}
