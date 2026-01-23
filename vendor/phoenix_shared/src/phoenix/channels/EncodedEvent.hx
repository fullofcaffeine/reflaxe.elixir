package phoenix.channels;

import phoenix.channels.Payload;

/**
 * EncodedEvent (Phoenix Channels)
 *
 * WHAT
 * - Normalized wire representation `{event, payload}` shared by client and server helpers.
 *
 * WHY
 * - Protocol encode functions should have a single, target-appropriate return type.
 *
 * HOW
 * - `payload` resolves to `js.lib.Object` on JS and `elixir.types.Term` on Elixir.
 */
typedef EncodedEvent = {
    var event: String;
    var payload: Payload;
}

