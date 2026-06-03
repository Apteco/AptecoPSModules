<#
.SYNOPSIS
    CSV Handler — schreibt Records in eine CSV-Datei.

.PARAMETER Records   Array von Hashtables aus dbo.WebhookEvents
.PARAMETER Config    Ziel-Konfiguration aus endpoints/*.yaml
.PARAMETER Endpoint  Name des Endpunkts
.PARAMETER ScriptDir Pfad zum Dispatcher-Verzeichnis (für Helper-Zugriff)

.OUTPUTS
    Array von @{Id=[long]; Success=[bool]; Error=[string]}

YAML-Konfiguration:
    type: csv
    path: "D:\Exports\{endpoint}\{datetime}.csv"
    delimiter: ";"          # optional, default: ;
    encoding: UTF8          # optional, default: UTF8 (UTF8, UTF8BOM, ASCII, Unicode)
    append: false           # optional — true: an bestehende Datei anhängen
    includeHeaders: true    # optional — Kopfzeile schreiben (nur bei neuer Datei)
    columns:                # optional — wenn leer: alle Spalten + payload-Felder
      - field: id
        header: EventId
      - field: received_at
        header: Datum
      - field: payload.email
        header: Email
      - field: payload.event
        header: Event
      - field: "$"
        header: RawPayload
#>

param(
    [object[]]  $Records,
    [hashtable] $Config,
    [string]    $Endpoint,
    [string]    $ScriptDir
)

Set-StrictMode -Version Latest

# Hilfsfunktionen aus dispatch.ps1 sind im gleichen Scope verfügbar
# (dot-sourced vom Hauptskript über & Aufruf im selben Runspace)

# ------------------------------------------------------------
# Konfiguration auslesen
# ------------------------------------------------------------
$delimiter      = if ($Config['delimiter'])      { $Config['delimiter'] }      else { ';' }
$encodingName   = if ($Config['encoding'])       { $Config['encoding'] }       else { 'UTF8' }
$append         = if ($null -ne $Config['append']) { [bool]$Config['append'] } else { $false }
$includeHeaders = if ($null -ne $Config['includeHeaders']) { [bool]$Config['includeHeaders'] } else { $true }
$columns        = $Config['columns']  # kann $null sein

# Encoding-Objekt
$encoding = switch ($encodingName.ToUpper()) {
    'UTF8BOM'  { [System.Text.UTF8Encoding]::new($true) }
    'ASCII'    { [System.Text.ASCIIEncoding]::new() }
    'UNICODE'  { [System.Text.UnicodeEncoding]::new() }
    default    { [System.Text.UTF8Encoding]::new($false) }  # UTF8 ohne BOM
}

# Pfad auflösen
$outPath = Resolve-PathTemplate -Template $Config['path'] -Endpoint $Endpoint -Target $Config['name']
$outDir  = Split-Path $outPath -Parent
$null    = New-Item -ItemType Directory -Path $outDir -Force

# Spalten ermitteln — explizit oder auto
if ($columns -and $columns.Count -gt 0) {
    $colDefs = $columns | ForEach-Object {
        @{ Field = $_.field; Header = if ($_.header) { $_.header } else { $_.field } }
    }
} else {
    # Automatisch: alle DB-Spalten + payload als letzte Spalte
    $colDefs = @(
        @{ Field = 'id';          Header = 'id' },
        @{ Field = 'endpoint';    Header = 'endpoint' },
        @{ Field = 'source_ip';   Header = 'source_ip' },
        @{ Field = 'received_at'; Header = 'received_at' },
        @{ Field = 'inserted_at'; Header = 'inserted_at' },
        @{ Field = '$';           Header = 'payload' }
    )
}

# ------------------------------------------------------------
# Datei schreiben
# ------------------------------------------------------------
$fileExists = Test-Path $outPath
$writeMode  = if ($append -and $fileExists) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }

$stream = [System.IO.FileStream]::new($outPath, $writeMode, [System.IO.FileAccess]::Write)
$writer = [System.IO.StreamWriter]::new($stream, $encoding)

try {
    # Header — nur bei neuer Datei oder wenn nicht append
    if ($includeHeaders -and (-not $append -or -not $fileExists)) {
        $headerLine = ($colDefs | ForEach-Object { Escape-CsvField $_.Header $delimiter }) -join $delimiter
        $writer.WriteLine($headerLine)
    }

    $results = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($record in $Records) {
        try {
            $values = $colDefs | ForEach-Object {
                $val = Resolve-Field -Record $record -FieldExpr $_.Field
                Escape-CsvField ($val ?? '') $delimiter
            }
            $writer.WriteLine($values -join $delimiter)
            $results.Add(@{ Id = $record['id']; Success = $true; Error = $null })
        } catch {
            $results.Add(@{ Id = $record['id']; Success = $false; Error = $_.Exception.Message })
        }
    }

} finally {
    $writer.Flush()
    $writer.Close()
    $stream.Close()
}

Write-Log "[$Endpoint][CSV] Geschrieben nach: $outPath" -Level INFO
return $results

# ------------------------------------------------------------
# CSV-Feld escapen (RFC 4180)
# ------------------------------------------------------------
function Escape-CsvField([string]$value, [string]$delim) {
    if ($value -match "[`"$([regex]::Escape($delim))\r\n]") {
        return '"' + $value.Replace('"', '""') + '"'
    }
    return $value
}
