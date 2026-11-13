// Compiled at module import by Initialize-DuckDBFastAppender (Add-Type).
//
// Keep this at C# 5 language level: Windows PowerShell 5.1 compiles via CodeDom/csc.exe of
// .NET Framework, which knows no string interpolation, ?., pattern matching, out var etc.
//
// A type cannot be redefined in a running PowerShell session. When you change this file,
// bump the version suffix of the class name AND $typeName in Initialize-DuckDBFastAppender.ps1.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Management.Automation;
using System.Numerics;
using DuckDB.NET.Data;

namespace SqlPipeline
{
    public static class DuckDBFastAppenderV1
    {
        private enum Kind
        {
            Passthrough, Varchar, Boolean,
            TinyInt, SmallInt, Integer, BigInt, HugeInt,
            UTinyInt, USmallInt, UInteger, UBigInt,
            Float, Double, Decimal
        }

        private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

        /// <summary>
        /// Appends all rows of <paramref name="data"/> to <paramref name="tableName"/>.
        /// Columns are taken from the table schema (DESCRIBE), in table order, and looked up
        /// by name on each row (PSObject properties or IDictionary keys; case-insensitive for
        /// PSObjects). Missing properties become NULL, extra properties are ignored.
        /// Each value is converted to the exact .NET type of its column before calling the
        /// typed AppendValue overload, because DuckDB.NET reinterprets bytes instead of
        /// converting on a type mismatch (e.g. Int64 into DOUBLE gives 7.4e-323).
        /// Lists, dictionaries and PSCustomObjects are serialized with <paramref name="jsonConverter"/>.
        /// </summary>
        /// <returns>Number of rows appended.</returns>
        public static long Write(DuckDBConnection connection, string tableName, IEnumerable data, Func<object, string> jsonConverter)
        {
            if (connection == null) throw new ArgumentNullException("connection");
            if (string.IsNullOrEmpty(tableName)) throw new ArgumentNullException("tableName");
            if (data == null) return 0;

            // Read the schema: column names (in table order) and their DuckDB types
            List<string> names = new List<string>();
            List<string> types = new List<string>();
            using (var cmd = connection.CreateCommand())
            {
                cmd.CommandText = "DESCRIBE \"" + tableName.Replace("\"", "\"\"") + "\"";
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        names.Add(reader.GetString(0));
                        types.Add(reader.GetString(1));
                    }
                }
            }

            int colCount = names.Count;
            Kind[] kinds = new Kind[colCount];
            for (int c = 0; c < colCount; c++) kinds[c] = GetKind(types[c]);

            long rowNumber = 0;
            var appender = connection.CreateAppender(tableName);
            bool failed = true;
            try
            {
                foreach (object item in data)
                {
                    if (item == null) continue;
                    rowNumber++;

                    PSObject pso = item as PSObject;
                    object baseObj = pso != null ? pso.BaseObject : item;
                    IDictionary dict = baseObj as IDictionary;
                    if (dict == null && pso == null) pso = PSObject.AsPSObject(item);

                    var row = appender.CreateRow();
                    for (int c = 0; c < colCount; c++)
                    {
                        // Lookup by name per column. (Measured: enumerating pso.Properties once per row and
                        // mapping by name is ~2.5x slower on a 118-column PSCustomObject than the indexer.)
                        object val;
                        if (dict != null)
                        {
                            val = dict.Contains(names[c]) ? dict[names[c]] : null;
                        }
                        else
                        {
                            PSPropertyInfo prop = pso.Properties[names[c]];
                            val = prop == null ? null : prop.Value;
                        }

                        try
                        {
                            AppendCell(row, kinds[c], val, jsonConverter);
                        }
                        catch (Exception ex)
                        {
                            object shown = val is PSObject ? ((PSObject)val).BaseObject : val;
                            throw new InvalidOperationException(string.Format(
                                "[{0}] Row {1}, column '{2}' ({3}): cannot append value of type {4}: {5}",
                                tableName, rowNumber, names[c], types[c],
                                shown == null ? "null" : shown.GetType().FullName, ex.Message), ex);
                        }
                    }
                    row.EndRow();
                }

                // Close() flushes the remaining rows; errors (e.g. constraint violations) surface here
                appender.Close();
                failed = false;
            }
            finally
            {
                if (failed)
                {
                    // DuckDB.NET 1.4.4 crashes the process (access violation) when an appender is disposed
                    // after a failed AppendValue without Close() first. Close() may flush the half-filled row,
                    // which is acceptable: callers write into a staging table that is dropped on failure.
                    // Errors here must not hide the original exception.
                    try { appender.Close(); } catch { }
                    try { appender.Dispose(); } catch { }
                }
                else
                {
                    appender.Dispose();
                }
            }

