import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Socket;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function rejectUnsupportedCertificateMetadata(cert:Certificate):Void {
		try {
			cert.subject("CN");
			throw "Certificate.subject should fail explicitly on the Elixir target";
		} catch (error:haxe.io.Error) {
			switch (error) {
				case Custom(message):
					assertThat(message != "", "Certificate.subject should explain unsupported status");
				default:
					throw "Certificate.subject should raise Error.Custom";
			}
		}
	}

	public static function main() {
		var cert = Certificate.loadDefaults();
		rejectUnsupportedCertificateMetadata(cert);

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
