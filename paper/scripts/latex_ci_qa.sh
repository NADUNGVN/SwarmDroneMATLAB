#!/usr/bin/env bash
set -euo pipefail

log_path="${1:-paper/main.log}"
report_path="${2:-paper/generated/ci_latex_report.txt}"
paper_dir="$(dirname "$log_path")"
repo_dir="$(cd "$paper_dir/.." && pwd)"
bbl_path="${log_path%.log}.bbl"

if [[ ! -s "$log_path" ]]; then
  echo "LaTeX log is missing or empty: $log_path" >&2
  exit 1
fi
if [[ ! -s "${log_path%.log}.pdf" ]]; then
  echo "Compiled PDF is missing or empty: ${log_path%.log}.pdf" >&2
  exit 1
fi
if [[ ! -s "$bbl_path" ]]; then
  echo "Compiled bibliography is missing or empty: $bbl_path" >&2
  exit 1
fi

count_matches() {
  local pattern="$1"
  local path="$2"
  grep -Eic "$pattern" "$path" || true
}

undefined_citations="$(count_matches 'Citation .+ undefined|There were undefined citations' "$log_path")"
undefined_references="$(count_matches 'Reference .+ undefined|There were undefined references' "$log_path")"
duplicate_labels="$(count_matches 'multiply[- ]defined labels?|Label .+ multiply defined' "$log_path")"
missing_artifacts="$(count_matches 'LaTeX Error: File .+ not found|Package pdftex.def Error: File .+ not found' "$log_path")"
overfull_hbox="$(count_matches 'Overfull \\hbox' "$log_path")"
overfull_vbox="$(count_matches 'Overfull \\vbox' "$log_path")"
underfull_hbox="$(count_matches 'Underfull \\hbox' "$log_path")"
underfull_vbox="$(count_matches 'Underfull \\vbox' "$log_path")"
float_problems="$(count_matches 'Too many unprocessed floats|Float too large|Unprocessed float|Float(s)? (lost|stuck)' "$log_path")"

page_count="$(sed -nE 's/.*Output written on .+\(([0-9]+) pages?.*/\1/p' "$log_path" | tail -n1)"
reference_count="$(grep -Ec '^\\bibitem' "$bbl_path" || true)"
figure_count="$(grep -RhoE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' "$paper_dir/main.tex" "$paper_dir"/sections/*.tex | sort -u | wc -l | tr -d ' ')"
table_count="$(grep -RhoE '\\input\{tables/[^}]+\}' "$paper_dir/main.tex" "$paper_dir"/sections/*.tex | sort -u | wc -l | tr -d ' ')"

mkdir -p "$(dirname "$report_path")"
{
  echo "compiler=pdflatex via latexmk (isolated TeX Live 2025)"
  echo "pdf=paper/main.pdf"
  echo "pages=${page_count:-UNKNOWN}"
  echo "bibliography_entries=$reference_count"
  echo "figures=$figure_count"
  echo "tables=$table_count"
  echo "undefined_citations=$undefined_citations"
  echo "undefined_references=$undefined_references"
  echo "duplicate_labels=$duplicate_labels"
  echo "missing_figures_or_tables=$missing_artifacts"
  echo "overfull_hbox=$overfull_hbox"
  echo "overfull_vbox=$overfull_vbox"
  echo "underfull_hbox=$underfull_hbox"
  echo "underfull_vbox=$underfull_vbox"
  echo "float_placement_problems=$float_problems"
  echo "commit=${GITHUB_SHA:-LOCAL}"
} | tee "$report_path"

failures=0
for value in "$undefined_citations" "$undefined_references" "$duplicate_labels" "$missing_artifacts" "$float_problems" "$overfull_hbox" "$overfull_vbox"; do
  if [[ "$value" -ne 0 ]]; then
    failures=1
  fi
done
if [[ -z "$page_count" ]]; then
  echo "Could not determine PDF page count from LaTeX log." >&2
  failures=1
fi
if [[ "$reference_count" -ne 53 || "$figure_count" -ne 3 || "$table_count" -ne 6 ]]; then
  echo "Unexpected compiled/static counts: references=$reference_count figures=$figure_count tables=$table_count" >&2
  failures=1
fi
if [[ -n "$page_count" && "$page_count" -gt 12 ]]; then
  echo "TCNS initial-submission limit exceeded: pages=$page_count limit=12" >&2
  failures=1
fi
if [[ "$failures" -ne 0 ]]; then
  echo "LaTeX CI QA failed; see $report_path and $log_path." >&2
  exit 1
fi

echo "LATEX_CI_QA_OK citations=0 refs=0 duplicate-labels=0 missing-artifacts=0 overfull-boxes=0"
