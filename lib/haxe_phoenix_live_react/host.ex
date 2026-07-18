defmodule HaxePhoenixLiveReact.Host do
  def require_regular_file(path, label) do
    result = File.lstat(path)
    result_tag = tag(result)

    if result_tag == :error do
      Kernel.raise(
        "expected #{label} file at #{path}: #{:file.format_error(Kernel.elem(result, 1))}"
      )
    else
      stat = Kernel.elem(result, 1)

      if stat.type == :regular do
        :ok
      else
        Kernel.raise("expected #{label} file at #{path}, found #{Kernel.to_string(stat.type)}")
      end
    end
  end

  def physical_directory(path) do
    try do
      options = [{:cd, path}, {:stderr_to_stdout, true}]
      command = System.cmd("pwd", ["-P"], options)

      if elem(command, 1) == 0,
        do: {:ok, String.trim(elem(command, 0))},
        else: {:error, {"physical_path", String.trim(elem(command, 0))}}
    rescue
      error ->
        {:error, Map.get(error, :reason)}
    end
  end

  def format_path_error(reason) do
    if Kernel.is_tuple(reason) and Kernel.tuple_size(reason) == 2 and
         Kernel.elem(reason, 0) == "physical_path" do
      Kernel.elem(reason, 1)
    else
      :file.format_error(reason)
    end
  end

  defp tag(value) do
    if Kernel.is_tuple(value) do
      Kernel.elem(value, 0)
    else
      value
    end
  end
end
