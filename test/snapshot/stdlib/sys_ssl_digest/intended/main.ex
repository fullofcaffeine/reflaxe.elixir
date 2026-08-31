defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp pem(label, body) do
    lines = []
    offset = 0
    {lines, _offset} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {lines, offset}, fn _, {acc_lines, acc_offset} ->
      try do
        if (acc_offset < String.length(body)) do
          acc_lines = acc_lines ++ [StringTools.haxe_substr_non_nil_len(body, acc_offset, 64)]
          acc_offset = acc_offset + 64
          {:cont, {acc_lines, acc_offset}}
        else
          {:halt, {acc_lines, acc_offset}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_lines, acc_offset}}
        :throw, :continue ->
          {:cont, {acc_lines, acc_offset}}
      end
    end)
    "-----BEGIN #{label}-----\n#{Enum.join(lines, "\n")}\n-----END #{label}-----\n"
  end
  def main() do
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "MD5")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "900150983cd24fb0d6963f7d28e17f72", "MD5 digest should match the standard vector")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "SHA1")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "a9993e364706816aba3e25717850c26c9cd0d89d", "SHA1 digest should match the standard vector")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "SHA224")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "SHA224 digest should match the standard vector")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "SHA256")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA256 digest should match the standard vector")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "SHA384")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7", "SHA384 digest should match the standard vector")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "SHA512")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f", "SHA512 digest should match the standard vector")
    assert_that((fn ->
      reflaxe_dispatch_receiver = Digest.make(Bytes.of_string("abc", {:utf8}), "RIPEMD160")
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_hex, [reflaxe_dispatch_receiver])
    end).() == "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc", "RIPEMD160 digest should match the standard vector")
    private_body = "MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAECgYBRsvGnqjxhMhnfo/BfKchjZUvHuiOdVrZQ0DmCBaxJkoXHySdVTVWsDYVfbEIdR3SNmdXa6But4UXyya6uOPN03ZZFAGIPVzPOGMMw92r4ti8cZtPYqWQxWeMwVbxH7doXtsytn2nGifLWkb2xYOr9ZSax9TMLJF8nFfgD4YltSQJBAOPMeT6AXxp25p2AeV/c6+/txx/UMoXgu/M2pwN0ixLU+ENpgiV5gAqhl/wqdo1tTswenO8CFk+mvxtxpCEjcd8CQQDhrLwb1xGxHyexHekpebkk/U9sB1uH26Rmzhz57wSLBMQ7+D//CVZPQfNdow06Pid7SuWrAwFEq7ObhrI7jl0FAkEArlNnIY6JuS3us++CcvsUz2qurMvt0gg2rRxQ2VMRrtquFqCiiV0ewIQDVGWGjhptZ8WxoTJ+snvP2gewa++9DwJAR19xEsD/SGxZCkwybLqhkpBGqRzeluYhZZ40TduJLUpxoaHO46MZV/G8vVWPHmd/5x916ZMGuKgxIrQD9I/+3QJBAIUwCoU84cF5L024f2SaxDQIvGmdkvKeHJTnzfXso/xhm4M0mdSbKKU1e4/tBhYkf5JDV1+eOMALiBRbVQx6Sfs="
    public_body = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQAB"
    private_der = Haxe.Crypto.Base64.decode(private_body, nil)
    public_der = Haxe.Crypto.Base64.decode(public_body, nil)
    private_key = Key.read_der(private_der, false)
    public_key = Key.read_der(public_der, true)
    pkcs1_private_key = Key.read_der(Haxe.Crypto.Base64.decode("MIICXQIBAAKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQABAoGAUbLxp6o8YTIZ36PwXynIY2VLx7ojnVa2UNA5ggWsSZKFx8knVU1VrA2FX2xCHUd0jZnV2ugbreFF8smurjjzdN2WRQBiD1czzhjDMPdq+LYvHGbT2KlkMVnjMFW8R+3aF7bMrZ9pxony1pG9sWDq/WUmsfUzCyRfJxX4A+GJbUkCQQDjzHk+gF8aduadgHlf3Ovv7ccf1DKF4LvzNqcDdIsS1PhDaYIleYAKoZf8KnaNbU7MHpzvAhZPpr8bcaQhI3HfAkEA4ay8G9cRsR8nsR3pKXm5JP1PbAdbh9ukZs4c+e8EiwTEO/g//wlWT0HzXaMNOj4ne0rlqwMBRKuzm4ayO45dBQJBAK5TZyGOibkt7rPvgnL7FM9qrqzL7dIINq0cUNlTEa7arhagooldHsCEA1Rlho4abWfFsaEyfrJ7z9oHsGvvvQ8CQEdfcRLA/0hsWQpMMmy6oZKQRqkc3pbmIWWeNE3biS1KcaGhzuOjGVfxvL1Vjx5nf+cfdemTBrioMSK0A/SP/t0CQQCFMAqFPOHBeS9NuH9kmsQ0CLxpnZLynhyU58317KP8YZuDNJnUmyilNXuP7QYWJH+SQ1dfnjjAC4gUW1UMekn7", nil), false)
    pkcs1_public_key = Key.read_der(Haxe.Crypto.Base64.decode("MIGJAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAE=", nil), true)
    message = Bytes.of_string("signed by ordinary Haxe", {:utf8})
    signature = Digest.sign(message, private_key, "SHA256")
    assert_that(signature.length > 0, "Digest.sign should produce a signature")
    assert_that(Digest.verify(message, signature, public_key, "SHA256"), "Digest.verify should accept the signed message")
    assert_that(not Digest.verify(Bytes.of_string("changed", {:utf8}), signature, public_key, "SHA256"), "Digest.verify should reject changed data")
    pkcs1_signature = Digest.sign(message, pkcs1_private_key, "SHA256")
    assert_that(Digest.verify(message, pkcs1_signature, pkcs1_public_key, "SHA256"), "Key.readDER should decode PKCS1 public and private keys")
    private_pem = pem("PRIVATE KEY", private_body)
    public_pem = pem("PUBLIC KEY", public_body)
    encrypted_private_pem = "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIC5TBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQQpeDvIQjlTxrKxgn\n/btTRgICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEECsaOY5BCgXJdCmJ\nneDMFIcEggKA7TtMwBxUR1CO/GCtITAHK9cuCZd6OZZqoTjwEY9RpfXRNBD4NyGG\nK6ZuY/pUJP2xwXq0lqVkqJlGGrlI+OB2OP42bkCM9YtoZJR3EvSHKzEA8o9NArog\nXAiQBRp3Kh70jyraq7ckEt/qYIM1HncbQe79GSMjXTJ9tY0BIOd2thbyrBMobR/v\n0igLYrHC6r8J7i1BjmUunAir4wTwMGrhe0XqvpWXN6CDz8yKeyUkWPzetE0VUCUx\ncqLrRq2x8xpjaUS5aRajdejxx1/jT3PdD6U5Ji5s+rKJPc6W58veOZj3CLRraveT\nDxNQdGzQhfOeyfImXaic7Q4xY2Xsgft54I+VgVwo9lituF2M0tNrvsaa0I+oFISP\n7WjeTHOviguTuVZsMnLTupHd/zn+rwuoN+SNP0XLKtAmqnauJeCQHmXZt2U7Ix2Q\n0Hlmh3MqAqb3rxfNV4mlo5RyIBSIdlBVjYA+6/xBeMIilOoJGzkM41fPPKXsWLLH\nOV1CY6YQ9VkWsZfddxSy0b1fyQRMs+Utz4mOBnbqerHJPuNIW8WKnXsEHUYAMwPr\nAh9Pyl2bMit8+UC1NfUec4A++PaKn37iHLBWBJkeGMssK2IcyQx+RtnIF6Oiv9LU\no9rtn5dd/GAsNbMd8F0uMdXPl5aJj1tBx2rYdUx1IYNXulDprQxh5AdG/S5e/aBI\nZWTaUW5VgGtVz+rHmuMi5f04m6/QPckRYEXDwPkDzrUI2TdVf4JJWfhIqpsvEJav\nxekP2PgIJZUoyceyKeYi5eq+slJCQ4avCELSiVPXHh/AWliXmPIQDfyLlIlrtIad\nkE+7MKp4FO/19vVes9zEuNIKp6BUaw8W6g==\n-----END ENCRYPTED PRIVATE KEY-----\n"
    pem_private_key = Key.read_pem(private_pem, false, nil)
    pem_public_key = Key.read_pem(public_pem, true, nil)
    pem_signature = Digest.sign(message, pem_private_key, "SHA256")
    assert_that(Digest.verify(message, pem_signature, pem_public_key, "SHA256"), "Key.readPEM should decode public and private keys")
    encrypted_private_key = Key.read_pem(encrypted_private_pem, false, "haxe-test-pass")
    encrypted_signature = Digest.sign(message, encrypted_private_key, "SHA256")
    assert_that(Digest.verify(message, encrypted_signature, pem_public_key, "SHA256"), "Key.readPEM should decode an encrypted private key with its passphrase")
    private_path = "sys_ssl_key_private.pem"
    public_path = "sys_ssl_key_public.der"
    encrypted_path = "sys_ssl_key_private_encrypted.pem"
    Sys.IO.File.save_content(private_path, private_pem)
    Sys.IO.File.save_bytes(public_path, public_der)
    Sys.IO.File.save_content(encrypted_path, encrypted_private_pem)
    file_private_key = Key.load_file(private_path, nil, nil)
    file_public_key = Key.load_file(public_path, true, nil)
    file_encrypted_key = Key.load_file(encrypted_path, false, "haxe-test-pass")
    file_signature = Digest.sign(message, file_private_key, "SHA256")
    assert_that(Digest.verify(message, file_signature, file_public_key, "SHA256"), "Key.loadFile should detect PEM and DER files")
    file_encrypted_signature = Digest.sign(message, file_encrypted_key, "SHA256")
    assert_that(Digest.verify(message, file_encrypted_signature, file_public_key, "SHA256"), "Key.loadFile should pass a private-key passphrase")
    FileSystem.delete_file(private_path)
    FileSystem.delete_file(public_path)
    FileSystem.delete_file(encrypted_path)
  end
end
