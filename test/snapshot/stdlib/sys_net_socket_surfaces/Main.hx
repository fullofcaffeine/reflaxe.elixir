import haxe.io.Bytes;
import sys.net.Address;
import sys.net.Host;
import sys.net.Socket;
import sys.net.UdpSocket;

class Main {
	static function configureTcp(socket:Socket, host:Host):Void {
		socket.setTimeout(0.01);
		socket.setBlocking(false);
		socket.setFastSend(true);
		socket.bind(host, 0);
		socket.listen(1);

		var endpoint = socket.host();
		if (endpoint != null && endpoint.port < 0) {
			throw "Socket.host returned an invalid port";
		}
	}

	static function configureUdp(socket:UdpSocket, host:Host):Void {
		socket.setTimeout(0.01);
		socket.setBroadcast(false);
		socket.bind(host, 0);

		var destination = new Address();
		destination.host = host.ip;
		destination.port = 9;

		var bytes = Bytes.ofString("ping");
		var sent = socket.sendTo(bytes, 0, bytes.length, destination);
		if (sent != bytes.length) {
			throw "UdpSocket.sendTo should report the sent length";
		}
	}

	static function rejectUnsupportedUdpRead(host:Host):Void {
		var receiver = new UdpSocket();
		receiver.bind(host, 0);
		try {
			receiver.readFrom(Bytes.alloc(16), 0, 16, new Address());
			throw "UdpSocket.readFrom should fail explicitly on the Elixir target";
		} catch (error:haxe.io.Error) {
			switch (error) {
				case Custom(message):
					if (message == "") {
						throw "UdpSocket.readFrom should explain the unsupported API";
					}
				default:
					throw "UdpSocket.readFrom should raise Error.Custom";
			}
		}
		receiver.close();
	}

	public static function main() {
		var host = new Host("127.0.0.1");

		var tcp = new Socket();
		configureTcp(tcp, host);
		tcp.close();

		var udp = new UdpSocket();
		configureUdp(udp, host);
		udp.close();

		rejectUnsupportedUdpRead(host);
	}
}
