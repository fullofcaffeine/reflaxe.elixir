package sys.ssl;

import elixir.types.Term;
import haxe.io.Bytes;
import haxe.io.Error;

/**
 * sys.ssl.Certificate (Elixir target)
 *
 * WHAT
 * - Opaque certificate chain container backed by DER binaries.
 *
 * WHY
 * - BEAM `:ssl` accepts DER certificate chains directly, which is enough for
 *   CA configuration, peer certificates, and server certificates.
 * - Full X.509 field introspection is intentionally not claimed yet because
 *   Erlang's decoded record shapes are version-sensitive.
 *
 * HOW
 * - PEM input is decoded with `:public_key.pem_decode/1`.
 * - DER input is stored as-is.
 * - Mutating Haxe APIs (`add`, `addDER`) update process-local state behind an
 *   opaque reference, mirroring `sys.net` socket/address mutability.
 */
class Certificate {
	public var commonName(get, null):Null<String>;
	public var altNames(get, null):Array<String>;
	public var notBefore(get, null):Date;
	public var notAfter(get, null):Date;

	@:noCompletion public var certificateRef(default, null):Term;

	final chainIndex:Int;

	function new(certificateRef:Term, chainIndex:Int) {
		this.certificateRef = certificateRef;
		this.chainIndex = chainIndex;
	}

	public static function loadFile(file:String):Certificate {
		return fromString(CertificateState.readFile(file));
	}

	public static function loadPath(path:String):Certificate {
		return new Certificate(CertificateState.loadPath(path), 0);
	}

	public static function fromString(str:String):Certificate {
		return new Certificate(CertificateState.fromPem(str), 0);
	}

	public static function loadDefaults():Certificate {
		return new Certificate(CertificateState.loadDefaults(), 0);
	}

	@:noCompletion public static function fromDerChain(derChain:Term):Certificate {
		return new Certificate(CertificateState.fromDerChain(derChain), 0);
	}

	public function subject(field:String):Null<String> {
		throw Error.Custom("sys.ssl.Certificate.subject is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration");
	}

	public function issuer(field:String):Null<String> {
		throw Error.Custom("sys.ssl.Certificate.issuer is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration");
	}

	public function next():Null<Certificate> {
		if (CertificateState.chainLength(certificateRef) <= chainIndex + 1)
			return null;
		return new Certificate(certificateRef, chainIndex + 1);
	}

	public function add(pem:String):Void {
		CertificateState.addPem(certificateRef, pem);
	}

	public function addDER(der:Bytes):Void {
		CertificateState.addDer(certificateRef, der.getData());
	}

	@:noCompletion public function toDerList():Term {
		return CertificateState.derList(certificateRef);
	}

	@:noCompletion public function firstDer():Term {
		return CertificateState.derAt(certificateRef, chainIndex);
	}

	function get_commonName():Null<String> {
		return subject("CN");
	}

	function get_altNames():Array<String> {
		throw Error.Custom("sys.ssl.Certificate.altNames is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration");
	}

	function get_notBefore():Date {
		throw Error.Custom("sys.ssl.Certificate.notBefore is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration");
	}

	function get_notAfter():Date {
		throw Error.Custom("sys.ssl.Certificate.notAfter is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration");
	}
}

private class CertificateState {
	public static function readFile(file:String):String {
		return untyped __elixir__('File.read!({0})', file);
	}

	public static function fromPem(pem:String):Term {
		return untyped __elixir__('(
            entries = :public_key.pem_decode({0})
            der_list =
              entries
              |> Enum.filter(fn
                {:Certificate, _der, _cipher_info} -> true
                _ -> false
              end)
              |> Enum.map(fn {:Certificate, der, _cipher_info} -> der end)
            if der_list == [] do
              raise "sys.ssl.Certificate.fromString expected at least one PEM certificate"
            end
            CertificateState.create(der_list)
        )', pem);
	}

	public static function fromDerChain(derChain:Term):Term {
		return untyped __elixir__('CertificateState.create(List.wrap({0}))', derChain);
	}

	public static function loadPath(path:String):Term {
		return untyped __elixir__('(
            der_list =
              {0}
              |> File.ls!()
              |> Enum.flat_map(fn file ->
                full_path = Path.join({0}, file)
                if File.regular?(full_path) do
                  :public_key.pem_decode(File.read!(full_path))
                  |> Enum.filter(fn
                    {:Certificate, _der, _cipher_info} -> true
                    _ -> false
                  end)
                  |> Enum.map(fn {:Certificate, der, _cipher_info} -> der end)
                else
                  []
                end
              end)
            CertificateState.create(der_list)
        )', path);
	}

	public static function loadDefaults():Term {
		return untyped __elixir__('(
            der_list =
              try do
                :public_key.cacerts_get()
              rescue
                _ -> []
              end
            CertificateState.create(der_list)
        )');
	}

	public static function addPem(certificateRef:Term, pem:String):Void {
		untyped __elixir__('(
            new_ref = CertificateState.from_pem({1})
            existing = CertificateState.der_list({0})
            added = CertificateState.der_list(new_ref)
            Process.put({:reflaxe_sys_ssl_certificate, {0}}, existing ++ added)
            :ok
        )', certificateRef, pem);
	}

	public static function addDer(certificateRef:Term, der:Term):Void {
		untyped __elixir__('(
            existing = CertificateState.der_list({0})
            Process.put({:reflaxe_sys_ssl_certificate, {0}}, existing ++ [{1}])
            :ok
        )', certificateRef, der);
	}

	public static function derList(certificateRef:Term):Term {
		return untyped __elixir__('(
            case Process.get({:reflaxe_sys_ssl_certificate, {0}}) do
              nil -> raise "sys.ssl.Certificate: certificate is closed or was not initialized"
              der_list -> der_list
            end
        )', certificateRef);
	}

	public static function derAt(certificateRef:Term, index:Int):Term {
		return untyped __elixir__('Enum.at(CertificateState.der_list({0}), {1})', certificateRef, index);
	}

	public static function chainLength(certificateRef:Term):Int {
		return untyped __elixir__('length(CertificateState.der_list({0}))', certificateRef);
	}

	public static function create(derList:Term):Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_ssl_certificate, ref}, List.wrap({0}))
            ref
        )', derList);
	}
}
