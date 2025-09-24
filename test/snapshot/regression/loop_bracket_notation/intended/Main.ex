defmodule Main do
  def main() do
    Log.trace("Test 1: Simple Grid bracket notation", %{:file_name => "Main.hx", :line_number => 4, :class_name => "Main", :method_name => "main"})
    Enum.each(0..1, fn x -> 
      Enum.each(0..1, fn y -> 
        Log.trace("Grid[#{x}][#{y}]", %{:file_name => "Main.hx", :line_number => 7, :class_name => "Main", :method_name => "main"}) 
      end) 
    end)
    
    Log.trace("Test 2: Grid with expressions", %{:file_name => "Main.hx", :line_number => 12, :class_name => "Main", :method_name => "main"})
    offset = 10
    Enum.each(0..2, fn i -> 
      Enum.each(0..2, fn j -> 
        Log.trace("Matrix[#{i * 3}][#{j + offset}]", %{:file_name => "Main.hx", :line_number => 16, :class_name => "Main", :method_name => "main"}) 
      end) 
    end)
    
    Log.trace("Test 3: Mixed notation", %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
    Enum.each(0..1, fn row -> 
      Enum.each(0..1, fn col -> 
        Log.trace("Cell[#{row}][#{col}] = (#{row},#{col})", %{:file_name => "Main.hx", :line_number => 24, :class_name => "Main", :method_name => "main"}) 
      end) 
    end)
    
    Log.trace("Test 4: 3D array bracket notation", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "main"})
    Enum.each(0..1, fn x -> 
      Enum.each(0..1, fn y -> 
        Enum.each(0..1, fn z -> 
          Log.trace("Cube[#{x}][#{y}][#{z}]", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "main"}) 
        end) 
      end) 
    end)
  end
end