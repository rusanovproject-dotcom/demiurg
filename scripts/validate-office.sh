#!/bin/bash
# validate-office.sh — Полный health-check ВСЕГО офиса (AGENTS.md + context.md + все агенты).
# 20 проверок в 4 категориях. Запускать ПОСЛЕ wiring-фазы (TEAM-режим).
# Для одного агента детально: validate-agent.sh
# Для общего health-check директории: validate.sh
# Usage: bash validate-office.sh [/path/to/office]
# Exit: 0 if no BLOCKERs, 1 if BLOCKERs found

set -uo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Target directory ---
TARGET="${1:-.}"
TARGET=$(cd "$TARGET" 2>/dev/null && pwd) || { echo "Error: directory '$1' not found"; exit 1; }

# --- Counters ---
PASS=0
WARN=0
ERROR=0
BLOCKER=0

# --- Collected issues ---
BLOCKER_LIST=""
ERROR_LIST=""
WARN_LIST=""

# --- Helpers ---
pass() {
  echo -e "  ${GREEN}PASS${NC}  $1"
  ((PASS++))
}

warn() {
  echo -e "  ${YELLOW}WARN${NC}  $1"
  ((WARN++))
  WARN_LIST="${WARN_LIST}\n  - $1"
}

error() {
  echo -e "  ${RED}ERROR${NC} $1"
  ((ERROR++))
  ERROR_LIST="${ERROR_LIST}\n  - $1"
}

blocker() {
  echo -e "  ${RED}${BOLD}FAIL${NC}  $1"
  ((BLOCKER++))
  BLOCKER_LIST="${BLOCKER_LIST}\n  - $1"
}

# --- Header ---
echo -e "${BOLD}=== AI Office Health Check ===${NC}"
echo "Target: $TARGET"
echo "Date: $(date +%Y-%m-%d)"
echo ""

# ============================================================
# A. STRUCTURE (5 checks)
# ============================================================
echo -e "${CYAN}[A. Structure]${NC}"

# A1: Root CLAUDE.md exists (BLOCKER)
if [ -f "$TARGET/CLAUDE.md" ]; then
  pass "A1: Root CLAUDE.md exists"
else
  blocker "A1: Root CLAUDE.md is MISSING"
fi

# A2: AGENTS.md exists (BLOCKER for small+)
if [ -f "$TARGET/AGENTS.md" ]; then
  pass "A2: AGENTS.md exists"
else
  # Check if there are agents/ dir — if yes, it's small+ and AGENTS.md is required
  if [ -d "$TARGET/agents" ] || [ -d "$TARGET/.claude/agents" ]; then
    blocker "A2: AGENTS.md is MISSING (agents/ directory exists — small+ pattern requires it)"
  else
    pass "A2: AGENTS.md not needed (solo pattern)"
  fi
fi

# A3: context.md exists and <= 50 lines (WARNING)
CONTEXT_FILE=""
for candidate in "$TARGET/context.md" "$TARGET/ops/context.md"; do
  [ -f "$candidate" ] && CONTEXT_FILE="$candidate" && break
done

if [ -n "$CONTEXT_FILE" ]; then
  ctx_lines=$(wc -l < "$CONTEXT_FILE" | tr -d ' ')
  if [ "$ctx_lines" -le 50 ]; then
    pass "A3: context.md exists ($ctx_lines lines)"
  else
    warn "A3: context.md is $ctx_lines lines (limit: 50)"
  fi
else
  warn "A3: context.md not found"
fi

# A4: knowledge/INDEX.md exists (WARNING)
if [ -d "$TARGET/knowledge" ]; then
  if [ -f "$TARGET/knowledge/INDEX.md" ]; then
    pass "A4: knowledge/INDEX.md exists"
  else
    warn "A4: knowledge/ exists but INDEX.md is missing"
  fi
else
  warn "A4: knowledge/ directory not found"
fi

# A5: Directory nesting <= 3 levels (WARNING)
max_depth=0
while IFS= read -r dir; do
  # Calculate depth relative to TARGET
  rel="${dir#$TARGET/}"
  # Count slashes = depth
  depth=$(echo "$rel" | awk -F'/' '{print NF}')
  [ "$depth" -gt "$max_depth" ] && max_depth=$depth
