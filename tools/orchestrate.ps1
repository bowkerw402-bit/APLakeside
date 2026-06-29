param(
    [Parameter(Mandatory=$true)]
    [string]$Task
)

$root = Split-Path $PSScriptRoot -Parent

Write-Host "`n=== ORCHESTRATOR ===" -ForegroundColor Cyan
Write-Host "Task: $Task" -ForegroundColor White

# Step 1 — Claude plans and splits the work
Write-Host "`n[1/4] Claude is planning the work split..." -ForegroundColor Yellow

$planPrompt = @"
You are the planning agent in a two-agent system (Claude + Codex).
Given this task: "$Task"

Split it into exactly two parallel workstreams:
- CLAUDE_TASK: what Claude Code should handle
- CODEX_TASK: what Codex should handle

Respond in this exact format (no extra text):
CLAUDE_TASK: <task description>
CODEX_TASK: <task description>
"@

$plan = & claude --print --dangerously-skip-permissions -p $planPrompt
Write-Host $plan -ForegroundColor Gray

# Parse the plan
$claudeTask = ($plan | Select-String "CLAUDE_TASK: (.+)").Matches[0].Groups[1].Value.Trim()
$codexTask  = ($plan | Select-String "CODEX_TASK: (.+)").Matches[0].Groups[1].Value.Trim()

Write-Host "`n[2/4] Running Claude and Codex in parallel..." -ForegroundColor Yellow
Write-Host "  Claude -> $claudeTask" -ForegroundColor Blue
Write-Host "  Codex  -> $codexTask" -ForegroundColor Magenta

# Step 2 — Run both agents in parallel via background jobs
$claudeJob = Start-Job -ScriptBlock {
    param($prompt, $root)
    & claude --print --dangerously-skip-permissions --cwd $root -p $prompt
} -ArgumentList $claudeTask, $root

$codexJob = Start-Job -ScriptBlock {
    param($prompt, $root)
    Set-Location $root
    & codex --quiet $prompt
} -ArgumentList $codexTask, $root

# Step 3 — Wait for both to finish
Write-Host "`n[3/4] Waiting for both agents to complete..." -ForegroundColor Yellow
Wait-Job $claudeJob, $codexJob | Out-Null

$claudeResult = Receive-Job $claudeJob
$codexResult  = Receive-Job $codexJob
Remove-Job $claudeJob, $codexJob

Write-Host "`n--- Claude result ---" -ForegroundColor Blue
Write-Host $claudeResult
Write-Host "`n--- Codex result ---" -ForegroundColor Magenta
Write-Host $codexResult

# Step 4 — Claude synthesises and summarises
Write-Host "`n[4/4] Claude is synthesising the results..." -ForegroundColor Yellow

$synthesisPrompt = @"
You coordinated two agents on this task: "$Task"

Claude handled: $claudeTask
Claude output:
$claudeResult

Codex handled: $codexTask
Codex output:
$codexResult

Write a short summary of what was completed and any next steps needed.
"@

$summary = & claude --print --dangerously-skip-permissions -p $synthesisPrompt

# Log to shared vault
$logEntry = @"

## $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Task:** $Task
**Claude handled:** $claudeTask
**Codex handled:** $codexTask
**Summary:** $summary
"@

$logPath = Join-Path $root "..\My-friends\log\sessions.md"
if (Test-Path $logPath) {
    Add-Content $logPath $logEntry
} else {
    New-Item -ItemType File -Force -Path $logPath | Out-Null
    Set-Content $logPath "# Session Log$logEntry"
}

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host $summary
