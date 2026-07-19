package server.layouts;

import plug.CSRFProtection;
import phoenix.types.Assigns;
import phoenix.types.Assigns.LayoutAssigns;
import server.live.TodoLiveTypes.TodoLiveAssigns;
import server.types.Types.User;

/**
 * Main layouts module for Phoenix application
 * Provides the layout functions that Phoenix expects
 */
// @:component (class): marks this module as a Phoenix component container so component functions are preserved and discoverable.
@:component
class Layouts {
	/**
	 * Root layout function
	 *
	 * WHY
	 * - Previously this returned only `inner_content`, so the page lacked the
	 *   required `<link>`/`<script>` tags and Tailwind never loaded.
	 *
	 * HOW
	 * - Return a real HEEx root document that includes tracked static assets
	 *   and yields `assigns.inner_content`. This mirrors Phoenix 1.7 defaults and
	 *   lets our HEEx transformer convert this string into a `~H` sigil.
	 */
	// @:component (function): marks this function as a typed dot-component entrypoint (props/slots can be validated).
	@:component public static function root(assigns:Assigns<LayoutAssigns<User, TodoLiveAssigns>>):String {
		return <html lang="en" class="h-full">
			<head>
				<meta charset="utf-8" />
				<meta http-equiv="X-UA-Compatible" content="IE=edge" />
				<meta name="viewport" content="width=device-width, initial-scale=1.0" />
				<title>Todo App</title>
				<meta name="csrf-token" content=${CSRFProtection.get_csrf_token()} />

				<!-- Static assets (served by Phoenix Endpoint) -->
				<link phx-track-static rel="stylesheet" href="/assets/app.css" />
				<!-- Canonical Vite entry that loads the Haxe-authored client and LiveSocket bootstrap -->
				<!-- BEGIN reflaxe_elixir live_react_vite_assets -->
				<TodoAppWeb.ReactIslands.LiveReactAssets.vite_assets assets=${["/js/app.js"]}>
				  <script defer phx-track-static type="module" src="/assets/app.js"></script>
				</TodoAppWeb.ReactIslands.LiveReactAssets.vite_assets>
				<!-- END reflaxe_elixir live_react_vite_assets -->
			</head>
			<body class="h-full bg-gray-50 dark:bg-gray-900 font-inter antialiased">
				<main id="main-content" class="h-full">
					${assigns.inner_content}
				</main>
			</body>
		</html>;
	}

	/**
	 * Application layout function
	 * - Wraps content in a responsive container and basic page chrome.
	 */
	@:component public static function app(assigns:Assigns<LayoutAssigns<User, TodoLiveAssigns>>):String {
		return <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-blue-900">
			<div class="container mx-auto px-4 py-8 max-w-6xl">
				${assigns.inner_content}
			</div>
		</div>;
	}
}
