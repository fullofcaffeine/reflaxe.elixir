package server.live;

@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {
    public static function index(conn: Dynamic, params: Dynamic): Dynamic {
        return conn;
    }
    
    public static function show(conn: Dynamic, params: Dynamic): Dynamic {
        return conn;
    }
    
    public static function edit(conn: Dynamic, params: Dynamic): Dynamic {
        return conn;
    }
}