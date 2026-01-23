package phoenix.channels;

#if js

import phoenix.Socket.Channel;
import phoenix.Socket.Push;

typedef EncodedEvent = {
  var event: String;
  var payload: js.lib.Object;
}

/**
 * TypedChannelClient
 *
 * WHAT
 * - A small typed wrapper over Phoenix JS Channels (`phoenix` npm package).
 *
 * WHY
 * - Channels are a client/server boundary; we want a minimal type-safe layer for:
 *   - encoding typed outbound messages to `{event, payload}`
 *   - decoding inbound `{eventName, payload}` to typed messages
 * - The runtime API remains Phoenix-native (`channel.join().receive(...)`, `channel.push(...)`).
 *
 * HOW
 * - Register `channel.on(eventName, ...)` handlers for the selected event names.
 * - Each inbound payload is decoded and broadcast to all registered `onMessage` handlers.
 */
class TypedChannelClient<TSend, TRecv> {
  final channel: Channel;
  final encodeSend: TSend -> EncodedEvent;
  final decodeRecv: (String, js.lib.Object) -> Null<TRecv>;
  final handlers: Array<TRecv -> Void>;

  public function new(
    channel: Channel,
    encodeSend: TSend -> EncodedEvent,
    decodeRecv: (String, js.lib.Object) -> Null<TRecv>,
    eventNames: Array<String>
  ) {
    this.channel = channel;
    this.encodeSend = encodeSend;
    this.decodeRecv = decodeRecv;
    this.handlers = [];

    var self = this;
    for (eventName in eventNames) {
      this.channel.on(eventName, function(payload: js.lib.Object): Void {
        var decoded = self.decodeRecv(eventName, payload);
        if (decoded == null) return;
        for (handler in self.handlers) {
          handler(decoded);
        }
      });
    }
  }

  public function onMessage(handler: TRecv -> Void): Void {
    handlers.push(handler);
  }

  public function join(?timeout: Int): Push {
    return channel.join(timeout);
  }

  public function leave(?timeout: Int): Push {
    return channel.leave(timeout);
  }

  public function push(message: TSend, ?timeout: Int): Push {
    var encoded = encodeSend(message);
    return channel.push(encoded.event, encoded.payload, timeout);
  }
}

#end