            return rowNumber;
        }

        private static Kind GetKind(string duckType)
        {
            string t = (duckType ?? string.Empty).Trim().ToUpperInvariant();
            if (t.StartsWith("DECIMAL") || t.StartsWith("NUMERIC")) return Kind.Decimal;
            if (t.StartsWith("VARCHAR")) return Kind.Varchar;
            switch (t)
            {
                case "JSON": case "TEXT": case "STRING": case "CHAR": case "BPCHAR": return Kind.Varchar;
                case "BOOLEAN": case "BOOL": case "LOGICAL": return Kind.Boolean;
                case "TINYINT": case "INT1": return Kind.TinyInt;
                case "SMALLINT": case "INT2": case "SHORT": return Kind.SmallInt;
                case "INTEGER": case "INT4": case "INT": case "SIGNED": return Kind.Integer;
                case "BIGINT": case "INT8": case "LONG": return Kind.BigInt;
                case "HUGEINT": case "INT128": return Kind.HugeInt;
                case "UTINYINT": return Kind.UTinyInt;
                case "USMALLINT": return Kind.USmallInt;
                case "UINTEGER": return Kind.UInteger;
                case "UBIGINT": return Kind.UBigInt;
                case "FLOAT": case "FLOAT4": case "REAL": return Kind.Float;
                case "DOUBLE": case "FLOAT8": return Kind.Double;
                default: return Kind.Passthrough; // TIMESTAMP, DATE, UUID, BLOB, INTERVAL, ... -> by runtime type
            }
        }

        private static bool IsComplex(object v)
        {
            return v is PSCustomObject || v is IDictionary || (v is IList && !(v is byte[]));
        }

        private static void AppendCell(IDuckDBAppenderRow row, Kind kind, object val, Func<object, string> jsonConverter)
        {
            if (val == null) { row.AppendNullValue(); return; }

            PSObject wrapped = val as PSObject;
            object v = wrapped != null ? wrapped.BaseObject : val;
            if (v == null || v is DBNull) { row.AppendNullValue(); return; }

            if (IsComplex(v))
            {
                // Pass the wrapped object: a PSCustomObject's properties live on the PSObject, not on its BaseObject
                string json = jsonConverter != null ? jsonConverter(val) : v.ToString();
                if (json == null) row.AppendNullValue(); else row.AppendValue(json);
                return;
            }

            // Booleans count as 1/0 in numeric columns (same as the former PowerShell appender)
            object n = v is bool ? (object)((bool)v ? 1 : 0) : v;

            switch (kind)
            {
                case Kind.Varchar:   row.AppendValue(ToInvariantString(v)); return;
                case Kind.Boolean:   row.AppendValue((bool?)Convert.ToBoolean(v, Inv)); return;
                case Kind.TinyInt:   row.AppendValue((sbyte?)Convert.ToSByte(n, Inv)); return;
                case Kind.SmallInt:  row.AppendValue((short?)Convert.ToInt16(n, Inv)); return;
                case Kind.Integer:   row.AppendValue((int?)Convert.ToInt32(n, Inv)); return;
                case Kind.BigInt:    row.AppendValue((long?)Convert.ToInt64(n, Inv)); return;
                case Kind.UTinyInt:  row.AppendValue((byte?)Convert.ToByte(n, Inv)); return;
                case Kind.USmallInt: row.AppendValue((ushort?)Convert.ToUInt16(n, Inv)); return;
                case Kind.UInteger:  row.AppendValue((uint?)Convert.ToUInt32(n, Inv)); return;
                case Kind.UBigInt:   row.AppendValue((ulong?)Convert.ToUInt64(n, Inv)); return;
                case Kind.Float:     row.AppendValue((float?)Convert.ToSingle(n, Inv)); return;
                case Kind.Double:    row.AppendValue((double?)Convert.ToDouble(n, Inv)); return;
                case Kind.Decimal:   row.AppendValue((decimal?)Convert.ToDecimal(n, Inv)); return;
                case Kind.HugeInt:
                    if (n is BigInteger) row.AppendValue((BigInteger?)(BigInteger)n);
                    else if (n is double || n is float) row.AppendValue((BigInteger?)new BigInteger(Convert.ToDouble(n, Inv)));
                    else row.AppendValue((BigInteger?)new BigInteger(Convert.ToDecimal(n, Inv)));
                    return;
                default:
                    AppendByRuntimeType(row, v);
                    return;
            }
        }

        private static void AppendByRuntimeType(IDuckDBAppenderRow row, object v)
        {
            if (v is string)         { row.AppendValue((string)v); return; }
            if (v is bool)           { row.AppendValue((bool?)(bool)v); return; }
            if (v is DateTime)       { row.AppendValue((DateTime?)(DateTime)v); return; }
            if (v is DateTimeOffset) { row.AppendValue((DateTimeOffset?)(DateTimeOffset)v); return; }
            if (v is TimeSpan)       { row.AppendValue((TimeSpan?)(TimeSpan)v); return; }
            if (v is Guid)           { row.AppendValue((Guid?)(Guid)v); return; }
            if (v is long)           { row.AppendValue((long?)(long)v); return; }
            if (v is int)            { row.AppendValue((int?)(int)v); return; }
            if (v is short)          { row.AppendValue((short?)(short)v); return; }
            if (v is sbyte)          { row.AppendValue((sbyte?)(sbyte)v); return; }
            if (v is ulong)          { row.AppendValue((ulong?)(ulong)v); return; }
            if (v is uint)           { row.AppendValue((uint?)(uint)v); return; }
            if (v is ushort)         { row.AppendValue((ushort?)(ushort)v); return; }
            if (v is byte)           { row.AppendValue((byte?)(byte)v); return; }
            if (v is double)         { row.AppendValue((double?)(double)v); return; }
            if (v is float)          { row.AppendValue((float?)(float)v); return; }
            if (v is decimal)        { row.AppendValue((decimal?)(decimal)v); return; }
            if (v is BigInteger)     { row.AppendValue((BigInteger?)(BigInteger)v); return; }
            if (v is byte[])         { row.AppendValue((byte[])v); return; }
            row.AppendValue(ToInvariantString(v));
        }

        private static string ToInvariantString(object v)
        {
            string s = v as string;
            if (s != null) return s;
            if (v is DateTime) return ((DateTime)v).ToString("yyyy-MM-dd HH:mm:ss.FFFFFFF", Inv);
            if (v is DateTimeOffset) return ((DateTimeOffset)v).ToString("yyyy-MM-dd HH:mm:ss.FFFFFFFzzz", Inv);
            IFormattable f = v as IFormattable;
            if (f != null) return f.ToString(null, Inv);
            return v.ToString();
        }
    }
}
