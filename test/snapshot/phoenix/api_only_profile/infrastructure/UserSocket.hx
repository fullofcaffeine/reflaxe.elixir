package infrastructure;

@:native("MyAppWeb.UserSocket")
@:socket
@:socketChannels([{topic: "api:*", channel: channels.ApiChannel}])
class UserSocket {}
