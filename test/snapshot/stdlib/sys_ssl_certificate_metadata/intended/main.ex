defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp leaf_certificate_pem() do
    "-----BEGIN CERTIFICATE-----\nMIIDkjCCAnqgAwIBAgIUZ64+bFTy8FCv3/YLmULejl7ZiwcwDQYJKoZIhvcNAQEL\nBQAwQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEYMBYG\nA1UEAwwPUmVmbGF4ZSBSb290IENBMB4XDTI2MDgzMTA1MzIzNVoXDTI3MDgzMTA1\nMzIzNVowVjELMAkGA1UEBhMCTVgxHTAbBgNVBAoMFFJlZmxheGUgRWxpeGlyIFRl\nc3RzMREwDwYDVQQLDAhDb21waWxlcjEVMBMGA1UEAwwMZXhhbXBsZS50ZXN0MIIB\nIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0AS+3gZjXa5Qxon9ix+SnLsa\nGjwtS7n27GDkaUMWJLj/HSJgjAWbuZEgGRacU3SMcpxxj6kbnB/VLyvh6ZFdmEnX\nmSm18UiO5WUTpJxWIh8eGtCG6kBDmwjsxafi0SDpq/hY6bfe7rw3XFAdbFUQTBlN\nGJS8cXJUO8LMUII51VTO6HafyanooFVmJqvIcP9Jc0WpkC+Pf4kTdCUD0gvgbsQn\nH4Qmn9D1MMGsI7cHv1TuBTaiJWDpTXvf6cWDlh/nBWC9pUbd2d7qSYUJe/J592/u\n1kGvE7bD37GD1AlGR8iuLeSKbCW3+vZJshAMmOpVSMeCf89eRp0P+apiySMMjwID\nAQABo20wazApBgNVHREEIjAgggxleGFtcGxlLnRlc3SCEHd3dy5leGFtcGxlLnRl\nc3QwHQYDVR0OBBYEFGzQHNO8KrFXIT9mdw2lGchbIAUbMB8GA1UdIwQYMBaAFK34\nyu1WVEKTMPYsMvVtQFeGgRa2MA0GCSqGSIb3DQEBCwUAA4IBAQCJJhxUUiNknNEW\n0V1pEIqMpyDOkraG6Lpo0kDTiMf3kKJJJoCtusKxYNu/4uJ+6qHgyZvbAT1K4yaB\nlSGVl09m2QhV16SCUFBwqObhWG190z0gAkglyhfEn66O92KuOUWielG6kYsxdv96\nVsrQ3JEQujOeCVpT+Z+61h3f/YlkxAaHqOGlNQpo/QKFjAxMDqPvbIfDGU0zV+AG\nZw7zG0+treqoNzK7BIG1UzPqjXT41zyOve4Q5JTvmtPoWo3YvnqF+FqqkfQaAYU7\npsIh5pUBw5vK2ghmhq9E/wb4MAZpswzD+4VeSEwsbUjfU3DWexKbvLA5O1wKukfH\npGsqGJGl\n-----END CERTIFICATE-----\n"
  end
  defp root_certificate_pem() do
    "-----BEGIN CERTIFICATE-----\nMIIDYzCCAkugAwIBAgIUa46EOG9aPLgRJKLPoew3RJvehBEwDQYJKoZIhvcNAQEL\nBQAwQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEYMBYG\nA1UEAwwPUmVmbGF4ZSBSb290IENBMB4XDTI2MDgzMTA1MzIzNVoXDTM2MDgyODA1\nMzIzNVowQTELMAkGA1UEBhMCTVgxGDAWBgNVBAoMD1JlZmxheGUgVGVzdCBDQTEY\nMBYGA1UEAwwPUmVmbGF4ZSBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A\nMIIBCgKCAQEAoxaBDD23jYSmqMzqfiotTC9JwGF+3BN65zHxVVKuAdmRP4D++OI2\nDT7U07WIUkwfp6aeXTsOv2qiuXSzv+Nr6sVbxgApGlMLAtslBOGXldUpXbrhsnc+\ncwAbav+jEtnxtBSM6UOUGtax34P2Tl7bHXJhv+Kj49xKpLxIJjuO1PhfF3nDJrPt\nZsFedMbyYp9yAVz87UhB+T8YVQ2806NibaoZA7JeOLlze48dOh4rDi2kF4tB9yyz\nnThgobWhCzpT+WgNJls2h5xuCfBOPhk7y0AWpiRtd72OzVPw7Y4tkaYy+w/yTsGQ\nUCBWXRr9JwlTOUw64HJq+9m5jvmfrSqpHQIDAQABo1MwUTAdBgNVHQ4EFgQUrfjK\n7VZUQpMw9iwy9W1AV4aBFrYwHwYDVR0jBBgwFoAUrfjK7VZUQpMw9iwy9W1AV4aB\nFrYwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAHGq3hWpw7n8O\nCsmjV0vyjUDthhgNCGvvBzYZ4qRai9TGLkZucdOct8cXBsDNIF5MLvGP46hd4L4r\nSKLj1RNew2Gv9hG9fdaWsRFfMX04jtYgZhsZSjwsmGkztVPqwXr0Wl/A/JCI4wjw\nDR70HMad+sxJRNpHZ2i/Awbu7loLxxI/Ih2PdW0asX807kOqjR/7figPlGASPnFB\n59HAvgKUDENIqE70sEPdN75qhrsxL/hc4orThdw8aujZlRYzrxxVOkkPwAni+z0Y\n62CGAKaux3VRJ3Kij+Nx+2vH16G/4iDkSRQvyOlye0mcVAnmi96zx8d7/69v/iXb\n2FeXHBnJuQ==\n-----END CERTIFICATE-----\n"
  end
  def main() do
    cert = Certificate.from_string(leaf_certificate_pem())
    assert_that(apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :subject, [cert, "CN"]) == "example.test", "Certificate.subject should read the common name")
    assert_that(apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :subject, [cert, "O"]) == "Reflaxe Elixir Tests", "Certificate.subject should read the organization")
    assert_that(apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :subject, [cert, "2.5.4.11"]) == "Compiler", "Certificate.subject should accept a dotted OID")
    assert_that(Kernel.is_nil(apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :subject, [cert, "missing-field"])), "Certificate.subject should return null for an unknown field")
    assert_that(apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :issuer, [cert, "CN"]) == "Reflaxe Root CA", "Certificate.issuer should read the common name")
    assert_that(Certificate.get_common_name(cert) == "example.test", "Certificate.commonName should use the subject CN")
    assert_that(Enum.join(Certificate.get_alt_names(cert), ",") == "example.test,www.example.test", "Certificate.altNames should read DNS names")
    assert_that((fn ->
      this1 = Certificate.get_not_before(cert)
      this1.year
    end).() == 2026 and (fn ->
      this1 = Certificate.get_not_before(cert)
      (this1.month - 1)
    end).() == 7 and (fn ->
      this1 = Certificate.get_not_before(cert)
      this1.day
    end).() == 31 and (fn ->
      this1 = Certificate.get_not_before(cert)
      this1.hour
    end).() == 5, "Certificate.notBefore should read the UTC validity start")
    assert_that((fn ->
      this1 = Certificate.get_not_after(cert)
      this1.year
    end).() == 2027 and (fn ->
      this1 = Certificate.get_not_after(cert)
      (this1.month - 1)
    end).() == 7 and (fn ->
      this1 = Certificate.get_not_after(cert)
      this1.day
    end).() == 31, "Certificate.notAfter should read the UTC validity end")
    assert_that(Kernel.is_nil(apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :next, [cert])), "Certificate.next should end a one-certificate chain")
    apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :add, [cert, root_certificate_pem()])
    root = apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :next, [cert])
    assert_that(not Kernel.is_nil(root) and Certificate.get_common_name(root) == "Reflaxe Root CA", "Certificate.add and next should expose the appended certificate")
  end
end
