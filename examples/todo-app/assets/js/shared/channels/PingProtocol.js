import {Register} from "../../genes/Register.js"

const $global = Register.$global

export const PingClientEvent =
Register.hxEnums()["shared.channels.PingClientEvent"] =
{
	__ename__: "shared.channels.PingClientEvent",
	Ping: Object.assign((payload) => ({_hx_index: 0, __enum__: "shared.channels.PingClientEvent", "payload": payload}), {_hx_name: "Ping", __params__: ["payload"]})
}
PingClientEvent.__constructs__ = [PingClientEvent.Ping]
PingClientEvent.__empty_constructs__ = []

export const PingServerEvent =
Register.hxEnums()["shared.channels.PingServerEvent"] =
{
	__ename__: "shared.channels.PingServerEvent",
	Pong: Object.assign((payload) => ({_hx_index: 0, __enum__: "shared.channels.PingServerEvent", "payload": payload}), {_hx_name: "Pong", __params__: ["payload"]})
}
PingServerEvent.__constructs__ = [PingServerEvent.Pong]
PingServerEvent.__empty_constructs__ = []

export const PingProtocol = Register.hxClasses()["shared.channels.PingProtocol"] =
class PingProtocol {
	static encodeClientSend(event) {
		let payload = event.payload;
		return {"event": "ping", "payload": PingProtocol.pingPayloadCodec.encode(payload)};
	}
	static decodeClientRecv(eventName, payload) {
		if (eventName == "pong") {
			let decoded = PingProtocol.pingPayloadCodec.decode(payload);
			if (decoded != null) {
				return PingServerEvent.Pong(decoded);
			} else {
				return null;
			};
		} else {
			return null;
		};
	}
	static clientProtocol() {
		return {"eventNames": ["pong"], "encodeSend": PingProtocol.encodeClientSend, "decodeRecv": PingProtocol.decodeClientRecv};
	}
	static get __name__() {
		return "shared.channels.PingProtocol"
	}
	get __class__() {
		return PingProtocol
	}
}


PingProtocol.requestIdField = {"key": "request_id", "put": function (payload, value) {
	if (payload == null) {
		return payload;
	} else {
		payload["request_id"] = value;
		return payload;
	};
}, "get": function (payload) {
	if (payload == null) {
		return null;
	} else {
		return ((p,k)=>{var v=p[k]; return (typeof v==='string') ? v : null;})(payload,"request_id");
	};
}}
PingProtocol.pingPayloadCodec = (function($this) {var $r0
	let fieldA = PingProtocol.requestIdField;
	let from = function (requestId) {
		return {"requestId": requestId};
	};
	let getA = function (payload) {
		return payload.requestId;
	};
	$r0 = {"encode": function (value) {
		let payload = {};
		let fieldA1 = fieldA;
		let payload1 = getA(value);
		payload = fieldA1.put(payload, payload1);
		return payload;
	}, "decode": function (payload) {
		let a = fieldA.get(payload);
		if (a != null) {
			return from(a);
		} else {
			return null;
		};
	}}
	return $r0})(this)