import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const PingClientEvent = 
Register.global("$hxEnums")["shared.channels.PingClientEvent"] = 
{
	__ename__: "shared.channels.PingClientEvent",
	
	Ping: Object.assign((payload) => ({_hx_index: 0, __enum__: "shared.channels.PingClientEvent", "payload": payload}), {_hx_name: "Ping", __params__: ["payload"]})
}
PingClientEvent.__constructs__ = [PingClientEvent.Ping]
PingClientEvent.__empty_constructs__ = []

export const PingServerEvent = 
Register.global("$hxEnums")["shared.channels.PingServerEvent"] = 
{
	__ename__: "shared.channels.PingServerEvent",
	
	Pong: Object.assign((payload) => ({_hx_index: 0, __enum__: "shared.channels.PingServerEvent", "payload": payload}), {_hx_name: "Pong", __params__: ["payload"]})
}
PingServerEvent.__constructs__ = [PingServerEvent.Pong]
PingServerEvent.__empty_constructs__ = []

export const PingProtocol = Register.global("$hxClasses")["shared.channels.PingProtocol"] = 
class PingProtocol {
	static encodePingPayload(payload) {
		let out = {"request_id": payload.requestId};
		return out;
	}
	static decodePingPayload(payload) {
		let requestId = (payload != null) ? payload.request_id : null;
		if (requestId != null) {
			return {"requestId": requestId};
		} else {
			return null;
		};
	}
	static encodeSend(event) {
		let payload = event.payload;
		return {"event": "ping", "payload": PingProtocol.encodePingPayload(payload)};
	}
	static decodeRecv(eventName, payload) {
		if (eventName == "pong") {
			let decoded = PingProtocol.decodePingPayload(payload);
			if (decoded != null) {
				return PingServerEvent.Pong(decoded);
			} else {
				return null;
			};
		} else {
			return null;
		};
	}
	static get __name__() {
		return "shared.channels.PingProtocol"
	}
	get __class__() {
		return PingProtocol
	}
}

