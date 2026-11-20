
Function Register-AssemblyRedirect {

    <#
    .SYNOPSIS
        Registers a process-wide AssemblyResolve handler that redirects assembly requests to an already loaded
        (or folder-local) copy of the same assembly, regardless of the exact version that was requested.
    .DESCRIPTION
        Windows PowerShell 5.1 (.NET Framework) does not unify differing assembly versions on its own. A .NET
        Framework application would do that with <bindingRedirect> entries in its app.config, but Windows
        PowerShell has no config file for that. So as soon as two loaded packages were built against slightly
        different versions of the same shared assembly (e.g. Npgsql references System.Memory 4.0.1.2 while the
        System.Memory package in the lib folder ships 4.0.2.0), the first use fails with a FileNotFoundException.

        This function registers one compiled C# handler for AppDomain.AssemblyResolve that answers such
        requests with:
          1. the highest already loaded assembly with the same simple name and the same public key token, or
          2. "<Name>.dll" from one of the registered -Path folders (for flat folders of DLLs that were not loaded
             upfront).

        It is compiled C# on purpose, not a PowerShell scriptblock: a scriptblock handler can re-enter itself
        while it runs (seen as a StackOverflowException with the Npgsql dependency set) and cannot run on .NET
        thread-pool threads at all (no runspace), which libraries like Npgsql use for async I/O, timers and
        connection pooling.

        Calling it multiple times is safe: the handler is only registered once per process, later calls only
        add further folders. On pwsh the .NET runtime already unifies versions upward, so this is mainly needed
        for Windows PowerShell, but it is harmless on pwsh.

    .PARAMETER Path
        Optional folder(s) with flat DLLs (e.g. a folder with Npgsql.dll and all its dependencies) that should be
        searched for an assembly that is not loaded yet.
    .EXAMPLE
        Register-AssemblyRedirect
    .EXAMPLE
        Register-AssemblyRedirect -Path ".\npgsql-8.0.9-net48"
    .EXAMPLE
        Import-Dependency -LocalPackage "Npgsql", "System.Memory" -RedirectAssemblies   # calls this function before loading
    .NOTES
        Created by : gitfvb
    .LINK
        Project Site: https://github.com/Apteco/AptecoPSModules/tree/main/ImportDependency

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [String[]]$Path = [Array]@()
    )

    Begin {

        # The type is compiled once per process; Add-Type cannot redefine an existing type
        If ( $null -eq ( "ImportDependency.AssemblyRedirect" -as [type] ) ) {

            Write-Verbose "Compiling the ImportDependency.AssemblyRedirect resolver"

            # Keep this C# 5 compatible -- Windows PowerShell compiles Add-Type code with the old CodeDom compiler
            Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.IO;
using System.Reflection;
using System.Collections.Generic;

namespace ImportDependency {

    public static class AssemblyRedirect {

        private static readonly object Sync = new object();
        private static readonly List<string> folders = new List<string>();
        private static bool registered;

        [ThreadStatic]
        private static bool resolving;

        public static bool IsRegistered {
            get { lock (Sync) { return registered; } }
        }

        public static string[] Folders {
            get { lock (Sync) { return folders.ToArray(); } }
        }

        public static void Register(string[] paths) {
            lock (Sync) {
                if (paths != null) {
                    foreach (string p in paths) {
                        if (string.IsNullOrEmpty(p)) continue;
                        bool known = false;
                        foreach (string f in folders) {
                            if (string.Equals(f, p, StringComparison.OrdinalIgnoreCase)) { known = true; break; }
                        }
                        if (!known) folders.Add(p);
                    }
                }
                if (registered) return;
                AppDomain.CurrentDomain.AssemblyResolve += OnResolve;
                registered = true;
            }
        }

        private static Assembly OnResolve(object sender, ResolveEventArgs args) {
            return Resolve(args.Name);
        }

        // Public so it can be tested without having to provoke a real binding failure
        public static Assembly Resolve(string fullName) {

            // Loading from a folder can trigger nested resolve events -- never recurse into ourselves
            if (resolving) return null;

            AssemblyName requested;
            try { requested = new AssemblyName(fullName); } catch { return null; }
            if (string.IsNullOrEmpty(requested.Name)) return null;

            // Satellite resource lookups are expected to fail and fall back to neutral resources
            if (requested.Name.EndsWith(".resources", StringComparison.OrdinalIgnoreCase)) return null;

            resolving = true;
            try {

                byte[] requestedToken = requested.GetPublicKeyToken();

                // 1. An already loaded copy, highest version wins
                Assembly best = null;
                Version bestVersion = null;
                foreach (Assembly a in AppDomain.CurrentDomain.GetAssemblies()) {
                    AssemblyName n;
                    try { n = a.GetName(); } catch { continue; }
                    if (!string.Equals(n.Name, requested.Name, StringComparison.OrdinalIgnoreCase)) continue;
                    if (!TokenMatches(requestedToken, n.GetPublicKeyToken())) continue;
                    if (best == null || (n.Version != null && (bestVersion == null || n.Version > bestVersion))) {
                        best = a;
                        bestVersion = n.Version;
                    }
                }
                if (best != null) return best;

                // 2. A flat <Name>.dll in one of the registered folders
                foreach (string folder in Folders) {
                    string candidate = Path.Combine(folder, requested.Name + ".dll");
                    if (!File.Exists(candidate)) continue;
                    AssemblyName onDisk;
                    try { onDisk = AssemblyName.GetAssemblyName(candidate); } catch { continue; }   // native DLL or unreadable
                    if (!string.Equals(onDisk.Name, requested.Name, StringComparison.OrdinalIgnoreCase)) continue;   // file name is not the identity
                    if (!TokenMatches(requestedToken, onDisk.GetPublicKeyToken())) continue;
                    return Assembly.LoadFrom(candidate);
                }

                return null;

            } finally {
                resolving = false;
            }

        }

        // A request without public key token matches anything; a signed request needs the same signer
        private static bool TokenMatches(byte[] requested, byte[] actual) {
            if (requested == null || requested.Length == 0) return true;
            if (actual == null || actual.Length != requested.Length) return false;
            for (int i = 0; i < requested.Length; i++) {
                if (requested[i] != actual[i]) return false;
            }
            return true;
        }

    }

}
"@

        }

        $foldersToRegister = [System.Collections.ArrayList]@()

    }

    Process {

        foreach ( $p in $Path ) {
            $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p)
            If ( Test-Path -Path $absolutePath -PathType Container ) {
                [void]$foldersToRegister.Add($absolutePath)
            } else {
                Write-Warning "Folder '$( $absolutePath )' does not exist and is not used for assembly redirects"
            }
        }

    }

    End {

        [ImportDependency.AssemblyRedirect]::Register([string[]]$foldersToRegister.ToArray())
        Write-Verbose "Assembly redirect registered. Folders: $( [ImportDependency.AssemblyRedirect]::Folders -join ', ' )"

    }

}
