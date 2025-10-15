package server.layouts;

// HXX is handled at compile-time by the Reflaxe.Elixir compiler - no imports needed

/**
 * Main layouts module for Phoenix application
 * Provides the layout functions that Phoenix expects
 */
@:native("TodoAppWeb.Layouts")
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
     *   and yields `@inner_content`. This mirrors Phoenix 1.7 defaults and
     *   lets our HEEx transformer convert this string into a `~H` sigil.
     */
    @:keep public static function root(assigns: Dynamic): Dynamic {
        return HXX.hxx('
            <!DOCTYPE html>
            <html lang="en" class="h-full">
                <head>
                    <meta charset="utf-8"/>
                    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                    <title>Todo App</title>
                    <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()}/>
                    
                    <!-- Static assets (served by Phoenix Endpoint) -->
                    <link phx-track-static rel="stylesheet" href="/assets/app.css"/>
                    <!-- Bundle that bootstraps LiveSocket and loads Haxe hooks -->
                    <script defer phx-track-static type="text/javascript" src="/assets/phoenix_app.js"></script>
                </head>
                <body class="h-full bg-gray-50 dark:bg-gray-900 font-inter antialiased">
                    <main id="main-content" class="h-full">
                        <%= @inner_content %>
                    </main>
                </body>
            </html>
        ');
    }

    /**
     * Application layout function
     * - Wraps content in a responsive container and basic page chrome.
     */
    @:keep public static function app(assigns: Dynamic): Dynamic {
        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-blue-900">
                <div class="container mx-auto px-4 py-8 max-w-6xl">
                    <%= @inner_content %>
                </div>
            </div>
        ');
    }
}
