package sys.ssl;

import elixir.types.Term;
import haxe.io.Bytes;

/**
 * sys.ssl.Key (Elixir target)
 *
 * WHAT
 * - Opaque public/private key container backed by `:public_key` decoded terms.
 *
 * WHY
 * - BEAM `:ssl` accepts decoded private keys for certificate configuration.
 * - BEAM `:public_key` uses the same decoded terms for digest signatures.
 * - Decoded Erlang key terms are immutable and safe to send between BEAM
 *   processes. Public methods keep them behind an opaque `Key`.
 */
class Key {
	@:noCompletion public var keyRef(default, null):Term;

	function new(keyRef:Term) {
		this.keyRef = keyRef;
	}

	public static function loadFile(file:String, ?isPublic:Bool, ?pass:String):Key {
		var data = sys.io.File.getBytes(file);
		if (data.length >= 11 && data.getString(0, 11) == "-----BEGIN ")
			return readPEM(data.toString(), isPublic == true, pass);
		return readDER(data, isPublic == true);
	}

	public static function readPEM(data:String, isPublic:Bool, ?pass:String):Key {
		return new Key(KeyState.readPem(data, isPublic, pass));
	}

	public static function readDER(data:Bytes, isPublic:Bool):Key {
		return new Key(KeyState.readDer(data.getData(), isPublic));
	}

	@:noCompletion public function toSslKey():Term {
		return keyRef;
	}
}

private class KeyState {
	public static function readPem(data:String, isPublic:Bool, pass:String):Term {
		var decoded:Term = untyped __elixir__('(
            entries = :public_key.pem_decode({0})
            public_tags = [:SubjectPublicKeyInfo, :RSAPublicKey, :DSAPublicKey, :ECPublicKey]
            private_tags = [:PrivateKeyInfo, :EncryptedPrivateKeyInfo, :RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]
            allowed_tags = if {1}, do: public_tags, else: private_tags
            entry =
              Enum.find(entries, fn {tag, _der, _cipher_info} ->
                tag in allowed_tags
            end)
            if is_nil(entry) do
              key_kind = if {1}, do: "public", else: "private"
              raise "sys.ssl.Key.readPEM could not find a " <> key_kind <> " key entry"
            end
            if is_nil({2}) do
              :public_key.pem_entry_decode(entry)
            else
              :public_key.pem_entry_decode(entry, String.to_charlist({2}))
            end
        )', data, isPublic, pass);
		return decoded;
	}

	public static function readDer(data:Term, isPublic:Bool):Term {
		var decoded:Term = untyped __elixir__('(
			entry_tags =
			  if {1} do
			    [:SubjectPublicKeyInfo, :RSAPublicKey, :DSAPublicKey, :ECPublicKey]
			  else
			    [:PrivateKeyInfo, :RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]
			  end
			Enum.reduce_while(entry_tags, nil, fn entry_tag, _acc ->
			  try do
			    {:halt, :public_key.pem_entry_decode({entry_tag, {0}, :not_encrypted})}
			  rescue
			    _ -> {:cont, nil}
			  catch
			    _, _ -> {:cont, nil}
			  end
			end) || raise "sys.ssl.Key.readDER could not decode the requested key"
		)', data, isPublic);
		return decoded;
	}
}
