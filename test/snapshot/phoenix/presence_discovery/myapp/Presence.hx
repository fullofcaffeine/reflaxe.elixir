package myapp;

import phoenix.PresenceBehavior;

/**
 * Unreferenced Presence module used to validate RepoDiscovery + DCE preservation.
 *
 * This file intentionally is *not* referenced from Main.hx; RepoDiscovery must
 * force typing it and AnnotatedModuleEnumerator must keep it so the @:presence
 * transform can emit the Elixir module.
 */
@:native("MyAppWeb.Presence")
@:presence
class Presence implements PresenceBehavior {}

