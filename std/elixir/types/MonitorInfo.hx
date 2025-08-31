package elixir.types;

import elixir.types.Pid;
import elixir.types.Reference;

/**
 * Type-safe representation of monitor information
 * 
 * Represents information about a monitor relationship between processes.
 * The monitored item can be a process (Pid), a port, or a named process.
 * 
 * Usage:
 * ```haxe
 * var info: ProcessInfo = Process.info(pid);
 * for (monitor in info.monitors) {
 *     switch(monitor) {
 *         case ProcessMonitor(pid): trace('Monitoring process: $pid');
 *         case PortMonitor(port): trace('Monitoring port: $port');  
 *         case NamedMonitor(name): trace('Monitoring named process: $name');
 *     }
 * }
 * ```
 */
enum MonitorInfo {
    /**
     * Monitoring a process by PID
     */
    ProcessMonitor(pid: Pid);
    
    /**
     * Monitoring a port
     */
    PortMonitor(port: Dynamic); // Ports don't have a type yet
    
    /**
     * Monitoring a named process
     */
    NamedMonitor(name: String);
}