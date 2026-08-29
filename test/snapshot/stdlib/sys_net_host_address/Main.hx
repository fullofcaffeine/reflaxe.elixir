import sys.net.Address;
import sys.net.Host;

class Main {
	public static function main() {
		var host = new Host("127.0.0.1");
		if (host.host != "127.0.0.1") {
			throw "Host.host should preserve its input";
		}
		if (host.ip != 2130706433) {
			throw "Host.ip should use signed 32-bit IPv4 values";
		}
		if (host.toString() != "127.0.0.1") {
			throw "Host.toString should preserve IPv4 loopback";
		}
		if (host.reverse().length == 0) {
			throw "Host.reverse should return a local name";
		}

		var highHost = new Host("255.255.255.255");
		if (highHost.ip != -1 || highHost.toString() != "255.255.255.255") {
			throw "Host should preserve the signed high IPv4 range";
		}

		var address = new Address();
		address.host = host.ip;
		address.port = 4001;

		var cloned = address.clone();
		if (address.compare(cloned) != 0) {
			throw "Address.clone should preserve host and port";
		}

		var reconstructed = address.getHost();
		if (reconstructed.toString() != "127.0.0.1") {
			throw "Address.getHost should reconstruct Host from integer IPv4";
		}

		var localName = Host.localhost();
		if (localName == null || localName.length == 0) {
			throw "Host.localhost should return a hostname";
		}
	}
}
