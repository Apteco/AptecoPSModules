<#
.SYNOPSIS
    JSON Handler — schreibt Records in eine JSON-Datei.

YAML-Konfiguration:
    type: json
    path: "D:\Exports\{endpoint}\{datetime}.json"
    pretty: true            # optional — eingerücktes JSON, default: false
    mode: array             # optional — "array" (default) oder "lines" (JSONL)
    append: false           # optional — nur für mode: lines sinnvoll
    fields:                 # optional — wenn leer: ganzer payload raw
      - field: id
        as: eventId
      - field: received_at
        as: receivedAt
      - field: payload.email
        as: email
      - field: "$"
        as: rawPayload
#>

param(
    [object[]]  $Records,
    [hashtable] $Config,
    [string]    $Endpoint,
    [string]    $ScriptDir
)

Set-StrictMode -Version Latest

# Konfiguration
$pretty  = if ($null -ne $Config['pretty'])  { [bool]$Config['pretty'] }  else { $false }
$mode    = if ($Config['mode'])              { $Config['mode'] }           else { 'array' }
$append  = if ($null -ne $Config['append'])  { [bool]$Config['append'] }  else { $false }
$fields  = $Config['fields']

# Pfad auflösen
$outPath = Resolve-PathTemplate -Template $Config['path'] -Endpoint $Endpoint -Target $Config['name']
$outDir  = Split-Path $outPath -Parent
$null    = New-Item -ItemType Directory -Path $outDir -Force

$results = [System.Collections.Generic.List[hashtable]]::new()

# Records in Objekte umwandeln
$objects = [System.Collections.Generic.List[object]]::new()

foreach ($record in $Records) {
    try {
        if ($fields -and $fields.Count -gt 0) {
            # Explizite Felder mappen
            $obj = [ordered]@{}
            foreach ($f in $fields) {
                $key = if ($f['as']) { $f['as'] } else { $f['field'] }
                $val = Resolve-Field -Record $record -FieldExpr $f['field']

                # Wenn Wert selbst JSON ist (payload/$), als Objekt einbetten
                if ($f['field'] -eq '$' -or $f['field'] -eq 'payload') {
                    try   { $val = $val | ConvertFrom-Json -ErrorAction Stop }
                    catch { <# als String belassen #> }
                }
                $obj[$key] = $val
            }
        } else {
            # Kein fields-Mapping — payload direkt als Objekt, plus Metadaten
            $payloadObj = $null
            try { $payloadObj = $record['payload'] | ConvertFrom-Json -ErrorAction Stop }
            catch { $payloadObj = $record['payload'] }

            $obj = [ordered]@{
                _id          = $record['id']
                _endpoint    = $record['endpoint']
                _source_ip   = $record['source_ip']
                _received_at = $record['received_at']
                payload      = $payloadObj
            }
        }

        $objects.Add($obj)
        $results.Add(@{ Id = $record['id']; Success = $true; Error = $null })
    } catch {
        $results.Add(@{ Id = $record['id']; Success = $false; Error = $_.Exception.Message })
    }
}

# Datei schreiben
$depth = 20  # ConvertTo-Json Tiefe
$writeMode = if ($append -and (Test-Path $outPath) -and $mode -eq 'lines') {
    [System.IO.FileMode]::Append
} else {
    [System.IO.FileMode]::Create
}

$stream = [System.IO.FileStream]::new($outPath, $writeMode, [System.IO.FileAccess]::Write)
$writer = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))

try {
    if ($mode -eq 'lines') {
        # JSONL — eine Zeile pro Record
        foreach ($obj in $objects) {
            $json = $obj | ConvertTo-Json -Depth $depth -Compress:(-not $pretty)
            $writer.WriteLine($json)
        }
    } else {
        # Array-Modus
        $json = $objects | ConvertTo-Json -Depth $depth
        if (-not $pretty) {
            # Komprimieren: Whitespace entfernen (simpel für valides JSON)
            $json = $json | ConvertFrom-Json | ConvertTo-Json -Depth $depth -Compress
        }
        $writer.Write($json)
    }
} finally {
    $writer.Flush()
    $writer.Close()
    $stream.Close()
}

Write-Log "[$Endpoint][JSON] Geschrieben nach: $outPath ($mode)" -Level INFO
return $results
