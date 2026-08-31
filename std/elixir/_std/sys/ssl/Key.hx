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
 * - `KeyState` owns the decoded Erlang term. Public methods return an opaque
 *   `Key` instead of exposing Erlang records to application code.
 */
class Key {
	@:noCompletion public var keyRef(default, null):Term;

	function new(keyRef:Term) {
		this.keyRef = keyRef;
	}

	public static function loadFile(file:String, ?isPublic:Bool, ?pass:String):Key {
		return readPEM(untyped __elixir__('File.read!({0})', file), isPublic == true, pass);
	}

	public static function readPEM(data:String, isPublic:Bool, ?pass:String):Key {
		return new Key(KeyState.readPem(data, isPublic, pass));
	}

	public static function readDER(data:Bytes, isPublic:Bool):Key {
		return new Key(KeyState.readDer(data.getData(), isPublic));
	}

	@:noCompletion public function toSslKey():Term {
		return KeyState.sslKey(keyRef);
	}
}

private class KeyState {
	public static function readPem(data:String, isPublic:Bool, pass:String):Term {
		var decoded:Term = untyped __elixir__('(
            entries = :public_key.pem_decode({0})
            public_tags = [:SubjectPublicKeyInfo, :RSAPublicKey, :DSAPublicKey, :ECPublicKey]
            private_tags = [:PrivateKeyInfo, :RSAPrivateKey, :DSAPrivateKey, :ECPrivateKey]
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
		return create(decoded);
	}

	public static function readDer(data:Term, isPublic:Bool):Term {
		var decoded:Term = untyped __elixir__('(
			entry_tag = if {1}, do: :SubjectPublicKeyInfo, else: :PrivateKeyInfo
			:public_key.pem_entry_decode({entry_tag, {0}, :not_encrypted})
		)', data, isPublic);
		return create(decoded);
	}

	public static function sslKey(keyRef:Term):Term {
		return untyped __elixir__('(
            case Process.get({:reflaxe_sys_ssl_key, {0}}) do
              nil -> raise "sys.ssl.Key: key is closed or was not initialized"
              key -> key
            end
        )', keyRef);
	}

	public static function create(key:Term):Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_ssl_key, ref}, {0})
            ref
        )', key);
	}
}
