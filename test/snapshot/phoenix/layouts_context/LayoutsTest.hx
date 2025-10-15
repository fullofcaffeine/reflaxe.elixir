package;

/**
 * Phoenix Layouts context emission test
 *
 * WHAT
 * - Ensure modules named <App>Web.Layouts get `use <App>Web, :html` injected.
 * - Verify CSRF meta tag emission uses Phoenix.Controller.get_csrf_token/0.
 */
@:native("MyAppWeb.Layouts")
class LayoutsTest {
    public static function root(assigns:Dynamic):Dynamic {
        return HXX.hxx('
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()}/>
            </head>
            <body>
                <%= @inner_content %>
            </body>
            </html>
        ');
    }
}

