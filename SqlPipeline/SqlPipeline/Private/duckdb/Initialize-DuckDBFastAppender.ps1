function Initialize-DuckDBFastAppender {
    <#
    .SYNOPSIS
        Compiles the C# appender helper (DuckDBFastAppender.cs) via Add-Type.
    .DESCRIPTION
        The PowerShell appender loop costs a few microseconds per cell (property lookup, type checks and
        dynamic overload resolution of AppendValue). For wide tables that dominates the load time, so the hot
        loop lives in C#. It is compiled at import against the DuckDB.NET assemblies that are actually loaded,
        so it works with both the pinned 1.4.4 build (Windows PowerShell) and the latest build (pwsh).
        Returns $true when the type is available, $false otherwise (e.g. Add-Type blocked by Constrained
        Language Mode / AppLocker, or a compile error). Write-DuckDBAppender falls back to the PowerShell loop then.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # Must match the class name in DuckDBFastAppender.cs (bump both when the C# source changes)
    $typeName = 'SqlPipeline.DuckDBFastAppenderV1'

    if ($null -ne ($typeName -as [type])) {
        Write-Verbose "Fast appender '$typeName' already loaded in this session."
        return $true
    }

    try {

        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath 'DuckDBFastAppender.cs'
        $source = [System.IO.File]::ReadAllText($sourcePath)

        # Reference the DuckDB.NET assemblies exactly as loaded, plus what their public API pulls in
        $duckData     = [DuckDB.NET.Data.DuckDBConnection].Assembly
        $references   = [System.Collections.Generic.List[string]]::new()
        $references.Add($duckData.Location)
        $references.Add([System.Management.Automation.PSObject].Assembly.Location)

        $loaded = @{}
        [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { -not $_.IsDynamic -and $_.Location } | ForEach-Object {
            $loaded[$_.GetName().Name] = $_.Location
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            # csc.exe of .NET Framework: DuckDB.NET is a netstandard2.0 build here, so the compiler needs the
            # netstandard facade plus the framework assemblies behind DbConnection, BigInteger and Span<T>.
            $references.Add('System.Data.dll')
            $references.Add('System.Numerics.dll')
            $netstandard = Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) 'netstandard.dll'
            if (Test-Path $netstandard) { $references.Add($netstandard) }
            foreach ($name in @('DuckDB.NET.Bindings', 'System.Memory', 'System.Runtime.CompilerServices.Unsafe')) {
                if ($loaded.ContainsKey($name)) { $references.Add($loaded[$name]) }
            }
        } else {
            # pwsh: add everything DuckDB.NET.Data references (DuckDB.NET.Bindings, System.Data.Common for
            # DbConnection, System.Runtime.Numerics for BigInteger, ...). Framework assemblies must come from the
            # reference assemblies in $PSHOME/ref - mixing in runtime implementation assemblies breaks type forwarding.
            $refFolder = Join-Path -Path $PSHOME -ChildPath 'ref'
            foreach ($ref in $duckData.GetReferencedAssemblies()) {
                $refAssembly = Join-Path -Path $refFolder -ChildPath "$($ref.Name).dll"
                if (Test-Path -Path $refAssembly) {
                    $references.Add($refAssembly)
                } elseif ($loaded.ContainsKey($ref.Name)) {
                    $references.Add($loaded[$ref.Name])
                }
            }
        }

        Write-Verbose "Compiling fast appender '$typeName' with references: $($references -join ', ')"
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        # -IgnoreWarnings: Add-Type turns warnings into errors, e.g. CS1701 when DuckDB.NET was built against
        # .NET 8 (System.Data.Common 8.0.0.0) but pwsh runs on a newer runtime (10.0.0.0) - harmless unification.
        Add-Type -TypeDefinition $source -ReferencedAssemblies ($references | Select-Object -Unique) -IgnoreWarnings -WarningAction SilentlyContinue -ErrorAction Stop
        $sw.Stop()
        Write-Verbose "Fast appender compiled in $($sw.ElapsedMilliseconds) ms."

        return ($null -ne ($typeName -as [type]))

    } catch {
        Write-Warning "Could not compile the fast DuckDB appender, falling back to the (slower) PowerShell appender. Reason: $($_.Exception.Message)"
        return $false
    }
}
