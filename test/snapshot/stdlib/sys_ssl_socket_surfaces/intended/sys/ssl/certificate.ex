defmodule Certificate do
  defp new(certificate_ref_param, chain_index_param) do
    struct = %{:__reflaxe_class__ => Certificate, :common_name => nil, :alt_names => nil, :not_before => nil, :not_after => nil, :certificate_ref => nil, :chain_index => nil}
    struct = %{struct | certificate_ref: certificate_ref_param}
    struct = %{struct | chain_index: chain_index_param}
    struct
  end
  def subject(_struct, _field) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Certificate.subject is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration"}]
  end
  def issuer(_struct, _field) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Certificate.issuer is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration"}]
  end
  def next(struct) do
    if (CertificateState.chain_length(struct.certificate_ref) <= struct.chain_index + 1), do: nil, else: new(struct.certificate_ref, struct.chain_index + 1)
  end
  def add(struct, pem) do
    CertificateState.add_pem(struct.certificate_ref, pem)
  end
  def add_der(struct, der) do
    CertificateState.add_der(struct.certificate_ref, apply(Map.get(der, :__reflaxe_class__) || Map.get(der, :__struct__), :get_data, [der]))
  end
  def to_der_list(struct) do
    CertificateState.der_list(struct.certificate_ref)
  end
  def first_der(struct) do
    CertificateState.der_at(struct.certificate_ref, struct.chain_index)
  end
  def get_common_name(struct) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :subject, [struct, "CN"])
  end
  def get_alt_names(_struct) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Certificate.altNames is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration"}]
  end
  def get_not_before(_struct) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Certificate.notBefore is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration"}]
  end
  def get_not_after(_struct) do
    raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "sys.ssl.Certificate.notAfter is not supported on the Elixir target yet; certificates are currently opaque DER chains for :ssl configuration"}]
  end
  def load_file(file) do
    from_string(CertificateState.read_file(file))
  end
  def load_path(path) do
    new(CertificateState.load_path(path), 0)
  end
  def from_string(str) do
    new(CertificateState.from_pem(str), 0)
  end
  def load_defaults() do
    new(CertificateState.load_defaults(), 0)
  end
  def from_der_chain(der_chain) do
    new(CertificateState.from_der_chain(der_chain), 0)
  end
end
