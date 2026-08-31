defmodule Certificate do
  defp new(certificate_ref_param, chain_index_param) do
    struct = %{:__reflaxe_class__ => Certificate, :common_name => nil, :alt_names => nil, :not_before => nil, :not_after => nil, :certificate_ref => nil, :chain_index => nil}
    struct = %{struct | certificate_ref: certificate_ref_param}
    struct = %{struct | chain_index: chain_index_param}
    struct
  end
  def subject(struct, field) do
    CertificateState.name_field(struct.certificate_ref, struct.chain_index, false, field)
  end
  def issuer(struct, field) do
    CertificateState.name_field(struct.certificate_ref, struct.chain_index, true, field)
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
  def get_alt_names(struct) do
    CertificateState.alt_names(struct.certificate_ref, struct.chain_index)
  end
  def get_not_before(struct) do
    CertificateState.validity_date(struct.certificate_ref, struct.chain_index, false)
  end
  def get_not_after(struct) do
    CertificateState.validity_date(struct.certificate_ref, struct.chain_index, true)
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
