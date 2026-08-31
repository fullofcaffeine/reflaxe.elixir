defmodule KeyState do
  def read_pem(data, is_public, pass) do
    (
                entries = :public_key.pem_decode(data)
                public_tags = [:SubjectPublicKeyInfo, :RSAPublicKey, :DSAPublicKey, :ECPublicKey]
                private_tags = [:PrivateKeyInfo, :EncryptedPrivateKeyInfo, :RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]
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
  end
  def read_der(data, is_public) do
    (
          entry_tags =
            if is_public do
              [:SubjectPublicKeyInfo, :RSAPublicKey, :DSAPublicKey, :ECPublicKey]
            else
              [:PrivateKeyInfo, :RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]
            end
          Enum.reduce_while(entry_tags, nil, fn entry_tag, _acc ->
            try do
              {:halt, :public_key.pem_entry_decode({entry_tag, data, :not_encrypted})}
            rescue
              _ -> {:cont, nil}
            catch
              _, _ -> {:cont, nil}
            end
          end) || raise "sys.ssl.Key.readDER could not decode the requested key"
        )
  end
end
