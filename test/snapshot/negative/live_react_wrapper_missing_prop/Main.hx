package;

@:liveview
@:hxx_strict_components
class Main {
	public static function render(assigns:{}):String {
		// The app-local wrapper requires `title` even though stock LiveReact props are open.
		return <main>
			<AppWeb.ReactComponents.status_card id="status-card" />
		</main>;
	}

	public static function main() {}
}
