package server.infrastructure;

import HXX.*;
import plug.CSRFProtection;

typedef LayoutTemplateAssigns = {
	inner_content:String
}

/**
 * Minimal layouts for Phoenix controller/live rendering.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("ElixirFirstLiveviewWeb.Layouts")
// @:component (class): marks this module as a Phoenix component container so component functions are preserved and discoverable.
@:component
class Layouts {
	// @:component (function): marks this function as a typed dot-component entrypoint (props/slots can be validated).
	@:component
	public static function root(assigns:LayoutTemplateAssigns):String {
		return <html lang="en">
            <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <meta name="csrf-token" content=${CSRFProtection.get_csrf_token()} />
                <title>Elixir First Liveview</title>
                <script defer phx-track-static type="text/javascript" src="/assets/phoenix_app.js"></script>
            </head>
            <body>
                ${assigns.inner_content}
            </body>
        </html>;
	}

	@:component
	public static function app(assigns:LayoutTemplateAssigns):String {
		return <div class="min-h-screen bg-slate-50 text-slate-900">
            ${assigns.inner_content}
        </div>;
	}
}
