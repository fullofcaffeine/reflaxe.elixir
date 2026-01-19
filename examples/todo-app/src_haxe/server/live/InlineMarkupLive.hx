package server.live;

	import HXX.*;
	import phoenix.Phoenix.MountResult;
	import phoenix.Phoenix.Socket;
	import phoenix.LiveSocket;
	import server.types.Types.MountParams;
	import server.types.Types.Session;

typedef InlineMarkupLiveAssigns = {
    var message: String;
}

/**
 * InlineMarkupLive
 *
 * WHAT
 * - A tiny LiveView used by the todo-app to showcase Haxe inline markup (`return <div>...</div>`).
 *
 * WHY
 * - Inline markup is TSX-like syntax sugar for authoring HEEx/HXX templates.
 * - This demo intentionally avoids LiveView events/hooks and complex interpolations so it remains
 *   representative of what inline markup is best at: ergonomic, mostly-static UI.
 *
 * HOW
 * - Enabled via `-D hxx_inline_markup` (todo-app sets this in `build-server.hxml`).
 * - The compiler rewrites markup literals into `HXX.hxx("...")` before typing, then the normal HXX
 *   pipeline converts the template into HEEx (~H).
 *
 * EXAMPLES
 * Haxe:
 *   return <div class="card"><h1>${assigns.message}</h1></div>;
 */
@:native("TodoAppWeb.InlineMarkupLive")
@:liveview
class InlineMarkupLive {
    /**
     * Router action handler (placeholder to satisfy route validation).
     */
    public static function index(): String {
        return "index";
	    }

	    public static function mount(params: MountParams, session: Session, socket: Socket<InlineMarkupLiveAssigns>): MountResult<InlineMarkupLiveAssigns> {
	        var liveSocket: LiveSocket<InlineMarkupLiveAssigns> = socket;
	        return Ok(liveSocket.merge({
	            message: "Hello from inline markup 👋"
	        }));
	    }

    public static function render(assigns: InlineMarkupLiveAssigns): String {
        return <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
            <div class="container mx-auto px-4 py-10 max-w-3xl">
                <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                    <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">Inline markup demo</h1>
                    <p class="text-gray-600 dark:text-gray-300 mb-6">
                        ${assigns.message}
                    </p>

                    <div class="flex flex-wrap items-center gap-3">
                        <a href="/todos" class="inline-flex items-center px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800">
                            Back to todos
                        </a>
                        <a href="/login" class="inline-flex items-center px-4 py-2 bg-white text-gray-900 border border-gray-300 rounded-lg hover:bg-gray-50 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">
                            Sign in
                        </a>
                    </div>
                </div>
            </div>
        </div>;
    }
}
