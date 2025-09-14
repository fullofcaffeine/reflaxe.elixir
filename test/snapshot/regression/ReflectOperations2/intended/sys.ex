defmodule Sys do
  def get_char(echo) do
    char = (

            # Save current terminal settings
            {:ok, old_settings} = :io.getopts(:standard_io)
            
            # Set terminal to raw mode if echo is false
            if not echo do
                :io.setopts(:standard_io, [{:echo, false}])
            end
            
            # Read single character
            char = IO.getn("", 1)
            
            # Restore terminal settings
            :io.setopts(:standard_io, old_settings)
            
            # Convert to character code
            case char do
                <<c::utf8>> -> c
                _ -> 0
            end
        
)
    char
  end
  def environment() do
    env = %{}
    elixir_env = System.get_env()
    
            Enum.each(elixir_env, fn {k, v} -> 
                env.set(k, v)
                nil
            end)
    env
  end
  def args() do
    System.argv()
  end
  def command(cmd, args) do
    if (args == nil || length(args) == 0) do
      
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
    Sys.executable_path()
  end
  def set_time_locale(loc) do
    
            Application.put_env(:elixir, :locale, loc)
        
    true
  end
end