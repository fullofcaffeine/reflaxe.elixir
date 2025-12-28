defmodule Sys do
  def println(v) do
    IO.puts(v)
  end
  def print(v) do
    IO.write(v)
  end
  def stdin() do
    Process.group_leader()
  end
  def stdout() do
    Process.group_leader()
  end
  def stderr() do
    :standard_error
  end
  def get_char(echo) do
    
            {:ok, old_settings} = :io.getopts(:standard_io)

            if not echo do
                :io.setopts(:standard_io, [{:echo, false}])
            end

            input = IO.getn("", 1)
            :io.setopts(:standard_io, old_settings)

            case input do
                <<c::utf8>> -> c
                _ -> 0
            end
        
  end
  def environment() do
    System.get_env()
  end
  def get_env(s) do
    System.get_env(s)
  end
  def put_env(s, v) do
    System.put_env(s, v)
  end
  def get_cwd() do
    File.cwd!()
  end
  def set_cwd(s) do
    File.cd!(s)
  end
  def args() do
    System.argv()
  end
  def exit(code) do
    System.halt(code)
  end
  def command(cmd, args) do
    if (Kernel.is_nil(args) or length(args) == 0) do
      
                case System.cmd("sh", ["-c", cmd]) do
                    {_, 0} -> 0
                    {_, code} -> code
                end
    else
      
                case System.cmd(cmd, args) do
                    {_, 0} -> 0
                    {_, code} -> code
                end
    end
  end
  def time() do
    System.system_time(:second)
  end
  def cpu_time() do
    
            {total, _} = :erlang.statistics(:runtime)
            total / 1000.0
        
  end
  def sleep(seconds) do
    milliseconds = trunc(seconds * 1000)
    Process.sleep(milliseconds)
  end
  def system_name() do
    
            case :os.type() do
                {:unix, :linux} -> "linux"
                {:unix, :darwin} -> "darwin"
                {:win32, _} -> "windows"
                {:unix, name} -> Atom.to_string(name)
                {family, name} -> Atom.to_string(family) <> "_" <> Atom.to_string(name)
            end
        
  end
  def executable_path() do
    
            case :init.get_argument(:progname) do
                {:ok, [[path | _]]} -> List.to_string(path)
                _ -> System.find_executable("erl") || ""
            end
        
  end
  def program_path() do
    executable_path()
  end
  def set_time_locale(loc) do
    
            Application.put_env(:elixir, :locale, loc)
        
    true
  end
end
