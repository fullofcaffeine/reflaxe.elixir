package client.extern;

import js.html.Element;

/**
 * Phoenix LiveView JavaScript API extern definitions
 * Provides type-safe interfaces for Phoenix LiveView hooks
 */

/**
 * Phoenix LiveView Hook interface
 * All hooks must implement these methods
 */
interface LiveViewHook {
    /**
     * Element that the hook is attached to
     */
    var el: Element;
}

// Also fix the closing brace to be on its own line

/**
 * Phoenix LiveView Socket extern
 */
extern class LiveSocket {
    public function new(url: String, socket: Dynamic, ?options: Dynamic);
    public function connect(): Void;
    public function disconnect(): Void;
    public function isConnected(): Bool;
    public function pushEvent(event: String, payload: Dynamic): Void;
    public var hooks: Dynamic;
}

/**
 * Phoenix Socket extern
 */
extern class Socket {
    public function new(url: String, ?options: Dynamic);
    public function connect(): Void;
    public function disconnect(): Void;
    public function isConnected(): Bool;
}

/**
 * Phoenix Channel extern
 */
extern class Channel {
    public function new(topic: String, payload: Dynamic, socket: Socket);
    public function join(): Dynamic;
    public function leave(): Dynamic;
    public function push(event: String, payload: Dynamic): Dynamic;
    public function on(event: String, callback: Dynamic -> Void): Void;
}

/**
 * LiveView test utilities (for testing)
 */
extern class LiveViewTest {
    public static function live(conn: Dynamic, path: String): Dynamic;
    public static function render_click(view: Dynamic, selector: String): String;
    public static function render_submit(form: Dynamic): String;
    public static function form(view: Dynamic, selector: String, params: Dynamic): Dynamic;
    public static function element(view: Dynamic, selector: String): Dynamic;
    public static function has_element(view: Dynamic, selector: String): Bool;
}