done < <(find "$TARGET" -type d -not -path '*/.git/*' -not -path '*/.git' -not -path '*/node_modules/*' -not -path '*/.claude/*' 2>/dev/null)

if [ "$max_depth" -le 3 ]; then
  pass "A5: Max nesting depth is $max_depth (limit: 3)"
else
  warn "A5: Max nesting depth is $max_depth (limit: 3)"
fi

echo ""

# ============================================================
# B. AGENTS (5 checks)
# ============================================================
echo -e "${CYAN}[B. Agents]${NC}"

# Parse AGENTS.md to find agent file references
AGENTS_FILE="$TARGET/AGENTS.md"
AGENTS_DIR=""
for candidate in "$TARGET/agents" "$TARGET/.claude/agents"; do
  [ -d "$candidate" ] && AGENTS_DIR="$candidate" && break
done

# Collect agents listed in AGENTS.md (look for file paths like agents/xxx.md or .claude/agents/xxx.md)
declare -a LISTED_AGENTS=()
if [ -f "$AGENTS_FILE" ]; then
  while IFS= read -r agent_path; do
    # Clean up: remove backticks, brackets, leading/trailing spaces
    clean=$(echo "$agent_path" | sed 's/`//g; s/\[//g; s/\]//g; s/(//g; s/)//g' | xargs)
    [ -n "$clean" ] && LISTED_AGENTS+=("$clean")
  done < <(grep -oE '(\.claude/agents|agents)/[a-zA-Z0-9_-]+\.(md|yml)' "$AGENTS_FILE" 2>/dev/null | sort -u)
fi

