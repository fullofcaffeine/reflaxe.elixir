package infrastructure;

import controllers.ApiController;
import reflaxe.elixir.macros.RouterDsl.*;

@:native("MyAppWeb.Router")
@:router
final routes = [
	pipeline(api, [plug(accepts, {initArgs: ["json"]})]),
	scope("/api", [pipeThrough([api]), get("/status", ApiController, ApiController.status)])
];
