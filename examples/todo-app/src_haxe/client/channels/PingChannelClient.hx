package client.channels;

#if js

import phoenix.Socket;
import phoenix.channels.TypedChannelClient;
import shared.channels.PingProtocol;
import shared.channels.PingProtocol.PingClientEvent;
import shared.channels.PingProtocol.PingServerEvent;
import Date;
import StringTools;

class PingChannelClient {
    static function readCsrfToken(): Null<String> {
        var meta = js.Browser.document.querySelector("meta[name='csrf-token']");
        return meta == null ? null : meta.getAttribute("content");
    }

    public static function bootstrap(): Void {
        var csrf = readCsrfToken();
        var params: js.lib.Object = cast {};
        if (csrf != null && StringTools.trim(csrf) != "") {
            Reflect.setField(cast params, "_csrf_token", csrf);
        }

        var socket = new Socket("/socket", {params: cast params});
        socket.connect();

        var channel = socket.channel(PingProtocol.Topic, cast {});
        var client = new TypedChannelClient<PingClientEvent, PingServerEvent>(
            channel,
            PingProtocol.encodeSend,
            PingProtocol.decodeRecv,
            [PingProtocol.EventPong]
        );

        client.onMessage(function(message: PingServerEvent): Void {
            switch (message) {
                case Pong(payload):
                    js.Syntax.code("window.__typed_channel_last_pong = {0}", payload.requestId);
            }
        });

        client.join().receive("ok", function(_resp): Void {
            var requestId = 'ping_${Date.now().getTime()}';
            client.push(Ping({requestId: requestId}));
            js.Syntax.code("window.__typed_channel_ready = true");
        });
    }
}

#end
