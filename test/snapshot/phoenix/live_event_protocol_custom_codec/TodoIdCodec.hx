import phoenix.channels.Payload;
import phoenix.channels.WireCodec;
import phoenix.channels.WirePayload;

class TodoIdCodec {
	public static function codec():WireCodec<TodoId> {
		return {
			encode: function(value:TodoId):Payload {
				return WirePayload.putInt(WirePayload.empty(), "value", value);
			},
			decode: function(payload:Payload):Null<TodoId> {
				var value = WirePayload.getInt(payload, "value");
				return value == null ? null : value;
			}
		};
	}
}
