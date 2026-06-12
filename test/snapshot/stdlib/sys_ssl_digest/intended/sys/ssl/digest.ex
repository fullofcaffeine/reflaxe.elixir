defmodule Digest do
  def make(data, alg) do
    Bytes.of_data(:crypto.hash(Digest.algorithm_atom(alg), apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_data, [data])))
  end
  def sign(_data, _priv_key, _alg) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Digest.sign is not supported on the Elixir target yet; key algorithm/padding must be modeled explicitly before lowering to :public_key.sign/3"}]
  end
  def verify(_data, _signature, _pub_key, _alg) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Digest.verify is not supported on the Elixir target yet; key algorithm/padding must be modeled explicitly before lowering to :public_key.verify/4"}]
  end
  def algorithm_atom(alg) do
    (
            case alg do
              "MD5" -> :md5
              "SHA1" -> :sha
              "SHA224" -> :sha224
              "SHA256" -> :sha256
              "SHA384" -> :sha384
              "SHA512" -> :sha512
              "RIPEMD160" -> :ripemd160
              other -> raise "sys.ssl.Digest: unsupported digest algorithm #{inspect(other)}"
            end
        )
  end
end
