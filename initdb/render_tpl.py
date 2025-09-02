#!/usr/bin/env python3
import re
import os
import sys


def load_dotenv(path):
    if not os.path.isfile(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k not in os.environ:
                os.environ[k] = v


def esc(s):
    if s is None:
        return ""
    return s.replace("'", "''")


def render(tpl_path, out_path):
    s = open(tpl_path, "r", encoding="utf-8").read()

    def repl(m):
        name = m.group(1)
        val = os.environ.get(name, "")
        return esc(val)
    out = re.sub(r'\$\{([^}]+)\}', repl, s)
    open(out_path, "w", encoding="utf-8").write(out)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: render_tpl.py in.tpl out.sql", file=sys.stderr)
        sys.exit(2)
    tpl, out = sys.argv[1], sys.argv[2]

    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dotenv = os.path.join(base, ".env")
    load_dotenv(dotenv)
    render(tpl, out)
