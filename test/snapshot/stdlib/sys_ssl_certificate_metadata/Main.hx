import sys.ssl.Certificate;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function leafCertificatePem():String {
		return "-----BEGIN CERTIFICATE-----\n"
			+ "MIIDkjCCAnqgAwIBAgIUZ64+bFTy8FCv3/YLmULejl7ZiwcwDQYJKoZIhvcNAQEL\n"
			+ "BQAwQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEYMBYG\n"
			+ "A1UEAwwPUmVmbGF4ZSBSb290IENBMB4XDTI2MDgzMTA1MzIzNVoXDTI3MDgzMTA1\n"
			+ "MzIzNVowVjELMAkGA1UEBhMCTVgxHTAbBgNVBAoMFFJlZmxheGUgRWxpeGlyIFRl\n"
			+ "c3RzMREwDwYDVQQLDAhDb21waWxlcjEVMBMGA1UEAwwMZXhhbXBsZS50ZXN0MIIB\n"
			+ "IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0AS+3gZjXa5Qxon9ix+SnLsa\n"
			+ "GjwtS7n27GDkaUMWJLj/HSJgjAWbuZEgGRacU3SMcpxxj6kbnB/VLyvh6ZFdmEnX\n"
			+ "mSm18UiO5WUTpJxWIh8eGtCG6kBDmwjsxafi0SDpq/hY6bfe7rw3XFAdbFUQTBlN\n"
			+ "GJS8cXJUO8LMUII51VTO6HafyanooFVmJqvIcP9Jc0WpkC+Pf4kTdCUD0gvgbsQn\n"
			+ "H4Qmn9D1MMGsI7cHv1TuBTaiJWDpTXvf6cWDlh/nBWC9pUbd2d7qSYUJe/J592/u\n"
			+ "1kGvE7bD37GD1AlGR8iuLeSKbCW3+vZJshAMmOpVSMeCf89eRp0P+apiySMMjwID\n"
			+ "AQABo20wazApBgNVHREEIjAgggxleGFtcGxlLnRlc3SCEHd3dy5leGFtcGxlLnRl\n"
			+ "c3QwHQYDVR0OBBYEFGzQHNO8KrFXIT9mdw2lGchbIAUbMB8GA1UdIwQYMBaAFK34\n"
			+ "yu1WVEKTMPYsMvVtQFeGgRa2MA0GCSqGSIb3DQEBCwUAA4IBAQCJJhxUUiNknNEW\n"
			+ "0V1pEIqMpyDOkraG6Lpo0kDTiMf3kKJJJoCtusKxYNu/4uJ+6qHgyZvbAT1K4yaB\n"
			+ "lSGVl09m2QhV16SCUFBwqObhWG190z0gAkglyhfEn66O92KuOUWielG6kYsxdv96\n"
			+ "VsrQ3JEQujOeCVpT+Z+61h3f/YlkxAaHqOGlNQpo/QKFjAxMDqPvbIfDGU0zV+AG\n"
			+ "Zw7zG0+treqoNzK7BIG1UzPqjXT41zyOve4Q5JTvmtPoWo3YvnqF+FqqkfQaAYU7\n"
			+ "psIh5pUBw5vK2ghmhq9E/wb4MAZpswzD+4VeSEwsbUjfU3DWexKbvLA5O1wKukfH\n"
			+ "pGsqGJGl\n"
			+ "-----END CERTIFICATE-----\n";
	}

	static function rootCertificatePem():String {
		return "-----BEGIN CERTIFICATE-----\n"
			+ "MIIDYzCCAkugAwIBAgIUa46EOG9aPLgRJKLPoew3RJvehBEwDQYJKoZIhvcNAQEL\n"
			+ "BQAwQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEYMBYG\n"
			+ "A1UEAwwPUmVmbGF4ZSBSb290IENBMB4XDTI2MDgzMTA1MzIzNVoXDTM2MDgyODA1\n"
			+ "MzIzNVowQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEY\n"
			+ "MBYGA1UEAwwPUmVmbGF4ZSBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A\n"
			+ "MIIBCgKCAQEAoxaBDD23jYSmqMzqfiotTC9JwGF+3BN65zHxVVKuAdmRP4D++OI2\n"
			+ "DT7U07WIUkwfp6aeXTsOv2qiuXSzv+Nr6sVbxgApGlMLAtslBOGXldUpXbrhsnc+\n"
			+ "cwAbav+jEtnxtBSM6UOUGtax34P2Tl7bHXJhv+Kj49xKpLxIJjuO1PhfF3nDJrPt\n"
			+ "ZsFedMbyYp9yAVz87UhB+T8YVQ2806NibaoZA7JeOLlze48dOh4rDi2kF4tB9yyz\n"
			+ "nThgobWhCzpT+WgNJls2h5xuCfBOPhk7y0AWpiRtd72OzVPw7Y4tkaYy+w/yTsGQ\n"
			+ "UCBWXRr9JwlTOUw64HJq+9m5jvmfrSqpHQIDAQABo1MwUTAdBgNVHQ4EFgQUrfjK\n"
			+ "7VZUQpMw9iwy9W1AV4aBFrYwHwYDVR0jBBgwFoAUrfjK7VZUQpMw9iwy9W1AV4aB\n"
			+ "FrYwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAHGq3hWpw7n8O\n"
			+ "CsmjV0vyjUDthhgNCGvvBzYZ4qRai9TGLkZucdOct8cXBsDNIF5MLvGP46hd4L4r\n"
			+ "SKLj1RNew2Gv9hG9fdaWsRFfMX04jtYgZhsZSjwsmGkztVPqwXr0Wl/A/JCI4wjw\n"
			+ "DR70HMad+sxJRNpHZ2i/Awbu7loLxxI/Ih2PdW0asX807kOqjR/7figPlGASPnFB\n"
			+ "59HAvgKUDENIqE70sEPdN75qhrsxL/hc4orThdw8aujZlRYzrxxVOkkPwAni+z0Y\n"
			+ "62CGAKaux3VRJ3Kij+Nx+2vH16G/4iDkSRQvyOlye0mcVAnmi96zx8d7/69v/iXb\n"
			+ "2FeXHBnJuQ==\n"
			+ "-----END CERTIFICATE-----\n";
	}

	public static function main() {
		var cert = Certificate.fromString(leafCertificatePem());
		assertThat(cert.subject("CN") == "example.test", "Certificate.subject should read the common name");
		assertThat(cert.subject("O") == "Reflaxe Elixir Tests", "Certificate.subject should read the organization");
		assertThat(cert.subject("2.5.4.11") == "Compiler", "Certificate.subject should accept a dotted OID");
		assertThat(cert.subject("missing-field") == null, "Certificate.subject should return null for an unknown field");
		assertThat(cert.issuer("CN") == "Reflaxe Root CA", "Certificate.issuer should read the common name");
		assertThat(cert.commonName == "example.test", "Certificate.commonName should use the subject CN");
		assertThat(cert.altNames.join(",") == "example.test,www.example.test", "Certificate.altNames should read DNS names");
		assertThat(cert.notBefore.getUTCFullYear() == 2026
			&& cert.notBefore.getUTCMonth() == 7
			&& cert.notBefore.getUTCDate() == 31
			&& cert.notBefore.getUTCHours() == 5,
			"Certificate.notBefore should read the UTC validity start");
		assertThat(cert.notAfter.getUTCFullYear() == 2027 && cert.notAfter.getUTCMonth() == 7 && cert.notAfter.getUTCDate() == 31,
			"Certificate.notAfter should read the UTC validity end");
		assertThat(cert.next() == null, "Certificate.next should end a one-certificate chain");
		cert.add(rootCertificatePem());
		var root = cert.next();
		assertThat(root != null && root.commonName == "Reflaxe Root CA", "Certificate.add and next should expose the appended certificate");
	}
}
