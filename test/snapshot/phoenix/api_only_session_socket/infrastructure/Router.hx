package infrastructure;

import reflaxe.elixir.macros.RouterDsl.*;

@:native("MyApp.Router")
@:router
final routes = [pipeline(api, [plug(accepts, {initArgs: ["json"]})])];
