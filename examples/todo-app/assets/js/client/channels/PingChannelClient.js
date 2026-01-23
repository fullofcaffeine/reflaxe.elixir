import {PingProtocol, PingClientEvent} from "../../shared/channels/PingProtocol.js"
import {TypedChannelClient} from "../../phoenix/channels/TypedChannelClient.js"
import {Socket} from "phoenix"
import {Register} from "../../genes/Register.js"
import {StringTools} from "../../StringTools.js"

const $global = Register.$global

export const PingChannelClient = Register.global("$hxClasses")["client.channels.PingChannelClient"] = 
class PingChannelClient {
	static readCsrfToken() {
		let meta = window.document.querySelector("meta[name='csrf-token']");
		if (meta == null) {
			return null;
		} else {
			return meta.getAttribute("content");
		};
	}
	static bootstrap() {
		let csrf = PingChannelClient.readCsrfToken();
		let params = {};
		if (csrf != null && StringTools.trim(csrf) != "") {
			params["_csrf_token"] = csrf;
		};
		let socket = new Socket("/socket", {"params": params});
		socket.connect();
		let channel = socket.channel("typed:lobby", {});
		let protocol = PingProtocol.clientProtocol();
		let client = new TypedChannelClient(channel, protocol.encodeSend, protocol.decodeRecv, protocol.eventNames);
		client.onMessage(function (message) {
			let payload = message.payload;
			window.__typed_channel_last_pong = payload.requestId;
		});
		client.join().receive("ok", function (_resp) {
			let requestId = "ping_" + new Date().getTime();
			client.push(PingClientEvent.Ping({"requestId": requestId}));
			window.__typed_channel_ready = true;
		});
	}
	static get __name__() {
		return "client.channels.PingChannelClient"
	}
	get __class__() {
		return PingChannelClient
	}
}

