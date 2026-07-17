package;

@:liveview
@:hxx_strict_components
class Main {
	public static function render(assigns:{}):String {
		// The app-local wrapper requires a String title.
		return <main>
			<AppWeb.ReactComponents.status_card
				id="status-card"
				title=${42}
			/>
		</main>;
	}

	public static function main() {}
}
