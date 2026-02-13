package server.infrastructure;

import HXX.*;

typedef LayoutTemplateAssigns = {
	inner_content:String
}

/**
 * Minimal layouts for Phoenix controller/live rendering.
 */
@:native("ElixirFirstLiveviewWeb.Layouts")
@:component
class Layouts {
	@:component
	public static function root(assigns:LayoutTemplateAssigns):String {
		return <html lang="en">
            <head>
                <meta charset="utf-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>Elixir First Liveview</title>
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
