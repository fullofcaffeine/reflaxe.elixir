import {Register} from "../../genes/Register.js"

const $global = Register.$global

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
export const TypedChannelClient = Register.global("$hxClasses")["phoenix.channels.TypedChannelClient"] =
class TypedChannelClient extends Register.inherits() {
	[Register.new](channel, encodeSend, decodeRecv, eventNames) {
		this.channel = channel;
		this.encodeSend = encodeSend;
		this.decodeRecv = decodeRecv;
		this.handlers = [];
		let self = this;
		let _g = 0;
		while (_g < eventNames.length) {
			let eventName = eventNames[_g];
			++_g;
			this.channel.on(eventName, function (payload) {
				let decoded = self.decodeRecv(eventName, payload);
				if (decoded == null) {
					return;
				};
				let _g = 0;
				let _g1 = self.handlers;
				while (_g < _g1.length) {
					let handler = _g1[_g];
					++_g;
					handler(decoded);
				};
			});
		};
	}
	onMessage(handler) {
		this.handlers.push(handler);
	}
	join(timeout) {
		return this.channel.join(timeout);
	}
	push(message, timeout) {
		let encoded = this.encodeSend(message);
		return this.channel.push(encoded.event, encoded.payload, timeout);
	}
	static get __name__() {
		return "phoenix.channels.TypedChannelClient"
	}
	get __class__() {
		return TypedChannelClient
	}
}
TypedChannelClient.prototype.channel = null;
TypedChannelClient.prototype.encodeSend = null;
TypedChannelClient.prototype.decodeRecv = null;
TypedChannelClient.prototype.handlers = null;