# B1: Every agent in AGENTS.md has a file (BLOCKER)
b1_ok=true
if [ -f "$AGENTS_FILE" ] && [ ${#LISTED_AGENTS[@]} -gt 0 ]; then
  for agent_ref in "${LISTED_AGENTS[@]}"; do
    if [ ! -f "$TARGET/$agent_ref" ]; then
      blocker "B1: Agent \"$(basename "$agent_ref" .md)\" in AGENTS.md but file missing: $agent_ref"
      b1_ok=false
    fi
  done
  $b1_ok && pass "B1: All agents in AGENTS.md have files"
elif [ -f "$AGENTS_FILE" ]; then
  # AGENTS.md exists but no agent paths found — try to parse agent names from table rows
  has_agents=false
  while IFS= read -r line; do
    # Look for table rows with agent names
    name=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' 2>/dev/null)
    [ -z "$name" ] && continue
    [[ "$name" == "---"* ]] && continue
    [[ "$name" == "Агент"* ]] && continue
    [[ "$name" == "Agent"* ]] && continue
    [[ "$name" == "#"* ]] && continue
    has_agents=true
  done < <(grep '|' "$AGENTS_FILE" 2>/dev/null)
  if $has_agents; then
    pass "B1: AGENTS.md found (no direct file paths to validate)"
  else
    pass "B1: AGENTS.md found (no agents listed)"
  fi
else
  pass "B1: No AGENTS.md — skipped"
fi

# B2: No orphan files in agents/ without entry in AGENTS.md (ERROR)
if [ -n "$AGENTS_DIR" ] && [ -f "$AGENTS_FILE" ]; then
  b2_ok=true
  while IFS= read -r agent_file; do
    basename_file=$(basename "$agent_file")
    # Skip INDEX.md, README.md
    [[ "$basename_file" == "INDEX.md" ]] && continue
    [[ "$basename_file" == "README.md" ]] && continue
    # Check if this file is mentioned in AGENTS.md
    if ! grep -q "$basename_file" "$AGENTS_FILE" 2>/dev/null; then
      error "B2: Orphan agent file: $agent_file (not in AGENTS.md)"
      b2_ok=false
    fi
  done < <(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -o -name "*.yml" 2>/dev/null)
  $b2_ok && pass "B2: No orphan agent files"
elif [ -n "$AGENTS_DIR" ]; then
  warn "B2: agents/ exists but no AGENTS.md to cross-check"
else
  pass "B2: No agents/ directory — skipped"
fi

# B3: Each agent has "НЕ отвечает" or "НЕ делает" section (WARNING)
if [ -n "$AGENTS_DIR" ]; then
  b3_ok=true
  while IFS= read -r agent_file; do
    basename_file=$(basename "$agent_file")
    [[ "$basename_file" == "INDEX.md" ]] && continue
    [[ "$basename_file" == "README.md" ]] && continue
    if ! grep -qiE '(НЕ отвечает|НЕ делает|не делает|не отвечает|NOT responsible|does NOT)' "$agent_file" 2>/dev/null; then
      warn "B3: Agent $(basename "$agent_file" .md) has no \"NOT responsible\" / \"НЕ делает\" section"
      b3_ok=false
    fi
  done < <(find "$AGENTS_DIR" -maxdepth 1 \( -name "*.md" -o -name "*.yml" \) 2>/dev/null)
  $b3_ok && pass "B3: All agents have boundary sections"
else
  pass "B3: No agents/ directory — skipped"
fi

# B4: Agent CLAUDE.md files <= 200 lines (WARNING)
b4_ok=true
while IFS= read -r claude_file; do
  # Skip root CLAUDE.md — this checks agent-level ones
  [[ "$claude_file" == "$TARGET/CLAUDE.md" ]] && continue
  lines=$(wc -l < "$claude_file" | tr -d ' ')
  if [ "$lines" -gt 200 ]; then
    warn "B4: $claude_file is $lines lines (limit: 200)"
    b4_ok=false
  fi
done < <(find "$TARGET" -name "CLAUDE.md" -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null)
$b4_ok && pass "B4: All CLAUDE.md files <= 200 lines"

# B5: No empty CLAUDE.md files (ERROR)
b5_ok=true
while IFS= read -r claude_file; do
  lines=$(wc -l < "$claude_file" | tr -d ' ')
  if [ "$lines" -lt 3 ]; then
    error "B5: Empty CLAUDE.md: $claude_file ($lines lines)"
    b5_ok=false
  fi
done < <(find "$TARGET" -name "CLAUDE.md" -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null)
$b5_ok && pass "B5: No empty CLAUDE.md files"

echo ""

# ============================================================
# C. CONNECTIONS & ROUTING (5 checks)
# ============================================================
echo -e "${CYAN}[C. Connections & Routing]${NC}"

ROOT_CLAUDE="$TARGET/CLAUDE.md"

# C1: Root CLAUDE.md has a routing table (BLOCKER)
if [ -f "$ROOT_CLAUDE" ]; then
  if grep -qE '\|.*\|.*\|' "$ROOT_CLAUDE" 2>/dev/null && grep -qiE '(роутинг|routing|задач|тип|agent|агент)' "$ROOT_CLAUDE" 2>/dev/null; then
    pass "C1: Root CLAUDE.md has a routing table"
  else
    blocker "C1: Root CLAUDE.md has no routing table"
  fi
else
  blocker "C1: Root CLAUDE.md missing — cannot check routing"
fi

# C2: All file references in .md files are valid — NO whitelist, check ALL paths (ERROR)
c2_ok=true
c2_checked=0
while IFS= read -r mdfile; do
  lineno=0
  while IFS= read -r line; do
    ((lineno++))
    # Extract file paths from backticks, markdown links, and plain references
    # Pattern: paths ending in .md or .sh, containing at least one /
    while IFS= read -r link; do
      [ -z "$link" ] && continue
      # Skip URLs
      [[ "$link" == http* ]] && continue
      # Skip variables/templates/globs
      [[ "$link" == *'$'* ]] && continue
      [[ "$link" == *'<'* ]] && continue
      [[ "$link" == *'{'* ]] && continue
      [[ "$link" == *'*'* ]] && continue
      [[ "$link" == *'['* ]] && continue
      [[ "$link" == *'~'* ]] && continue
      # Skip example/template paths
      [[ "$link" == path/* ]] && continue
      [[ "$link" == */X.md ]] && continue
      # Skip command-like references
      [[ "$link" == bash* ]] && continue
      [[ "$link" == npm* ]] && continue
      [[ "$link" == git* ]] && continue
      [[ "$link" == ssh* ]] && continue
      [[ "$link" == cd\ * ]] && continue
      [[ "$link" == cat\ * ]] && continue
      [[ "$link" == grep* ]] && continue
      [[ "$link" == head\ * ]] && continue
      [[ "$link" == ls\ * ]] && continue
      [[ "$link" == GET\ * ]] && continue
      # Must contain at least one slash (path, not just a filename in text)
      [[ "$link" == *"/"* ]] || continue

      ((c2_checked++))

      # Try resolving: relative to TARGET, then relative to file's directory
      if [ ! -f "$TARGET/$link" ] && [ ! -d "$TARGET/$link" ] && \
         [ ! -f "$(dirname "$mdfile")/$link" ] && [ ! -d "$(dirname "$mdfile")/$link" ]; then
        # Also try as absolute path
        if [ ! -f "$link" ] && [ ! -d "$link" ]; then
          rel_mdfile="${mdfile#$TARGET/}"
          error "C2: Broken link in $rel_mdfile:$lineno -> $link"
          c2_ok=false
        fi
      fi
    done < <(echo "$line" | grep -oE '`[^`]+\.(md|sh|yml|yaml|json)`' 2>/dev/null | sed 's/`//g')

    # Also check markdown link syntax [text](path)
    while IFS= read -r link; do
      [ -z "$link" ] && continue
      [[ "$link" == http* ]] && continue
      [[ "$link" == *'$'* ]] && continue
      [[ "$link" == *'<'* ]] && continue
      [[ "$link" == *'{'* ]] && continue
      [[ "$link" == *'*'* ]] && continue
      [[ "$link" == *'['* ]] && continue
      [[ "$link" == *'~'* ]] && continue
      [[ "$link" == path/* ]] && continue
      [[ "$link" == */X.md ]] && continue
      [[ "$link" == *"/"* ]] || continue
      [[ "$link" == "#"* ]] && continue

      ((c2_checked++))

      if [ ! -f "$TARGET/$link" ] && [ ! -d "$TARGET/$link" ] && \
         [ ! -f "$(dirname "$mdfile")/$link" ] && [ ! -d "$(dirname "$mdfile")/$link" ]; then
        if [ ! -f "$link" ] && [ ! -d "$link" ]; then
          rel_mdfile="${mdfile#$TARGET/}"
          error "C2: Broken link in $rel_mdfile:$lineno -> $link"
          c2_ok=false
        fi
      fi
    done < <(echo "$line" | grep -oE '\]\([^)]+\)' 2>/dev/null | sed 's/\](//;s/)$//' | grep -E '\.(md|sh|yml|yaml|json)$')

  done < "$mdfile"
done < <(find "$TARGET" -name "*.md" -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/archive/*' 2>/dev/null)
$c2_ok && pass "C2: All file references valid ($c2_checked checked)"

# C3: No duplicate content blocks (>5 identical consecutive lines across files) (WARNING)
c3_ok=true
dup_tmp=$(mktemp)
# Collect 5-line blocks from all .md files and hash them
while IFS= read -r mdfile; do
  total_lines=$(wc -l < "$mdfile" | tr -d ' ')
  if [ "$total_lines" -ge 5 ]; then
    i=1
    while [ $i -le $((total_lines - 4)) ]; do
      block_hash=$(sed -n "${i},$((i+4))p" "$mdfile" | md5 2>/dev/null || sed -n "${i},$((i+4))p" "$mdfile" | md5sum 2>/dev/null | cut -d' ' -f1)
      # Skip blocks that are mostly empty or just formatting
      block_content=$(sed -n "${i},$((i+4))p" "$mdfile" | tr -d '[:space:]|#-')
      if [ ${#block_content} -gt 20 ]; then
        echo "$block_hash|$mdfile:$i" >> "$dup_tmp"
      fi
      ((i += 5))
    done
  fi
done < <(find "$TARGET" -name "*.md" -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/archive/*' 2>/dev/null)

if [ -f "$dup_tmp" ] && [ -s "$dup_tmp" ]; then
  while IFS= read -r hash; do
    locations=$(grep "^${hash}|" "$dup_tmp" | cut -d'|' -f2 | head -5)
    loc_count=$(grep -c "^${hash}|" "$dup_tmp")
    if [ "$loc_count" -ge 2 ]; then
      # Check that locations are in DIFFERENT files
      files=$(grep "^${hash}|" "$dup_tmp" | cut -d'|' -f2 | cut -d':' -f1 | sort -u)
      file_count=$(echo "$files" | wc -l | tr -d ' ')
      if [ "$file_count" -ge 2 ]; then
        first_two=$(echo "$locations" | head -2 | tr '\n' ' ')
        warn "C3: Duplicate content block found in: $first_two"
        c3_ok=false
        break  # Report only first duplicate to avoid noise
      fi
    fi
  done < <(cut -d'|' -f1 "$dup_tmp" | sort | uniq -d)
fi
rm -f "$dup_tmp"
$c3_ok && pass "C3: No duplicate content blocks"

# C4: knowledge/INDEX.md contains all files from subdirectories (WARNING)
if [ -f "$TARGET/knowledge/INDEX.md" ]; then
  c4_ok=true
  while IFS= read -r kfile; do
    basename_kfile=$(basename "$kfile")
    [[ "$basename_kfile" == "INDEX.md" ]] && continue
    if ! grep -q "$basename_kfile" "$TARGET/knowledge/INDEX.md" 2>/dev/null; then
      warn "C4: $kfile not listed in knowledge/INDEX.md"
      c4_ok=false
    fi
  done < <(find "$TARGET/knowledge" -name "*.md" -not -name "INDEX.md" -not -path '*/archive/*' 2>/dev/null)
  $c4_ok && pass "C4: knowledge/INDEX.md covers all files"
else
  if [ -d "$TARGET/knowledge" ]; then
    warn "C4: knowledge/INDEX.md missing — cannot verify coverage"
  else
    pass "C4: No knowledge/ directory — skipped"
  fi
fi

# C5: No circular references in "передай" / "forward to" / "delegate" (WARNING)
c5_ok=true
# Build a simple directed graph of agent references
graph_tmp=$(mktemp)
while IFS= read -r mdfile; do
  from=$(basename "$mdfile" .md)
  # Look for delegation patterns
  while IFS= read -r target; do
    target_clean=$(echo "$target" | sed 's/`//g; s/\.md//g' | xargs)
    [ -n "$target_clean" ] && echo "$from -> $target_clean" >> "$graph_tmp"
  done < <(grep -iE '(передай|forward|delegate|→|эскалируй)' "$mdfile" 2>/dev/null | grep -oE '`[^`]+\.md`' | sed 's/`//g' | sed 's/\.md//')
done < <(find "$TARGET" -name "*.md" -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null)

if [ -f "$graph_tmp" ] && [ -s "$graph_tmp" ]; then
  # Simple cycle detection: for each node, follow edges up to depth 10
  while IFS= read -r start_node; do
    current="$start_node"
    visited="$start_node"
    depth=0
    cycle_found=false
    while [ $depth -lt 10 ]; do
      next=$(grep "^$current -> " "$graph_tmp" 2>/dev/null | head -1 | awk -F' -> ' '{print $2}')
      [ -z "$next" ] && break
      if echo "$visited" | grep -q "^${next}$"; then
        warn "C5: Circular reference detected: $visited -> $next"
        c5_ok=false
        cycle_found=true
        break
      fi
      visited="$visited
$next"
      current="$next"
      ((depth++))
    done
    $cycle_found && break
  done < <(awk -F' -> ' '{print $1}' "$graph_tmp" | sort -u)
fi
rm -f "$graph_tmp"
$c5_ok && pass "C5: No circular references detected"

echo ""

# ============================================================
# D. KNOWLEDGE & DATA (5 checks)
# ============================================================
echo -e "${CYAN}[D. Knowledge & Data]${NC}"

# D1: knowledge/ is not empty (>= 3 md files) (WARNING)
if [ -d "$TARGET/knowledge" ]; then
  k_count=$(find "$TARGET/knowledge" -name "*.md" -not -name "INDEX.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$k_count" -ge 3 ]; then
    pass "D1: knowledge/ has $k_count md files"
  else
    warn "D1: knowledge/ has only $k_count md files (minimum: 3)"
  fi
else
  warn "D1: knowledge/ directory not found"
fi

# D2: No empty md files (ERROR)
d2_ok=true
while IFS= read -r mdfile; do
  lines=$(wc -l < "$mdfile" | tr -d ' ')
  if [ "$lines" -lt 2 ]; then
    rel="${mdfile#$TARGET/}"
    error "D2: Empty md file: $rel ($lines lines)"
    d2_ok=false
  fi
done < <(find "$TARGET" -name "*.md" -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/archive/*' -not -name "DEPRECATED*" 2>/dev/null)
$d2_ok && pass "D2: No empty md files"

# D3: No TODO stubs in md files (WARNING)
d3_ok=true
while IFS= read -r mdfile; do
  todo_count=$(grep -ciE '(TODO|FIXME|PLACEHOLDER|ЗАГЛУШКА)' "$mdfile" 2>/dev/null | head -1 || true)
  todo_count=${todo_count:-0}
  todo_count=$(echo "$todo_count" | tr -d '[:space:]')
  if [ "$todo_count" -gt 0 ] 2>/dev/null; then
    rel="${mdfile#$TARGET/}"
    warn "D3: $rel has $todo_count TODO/FIXME stubs"
    d3_ok=false
  fi
done < <(find "$TARGET" -name "*.md" -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/archive/*' 2>/dev/null)
$d3_ok && pass "D3: No TODO stubs found"

# D4: All md files <= 300 lines (WARNING, excluding walkthrough/guide files)
d4_ok=true
while IFS= read -r mdfile; do
  basename_file=$(basename "$mdfile")
  # Exclude walkthrough and guide files
  [[ "$basename_file" == *walkthrough* ]] && continue
  [[ "$basename_file" == *guide* ]] && continue
  [[ "$basename_file" == *tutorial* ]] && continue
  lines=$(wc -l < "$mdfile" | tr -d ' ')
  if [ "$lines" -gt 300 ]; then
    rel="${mdfile#$TARGET/}"
    warn "D4: $rel is $lines lines (limit: 300)"
    d4_ok=false
  fi
done < <(find "$TARGET" -name "*.md" -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/archive/*' 2>/dev/null)
$d4_ok && pass "D4: All md files <= 300 lines"

# D5: ops/ directory exists (WARNING)
if [ -d "$TARGET/ops" ]; then
  pass "D5: ops/ directory exists"
else
  warn "D5: ops/ directory not found"
fi

echo ""

# ============================================================
# SUMMARY
# ============================================================
TOTAL=$((PASS + WARN + ERROR + BLOCKER))
SCORE=$((100 - BLOCKER * 10 - ERROR * 5 - WARN * 2))
[ "$SCORE" -lt 0 ] && SCORE=0

echo -e "${BOLD}Summary:${NC} ${GREEN}$PASS PASS${NC} | ${YELLOW}$WARN WARN${NC} | ${RED}$ERROR ERROR${NC} | ${RED}${BOLD}$BLOCKER BLOCKER${NC}"
echo -e "${BOLD}Score: ${SCORE}/100${NC}"
echo ""

# Print issues
if [ "$BLOCKER" -gt 0 ]; then
  echo -e "${RED}${BOLD}BLOCKERS (must fix):${NC}"
  echo -e "$BLOCKER_LIST"
  echo ""
fi

if [ "$ERROR" -gt 0 ]; then
  echo -e "${RED}ERRORS (should fix):${NC}"
  echo -e "$ERROR_LIST"
  echo ""
fi

if [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}WARNINGS (nice to fix):${NC}"
  echo -e "$WARN_LIST"
  echo ""
fi

# Exit code
if [ "$BLOCKER" -gt 0 ]; then
  exit 1
else
  exit 0
fi
