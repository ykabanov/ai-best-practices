#!/bin/sh
input=$(cat)

# ANSI color codes
bold_green='\033[1;32m'
cyan='\033[0;36m'
bold_blue='\033[1;34m'
red='\033[0;31m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
green='\033[0;32m'
dim='\033[2m'
reset='\033[0m'

# Extract every field in a SINGLE jq pass (one process instead of seven).
# Each comma-separated expression prints on its own line; "// \"\"" turns
# null/absent fields into empty strings so line alignment is preserved.
fields=$(echo "$input" | jq -r '
  (.cwd // .workspace.current_dir) // "",
  .model.display_name // "",
  .pr.number // "",
  .pr.review_state // "",
  .effort.level // "",
  .context_window.used_percentage // "",
  .cost.total_cost_usd // ""
' 2>/dev/null)

# Read the 7 lines into variables (IFS= / -r preserve spaces in paths & names).
{
  IFS= read -r cwd
  IFS= read -r model_name
  IFS= read -r pr_num
  IFS= read -r pr_state
  IFS= read -r effort
  IFS= read -r pct
  IFS= read -r cost_raw
} <<EOF
$fields
EOF

# Current directory basename via parameter expansion (no basename subprocess)
dir=${cwd##*/}

# Build git info using git commands (skip optional locks)
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if git -C "$cwd" status --porcelain 2>/dev/null | grep -q .; then
      git_info=$(printf " ${bold_blue}git:(${red}%s${blue})${reset} ${yellow}✗${reset}" "$branch")
    else
      git_info=$(printf " ${bold_blue}git:(${red}%s${blue})${reset}" "$branch")
    fi
  fi
fi

# Model name segment
model_segment=""
if [ -n "$model_name" ]; then
  model_segment=$(printf "  ${magenta}%s${reset}" "$model_name")
fi

# PR segment (placed after git_info in the output line)
pr_segment=""
if [ -n "$pr_num" ]; then
  case "$pr_state" in
    approved)          mark="${green}✓${reset}" ;;
    changes_requested) mark="${red}✗${reset}" ;;
    pending)           mark="${yellow}⋯${reset}" ;;
    draft)             mark="${dim}draft${reset}" ;;
    *)                 mark="" ;;
  esac
  pr_segment=$(printf "  ${cyan}PR#%s${reset} %b" "$pr_num" "$mark")
fi

# Reasoning effort segment (placed after model_segment)
effort_segment=""
[ -n "$effort" ] && effort_segment=$(printf "  ${dim}⚡%s${reset}" "$effort")

# Context window usage segment (reads pre-calculated field from stdin JSON)
ctx_segment=""
if [ -n "$pct" ]; then
  pct=${pct%.*}                       # strip any decimal
  if [ "$pct" -ge 80 ]; then ctx_color="$red"
  elif [ "$pct" -ge 50 ]; then ctx_color="$yellow"
  else ctx_color="$green"; fi
  ctx_segment=$(printf "  ${ctx_color}ctx %d%%${reset}" "$pct")
fi

# Session cost segment
cost_segment=""
if [ -n "$cost_raw" ] && [ "$cost_raw" != "0" ] && [ "$cost_raw" != "0.0" ]; then
  # Format to 2 decimal places using awk (faster than bc, available everywhere)
  cost_fmt=$(awk -v c="$cost_raw" 'BEGIN { printf "%.2f", c }' 2>/dev/null)
  if [ -n "$cost_fmt" ] && [ "$cost_fmt" != "0.00" ]; then
    cost_segment=$(printf "  ${dim}\$%s${reset}" "$cost_fmt")
  fi
fi

printf "${bold_green}➜${reset}  ${cyan}%s${reset}%s%s%s%s%s%s" "$dir" "$git_info" "$pr_segment" "$model_segment" "$effort_segment" "$ctx_segment" "$cost_segment"
