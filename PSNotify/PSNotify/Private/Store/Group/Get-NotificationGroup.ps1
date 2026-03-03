# NOTE: This file intentionally left as a no-op.
# Get-NotificationGroup (with optional -Name filter) is defined in
# Public\Group\Get-NotificationGroup.ps1.  Both public and private originally
# defined a function with this name, causing the private definition (loaded
# last) to overwrite the public one.  The merged function now lives in the
# public file; this file must not redefine the function.
