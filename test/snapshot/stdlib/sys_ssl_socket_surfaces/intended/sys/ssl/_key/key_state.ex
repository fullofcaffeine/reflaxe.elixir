defmodule KeyState do
  def read_pem(data, is_public, pass) do
    decoded = (
                entries = :public_key.pem_decode(data)
                public_tags = [:SubjectPublicKeyInfo, :RSAPublicKey, :DSAPublicKey, :ECPublicKey]
                private_tags = [:PrivateKeyInfo, :RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]
                allowed_tags = if is_public, do: public_tags, else: private_tags
                entry =
                  Enum.find(entries, fn {tag, _der, _cipher_info} ->
                    tag in allowed_tags
                end)
                if is_nil(entry) do
                  key_kind = if is_public, do: "public", else: "private"
                  raise "sys.ssl.Key.readPEM could not find a " <> key_kind <> " key entry"
                end
                if is_nil(pass) do
                  :public_key.pem_entry_decode(entry)
                else
                  :public_key.pem_entry_decode(entry, String.to_charlist(pass))
                end
            )
    create(decoded)
  end
  def read_der(data, is_public) do
    decoded = (
          entry_tag = if is_public, do: :SubjectPublicKeyInfo, else: :PrivateKeyInfo
          :public_key.pem_entry_decode({entry_tag, data, :not_encrypted})
        )
    create(decoded)
  end
  def ssl_key(key_ref) do
    (
                case Process.get({:reflaxe_sys_ssl_key, key_ref}) do
                  nil -> raise "sys.ssl.Key: key is closed or was not initialized"
                  key -> key
                end
            )
  end
  def create(key) do
    (
                ref = make_ref()
                Process.put({:reflaxe_sys_ssl_key, ref}, key)
                ref
            )
  end
end
