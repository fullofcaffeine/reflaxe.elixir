defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
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
    private_der = Haxe.Crypto.Base64.decode("MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMjQa1RTzP4JTemH9uOrATsOABsYGkOihKqe4r9FBuB8lJy4wmSIQIjA4o/TAPcdWYEJLujZ0jiFw5HjdbOgp+TS5bzfSDNeV/7uZaN09EpIlND0km+ZvauKU/qGSlq0eyZIrWRbmQGcreM1W9OhYhxnAFkTLdCImgfETDQUwTxbAgMBAAECgYBRsvGnqjxhMhnfo/BfKchjZUvHuiOdVrZQ0DmCBaxJkoXHySdVTVWsDYVfbEIdR3SNmdXa6But4UXyya6uOPN03ZZFAGIPVzPOGMMw92r4ti8cZtPYqWQxWeMwVbxH7doXtsytn2nGifLWkb2xYOr9ZSax9TMLJF8nFfgD4YltSQJBAOPMeT6AXxp25p2AeV/c6+/txx/UMoXgu/M2pwN0ixLU+ENpgiV5gAqhl/wqdo1tTswenO8CFk+mvxtxpCEjcd8CQQDhrLwb1xGxHyexHekpebkk/U9sB1uH26Rmzhz57wSLBMQ7+D//CVZPQfNdow06Pid7SuWrAwFEq7ObhrI7jl0FAkEArlNnIY6JuS3us++CcvsUz2qurMvt0gg2rRxQ2VMRrtquFqCiiV0ewIQDVGWGjhptZ8WxoTJ+snvP2gewa++9DwJAR19xEsD/SGxZCkwybLqhkpBGqRzeluYhZZ40TduJLUpxoaHO46MZV/G8vVWPHmd/5x916ZMGuKgxIrQD9I/+3QJBAIUwCoU84cF5L024f2SaxDQIvGmdkvKeHJTnzfXso/xhm4M0mdSbKKU1e4/tBhYkf5JDV1+eOMALiBRbVQx6Sfs=", nil)
    public_der = Haxe.Crypto.Base64.decode("MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDI0GtUU8z+CU3ph/bjqwE7DgAbGBpDooSqnuK/RQbgfJScuMJkiECIwOKP0wD3HVmBCS7o2dI4hcOR43WzoKfk0uW830gzXlf+7mWjdPRKSJTQ9JJvmb2rilP6hkpatHsmSK1kW5kBnK3jNVvToWIcZwBZEy3QiJoHxEw0FME8WwIDAQAB", nil)
    private_key = Key.read_der(private_der, false)
    public_key = Key.read_der(public_der, true)
    message = Bytes.of_string("signed by ordinary Haxe", {:utf8})
    signature = Digest.sign(message, private_key, "SHA256")
    assert_that(signature.length > 0, "Digest.sign should produce a signature")
    assert_that(Digest.verify(message, signature, public_key, "SHA256"), "Digest.verify should accept the signed message")
    assert_that(not Digest.verify(Bytes.of_string("changed", {:utf8}), signature, public_key, "SHA256"), "Digest.verify should reject changed data")
  end
end
