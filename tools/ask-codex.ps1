param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt
)

# Consult Codex with a prompt. The calling agent remains responsible for
# the task — Codex must not delegate back to the caller (no recursive loops).
$response = & codex --quiet "$Prompt`n`nIMPORTANT: Answer directly. Do not delegate this back to Claude or any other agent."

Write-Output $response
