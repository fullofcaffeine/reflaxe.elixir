package;

typedef DashboardAssigns = {
	var islandId:String;
	var title:String;
}

@:native("AppWeb.DashboardLive")
@:liveview
@:hxx_strict_components
class Main {
	public static function render(assigns:DashboardAssigns):String {
		return <main>
			<AppWeb.ReactComponents.status_card
				id=${assigns.islandId}
				title=${assigns.title}
			/>
		</main>;
	}

	public static function main() {}
}
