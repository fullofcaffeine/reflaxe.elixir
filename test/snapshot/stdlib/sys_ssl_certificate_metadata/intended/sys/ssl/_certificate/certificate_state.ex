defmodule CertificateState do
  def name_field(certificate_ref, index, issuer, field) do
    (
                der = CertificateState.der_at(certificate_ref, index)
                certificate = :public_key.pkix_decode_cert(der, :otp)
                tbs =
                  case certificate do
                    {:OTPCertificate, value, _signature_algorithm, _signature} -> value
                    other -> raise "sys.ssl.Certificate: unsupported OTP certificate shape: #{inspect(other)}"
                  end
                name =
                  case tbs do
                    {:OTPTBSCertificate, _version, _serial, _signature, issuer_name, _validity, subject_name, _spki, _issuer_uid, _subject_uid, _extensions} ->
                      if issuer, do: issuer_name, else: subject_name
                    other -> raise "sys.ssl.Certificate: unsupported OTP certificate body shape: #{inspect(other)}"
                  end
                requested_oid =
                  case String.downcase(field) do
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
            )
  end
  def alt_names(certificate_ref, index) do
    (
                der = CertificateState.der_at(certificate_ref, index)
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
            )
  end
  def validity_date(certificate_ref, index, use_not_after) do
    (
                der = CertificateState.der_at(certificate_ref, index)
                certificate = :public_key.pkix_decode_cert(der, :otp)
                encoded_time =
                  case certificate do
                    {:OTPCertificate, {:OTPTBSCertificate, _version, _serial, _tbs_signature, _issuer, {:Validity, not_before, not_after}, _subject, _spki, _issuer_uid, _subject_uid, _extensions}, _signature_algorithm, _certificate_signature} ->
                      if use_not_after, do: not_after, else: not_before
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
            )
  end
  def read_file(file) do
    File.read!(file)
  end
  def from_pem(pem) do
    (
                entries = :public_key.pem_decode(pem)
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
            )
  end
  def from_der_chain(der_chain) do
    CertificateState.create(List.wrap(der_chain))
  end
  def load_path(path) do
    (
                der_list =
                  path
                  |> File.ls!()
                  |> Enum.flat_map(fn file ->
                    full_path = Path.join(path, file)
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
            )
  end
  def load_defaults() do
    (
                der_list =
                  try do
                    :public_key.cacerts_get()
                  rescue
                    _ -> []
                  end
                CertificateState.create(der_list)
            )
  end
  def add_pem(certificate_ref, pem) do
    (
                new_ref = CertificateState.from_pem(pem)
                existing = CertificateState.der_list(certificate_ref)
                added = CertificateState.der_list(new_ref)
                Process.put({:reflaxe_sys_ssl_certificate, certificate_ref}, existing ++ added)
                :ok
            )
  end
  def add_der(certificate_ref, der) do
    (
                existing = CertificateState.der_list(certificate_ref)
                Process.put({:reflaxe_sys_ssl_certificate, certificate_ref}, existing ++ [der])
                :ok
            )
  end
  def der_list(certificate_ref) do
    (
                case Process.get({:reflaxe_sys_ssl_certificate, certificate_ref}) do
                  nil -> raise "sys.ssl.Certificate: certificate is closed or was not initialized"
                  der_list -> der_list
                end
            )
  end
  def der_at(certificate_ref, index) do
    Enum.at(CertificateState.der_list(certificate_ref), index)
  end
  def chain_length(certificate_ref) do
    length(CertificateState.der_list(certificate_ref))
  end
  def create(der_list) do
    (
                ref = make_ref()
                Process.put({:reflaxe_sys_ssl_certificate, ref}, List.wrap(der_list))
                ref
            )
  end
end
