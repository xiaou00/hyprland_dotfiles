local M = {}

function M.root(path)
    local start = vim.fs.dirname(vim.fn.fnamemodify(path, ":p"))
    local template = vim.fs.find("template.typ", { path = start, upward = true })[1]

    return template and vim.fs.dirname(template) or start
end

function M.command(action, path)
    -- return { "typst", action, "--root", M.root(path), path }
    return { "typst", action, path }
end

function M.atomic_compile_command(path)
    return {
        "bash",
        "-c",
        table.concat({
            "set -euo pipefail",
            'input="$1"',
            'output="${input%.typ}.pdf"',
            'dir="$(dirname -- "$output")"',
            'base="$(basename -- "$output")"',
            'tmp="$(mktemp "${TMPDIR:-/tmp}/typst-atomic.XXXXXX.pdf")"',
            'cleanup() { rm -f -- "$tmp"; }',
            "trap cleanup EXIT",
            'reload_zathura() {',
            '  pkill -HUP -x zathura 2>/dev/null || true',
            '}',
            'typst compile --creation-timestamp 0 "$input" "$tmp"',
            'cp -- "$tmp" "$output"',
            "reload_zathura",
        }, "\n"),
        "typst-atomic-compile",
        path,
    }
end

function M.atomic_watch_command(path)
    return {
        "bash",
        "-c",
        table.concat({
            "set -euo pipefail",
            'input="$1"',
            'output="${input%.typ}.pdf"',
            'dir="$(dirname -- "$output")"',
            'base="$(basename -- "$output")"',
            'tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/typst-watch.XXXXXX")"',
            'tmp_pdf="$tmp_dir/$base"',
            'watch_pid=""',
            'cleanup() {',
            '  if [ -n "$watch_pid" ]; then kill "$watch_pid" 2>/dev/null || true; fi',
            '  rm -rf -- "$tmp_dir"',
            '}',
            "trap cleanup EXIT INT TERM",
            'reload_zathura() {',
            '  pkill -HUP -x zathura 2>/dev/null || true',
            '}',
            'publish_pdf() {',
            '  cp -- "$tmp_pdf" "$output"',
            '  reload_zathura',
            '}',
            'typst compile --creation-timestamp 0 "$input" "$tmp_pdf"',
            "publish_pdf",
            'typst watch --creation-timestamp 0 "$input" "$tmp_pdf" &',
            'watch_pid="$!"',
            'last_seen=""',
            'last_published=""',
            "stable_count=0",
            'while kill -0 "$watch_pid" 2>/dev/null; do',
            '  if [ -s "$tmp_pdf" ]; then',
            '    current="$(stat -c "%Y:%s" -- "$tmp_pdf")"',
            '    if [ "$current" = "$last_seen" ]; then',
            "      stable_count=$((stable_count + 1))",
            "    else",
            '      last_seen="$current"',
            "      stable_count=0",
            "    fi",
            '    if [ "$stable_count" -ge 2 ] && [ "$current" != "$last_published" ]; then',
            "      publish_pdf",
            '      last_published="$current"',
            "    fi",
            "  fi",
            "  sleep 0.25",
            "done",
            'wait "$watch_pid"',
        }, "\n"),
        "typst-atomic-watch",
        path,
    }
end

return M
