param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt
)

# Consult Claude Code with a prompt. The calling agent remains responsible for
# the task — Claude must not delegate back to the caller (no recursive loops).
$response = & claude --print --dangerously-skip-permissions -p "$Prompt`n`nIMPORTANT: Answer directly. Do not delegate this back to Codex or any other agent."

Write-Output $response
