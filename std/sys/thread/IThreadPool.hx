package sys.thread;

interface IThreadPool {
	var threadsCount(get, never):Int;
	var isShutdown(get, never):Bool;
	function run(task:() -> Void):Void;
	function shutdown():Void;
}
