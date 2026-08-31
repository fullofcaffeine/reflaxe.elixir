package sys.ssl;

import elixir.types.Term;
import haxe.io.Bytes;

/**
 * sys.ssl.Certificate (Elixir target)
 *
 * WHAT
 * - Certificate chain container backed by DER binaries.
 *
 * WHY
 * - BEAM `:ssl` accepts DER certificate chains directly, which is enough for
 *   CA configuration, peer certificates, and server certificates.
 * - Haxe programs can inspect common X.509 names, DNS alternative names, and
 *   validity dates without depending on Erlang record declarations.
 *
 * HOW
 * - PEM input is decoded with `:public_key.pem_decode/1`.
 * - DER input is stored as-is.
 * - Metadata is decoded with `:public_key.pkix_decode_cert/2`. The target
 *   boundary validates each OTP tuple before it reads a record field.
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
		return CertificateState.nameField(certificateRef, chainIndex, false, field);
	}

	public function issuer(field:String):Null<String> {
		return CertificateState.nameField(certificateRef, chainIndex, true, field);
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
		return CertificateState.altNames(certificateRef, chainIndex);
	}

	function get_notBefore():Date {
		return CertificateState.validityDate(certificateRef, chainIndex, false);
	}

	function get_notAfter():Date {
		return CertificateState.validityDate(certificateRef, chainIndex, true);
	}
}

private class CertificateState {
	/**
	 * Read one X.509 distinguished-name field through OTP's public decoder.
	 * This function contains the raw Erlang record boundary and validates all
	 * tuple tags before it reads their positional fields.
	 */
	public static function nameField(certificateRef:Term, index:Int, issuer:Bool, field:String):Null<String> {
		return untyped __elixir__('(
            der = CertificateState.der_at({0}, {1})
            certificate = :public_key.pkix_decode_cert(der, :otp)
            tbs =
              case certificate do
                {:OTPCertificate, value, _signature_algorithm, _signature} -> value
                other -> raise "sys.ssl.Certificate: unsupported OTP certificate shape: #{inspect(other)}"
              end
            name =
              case tbs do
                {:OTPTBSCertificate, _version, _serial, _signature, issuer_name, _validity, subject_name, _spki, _issuer_uid, _subject_uid, _extensions} ->
                  if {2}, do: issuer_name, else: subject_name
                other -> raise "sys.ssl.Certificate: unsupported OTP certificate body shape: #{inspect(other)}"
              end
            requested_oid =
              case String.downcase({3}) do
                "cn" -> {2, 5, 4, 3}
                "commonname" -> {2, 5, 4, 3}
                "sn" -> {2, 5, 4, 4}
                "surname" -> {2, 5, 4, 4}
                "serialnumber" -> {2, 5, 4, 5}
                "c" -> {2, 5, 4, 6}
                "countryname" -> {2, 5, 4, 6}
                "l" -> {2, 5, 4, 7}
                "localityname" -> {2, 5, 4, 7}
                "st" -> {2, 5, 4, 8}
                "stateorprovincename" -> {2, 5, 4, 8}
                "street" -> {2, 5, 4, 9}
                "streetaddress" -> {2, 5, 4, 9}
                "o" -> {2, 5, 4, 10}
                "organizationname" -> {2, 5, 4, 10}
                "ou" -> {2, 5, 4, 11}
                "organizationalunitname" -> {2, 5, 4, 11}
                "title" -> {2, 5, 4, 12}
                "description" -> {2, 5, 4, 13}
                "postalcode" -> {2, 5, 4, 17}
                "givenname" -> {2, 5, 4, 42}
                "initials" -> {2, 5, 4, 43}
                "generationqualifier" -> {2, 5, 4, 44}
                "dnqualifier" -> {2, 5, 4, 46}
                "pseudonym" -> {2, 5, 4, 65}
                "emailaddress" -> {1, 2, 840, 113549, 1, 9, 1}
                "dc" -> {0, 9, 2342, 19200300, 100, 1, 25}
                "domaincomponent" -> {0, 9, 2342, 19200300, 100, 1, 25}
                "uid" -> {0, 9, 2342, 19200300, 100, 1, 1}
                "userid" -> {0, 9, 2342, 19200300, 100, 1, 1}
                dotted ->
                  try do
                    dotted |> String.split(".") |> Enum.map(&String.to_integer/1) |> List.to_tuple()
                  rescue
                    _ -> nil
                  end
              end
            decode_value = fn
              value when is_binary(value) -> value
              value when is_list(value) -> :unicode.characters_to_binary(value)
              {_kind, value} when is_binary(value) -> value
              {_kind, value} when is_list(value) -> :unicode.characters_to_binary(value)
              value -> raise "sys.ssl.Certificate: unsupported X.509 name value: #{inspect(value)}"
            end
            case {name, requested_oid} do
              {_, nil} -> nil
              {{:rdnSequence, groups}, oid} when is_list(groups) ->
                groups
                |> List.flatten()
                |> Enum.find_value(fn
                  {:AttributeTypeAndValue, ^oid, value} -> decode_value.(value)
                  _ -> nil
                end)
              {other, _oid} -> raise "sys.ssl.Certificate: unsupported X.509 name shape: #{inspect(other)}"
            end
        )', certificateRef, index, issuer, field);
	}

	/** Return DNS, email, URI, and IP subject alternative names as strings. */
	public static function altNames(certificateRef:Term, index:Int):Array<String> {
		return untyped __elixir__('(
            der = CertificateState.der_at({0}, {1})
            certificate = :public_key.pkix_decode_cert(der, :otp)
            extensions =
              case certificate do
                {:OTPCertificate, {:OTPTBSCertificate, _version, _serial, _tbs_signature, _issuer, _validity, _subject, _spki, _issuer_uid, _subject_uid, value}, _signature_algorithm, _certificate_signature} -> value
                other -> raise "sys.ssl.Certificate: unsupported OTP certificate shape: #{inspect(other)}"
              end
            names =
              Enum.find_value(List.wrap(extensions), [], fn
                {:Extension, {2, 5, 29, 17}, _critical, value} -> value
                _ -> nil
              end)
            names
            |> Enum.flat_map(fn
              {:dNSName, value} -> [:unicode.characters_to_binary(value)]
              {:rfc822Name, value} -> [:unicode.characters_to_binary(value)]
              {:uniformResourceIdentifier, value} -> [:unicode.characters_to_binary(value)]
              {:iPAddress, value} when is_binary(value) ->
                address =
                  case value do
                    <<a, b, c, d>> -> {a, b, c, d}
                    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>> -> {a, b, c, d, e, f, g, h}
                    _ -> nil
                  end
                case address do
                  nil -> []
                  tuple ->
                    case :inet.ntoa(tuple) do
                      {:error, _reason} -> []
                      chars -> [:unicode.characters_to_binary(chars)]
                    end
                end
              _ -> []
            end)
        )', certificateRef, index);
	}

	/** Convert an RFC 5280 UTC or generalized validity time to Haxe Date. */
	public static function validityDate(certificateRef:Term, index:Int, useNotAfter:Bool):Date {
		return untyped __elixir__('(
            der = CertificateState.der_at({0}, {1})
            certificate = :public_key.pkix_decode_cert(der, :otp)
            encoded_time =
              case certificate do
                {:OTPCertificate, {:OTPTBSCertificate, _version, _serial, _tbs_signature, _issuer, {:Validity, not_before, not_after}, _subject, _spki, _issuer_uid, _subject_uid, _extensions}, _signature_algorithm, _certificate_signature} ->
                  if {2}, do: not_after, else: not_before
                other -> raise "sys.ssl.Certificate: unsupported OTP certificate validity shape: #{inspect(other)}"
              end
            {year, month, day, hour, minute, second} =
              case encoded_time do
                {:utcTime, value} ->
                  <<short_year::binary-size(2), month::binary-size(2), day::binary-size(2), hour::binary-size(2), minute::binary-size(2), second::binary-size(2), "Z">> = :unicode.characters_to_binary(value)
                  short_year = String.to_integer(short_year)
                  year = if short_year >= 50, do: short_year + 1900, else: short_year + 2000
                  {year, String.to_integer(month), String.to_integer(day), String.to_integer(hour), String.to_integer(minute), String.to_integer(second)}
                {kind, value} when kind in [:generalTime, :generalizedTime] ->
                  <<year::binary-size(4), month::binary-size(2), day::binary-size(2), hour::binary-size(2), minute::binary-size(2), second::binary-size(2), "Z">> = :unicode.characters_to_binary(value)
                  {String.to_integer(year), String.to_integer(month), String.to_integer(day), String.to_integer(hour), String.to_integer(minute), String.to_integer(second)}
                other -> raise "sys.ssl.Certificate: unsupported X.509 validity time: #{inspect(other)}"
              end
            {:ok, naive} = NaiveDateTime.new(year, month, day, hour, minute, second)
            DateTime.from_naive!(naive, "Etc/UTC")
        )', certificateRef, index, useNotAfter);
	}

	public static function readFile(file:String):String {
		return untyped __elixir__('File.read!({0})', file);
	}

	// Raw Elixir in addPem calls this method, so DCE cannot see every call.

	@:keep
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

	// Raw Elixir in this helper calls derList through the generated module.

	@:keep
	public static function derList(certificateRef:Term):Term {
		return untyped __elixir__('(
            case Process.get({:reflaxe_sys_ssl_certificate, {0}}) do
              nil -> raise "sys.ssl.Certificate: certificate is closed or was not initialized"
              der_list -> der_list
            end
        )', certificateRef);
	}

	// Metadata decoders call derAt from raw Elixir.

	@:keep
	public static function derAt(certificateRef:Term, index:Int):Term {
		return untyped __elixir__('Enum.at(CertificateState.der_list({0}), {1})', certificateRef, index);
	}

	public static function chainLength(certificateRef:Term):Int {
		return untyped __elixir__('length(CertificateState.der_list({0}))', certificateRef);
	}

	// PEM, DER-chain, path, and default loaders call create from raw Elixir.

	@:keep
	public static function create(derList:Term):Term {
		return untyped __elixir__('(
            ref = make_ref()
            Process.put({:reflaxe_sys_ssl_certificate, ref}, List.wrap({0}))
            ref
        )', derList);
	}
}
