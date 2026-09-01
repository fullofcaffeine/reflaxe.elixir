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

	static function receiveUdpDatagram(host:Host):Void {
		var receiver = new UdpSocket();
		receiver.bind(host, 0);
		var receiverEndpoint = receiver.host();
		if (receiverEndpoint == null || receiverEndpoint.port <= 0) {
			throw "UdpSocket.host should expose the bound receiver port";
		}

		receiver.setBlocking(false);
		try {
			receiver.readFrom(Bytes.alloc(16), 0, 16, new Address());
			throw "UdpSocket.readFrom should block when no datagram is ready";
		} catch (error:haxe.io.Error) {
			switch (error) {
				case Blocked:
				default:
					throw "UdpSocket.readFrom should raise Error.Blocked without data";
			}
		}
		receiver.setBlocking(true);
		receiver.setTimeout(0.25);

		var sender = new UdpSocket();
		var senderEndpoint = sender.host();
		var destination = new Address();
		destination.host = host.ip;
		destination.port = receiverEndpoint.port;
		var payload = Bytes.ofString("hello!");
		if (sender.sendTo(payload, 0, payload.length, destination) != payload.length) {
			throw "UdpSocket.sendTo should send the complete datagram";
		}

		var buffer = Bytes.ofString("________");
		var source = new Address();
		var received = receiver.readFrom(buffer, 2, 5, source);
		if (received != 5 || buffer.toString() != "__hello_") {
			throw "UdpSocket.readFrom should truncate and mutate only the requested buffer range";
		}
		if (source.host != host.ip || source.port != senderEndpoint.port) {
			throw "UdpSocket.readFrom should report the sender address";
		}

		sender.close();
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

		receiveUdpDatagram(host);
	}
}
