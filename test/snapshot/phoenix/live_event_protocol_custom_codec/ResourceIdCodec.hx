import phoenix.channels.Payload;
import phoenix.channels.WireCodec;
import phoenix.channels.WirePayload;

class ResourceIdCodec {
	public static function codec():WireCodec<ResourceId> {
		return {
			encode: function(value:ResourceId):Payload {
				return WirePayload.putInt(WirePayload.empty(), "value", value);
			},
			decode: function(payload:Payload):Null<ResourceId> {
				var value = WirePayload.getInt(payload, "value");
				return value == null ? null : value;
			}
		};
	}
}
