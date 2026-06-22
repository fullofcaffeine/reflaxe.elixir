defmodule CertificateState do
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
