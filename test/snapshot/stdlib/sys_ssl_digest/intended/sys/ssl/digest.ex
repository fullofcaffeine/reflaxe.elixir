defmodule Digest do
  def make(data, alg) do
    Bytes.of_data(:crypto.hash(Digest.algorithm_atom(alg), apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_data, [data])))
  end
  def sign(data, priv_key, alg) do
    Bytes.of_data(DigestState.sign(apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_data, [data]), apply(Map.get(priv_key, :__reflaxe_class__) || Map.get(priv_key, :__struct__), :to_ssl_key, [priv_key]), algorithm_atom(alg)))
  end
  def verify(data, signature, pub_key, alg) do
    DigestState.verify(apply(Map.get(data, :__reflaxe_class__) || Map.get(data, :__struct__), :get_data, [data]), apply(Map.get(signature, :__reflaxe_class__) || Map.get(signature, :__struct__), :get_data, [signature]), apply(Map.get(pub_key, :__reflaxe_class__) || Map.get(pub_key, :__struct__), :to_ssl_key, [pub_key]), algorithm_atom(alg))
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
