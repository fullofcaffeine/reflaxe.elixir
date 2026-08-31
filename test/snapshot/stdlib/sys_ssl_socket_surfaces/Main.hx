import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Socket;

class Main {
	public static function main() {
		var cert = Certificate.loadDefaults();

		var socket = new Socket();
		socket.verifyCert = false;
		socket.setTimeout(0.01);
		socket.setBlocking(false);
		socket.setHostname("localhost");
		socket.setCA(cert);
		socket.bind(new Host("127.0.0.1"), 0);
		socket.close();
	}
}
