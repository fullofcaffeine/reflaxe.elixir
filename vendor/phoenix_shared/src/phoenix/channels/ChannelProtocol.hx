package phoenix.channels;

import phoenix.channels.EncodedEvent;
import phoenix.channels.Payload;

/**
 * ChannelProtocol (Phoenix Channels)
 *
 * WHAT
 * - Shared typed description of a channel’s wire protocol:
 *   - how to encode typed outbound messages to `{event, payload}`
 *   - how to decode inbound `{eventName, payload}` to typed messages
 *
 * WHY
 * - Channels are a client/server boundary. Keeping a single source of truth for event names
 *   and payload (de)serialization improves correctness and dev UX when sharing Haxe across
 *   JS + Elixir runtimes.
 *
 * HOW
 * - `encodeSend/1` produces wire `{event, payload}`.
 * - `decodeRecv/2` maps `(eventName, payload)` to a typed message (or null if unsupported).
 * - `eventNames` lists the event names that should be listened to (JS) or accepted (server helpers).
 */
typedef ChannelProtocol<TSend, TRecv> = {
    var eventNames: Array<String>;
    var encodeSend: TSend -> EncodedEvent;
    var decodeRecv: (String, Payload) -> Null<TRecv>;
}

