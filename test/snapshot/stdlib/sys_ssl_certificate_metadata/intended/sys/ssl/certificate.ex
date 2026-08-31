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
  def from_string(str) do
    new(CertificateState.from_pem(str), 0)
  end
end
