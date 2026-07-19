# Select only process-table rows whose executable and arguments describe a
# Haxe compilation server. Input rows use: pid comm command.

function basename(path, parts, count) {
  count = split(path, parts, "/")
  return parts[count]
}

function is_native_haxe(executable) {
  return executable == "haxe" || executable == "haxe.exe"
}

function is_node(executable) {
  return executable == "node" || executable == "node.exe"
}

function is_haxe_launcher(argument, name) {
  name = tolower(basename(argument))
  return name == "haxe" || name == "haxe.js" || name == "haxeshim" || name == "haxeshim.js"
}

function print_candidate(pid, first_argument, command, cursor) {
  command = ""
  for (cursor = first_argument; cursor <= NF; cursor++) {
    command = command (command == "" ? "" : " ") $cursor
  }
  printf "%s\t%s\n", pid, command
}

{
  pid = $1
  executable = tolower(basename($2))
  server_flag_index = 0

  for (i = 3; i <= NF; i++) {
    if ($i == "--wait") {
      server_flag_index = i
      break
    }
  }
  if (server_flag_index == 0)
    next

  if (is_native_haxe(executable)) {
    print_candidate(pid, 3)
    next
  }
  if (!is_node(executable))
    next

  node_executable_seen = 0
  for (i = 3; i < server_flag_index; i++) {
    argument_name = tolower(basename($i))
    if (!node_executable_seen && is_node(argument_name)) {
      node_executable_seen = 1
      continue
    }
    if (substr($i, 1, 1) == "-")
      continue
    if (is_haxe_launcher($i)) {
      print_candidate(pid, 3)
    }
    next
  }
}
