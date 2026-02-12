package infrastructure;

@:native("MyAppWeb.UserSocket")
@:socket
@:socketChannels([{topic: "typed:*", channel: channels.PingChannel}])
class UserSocket {}
