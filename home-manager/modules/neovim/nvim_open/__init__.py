#!/usr/bin/env python
import hashlib
import os
import re
import socket
import sys
from pathlib import Path

import nvr


def find_project_root(initial_path: Path) -> Path:
    project_files = [
        ".git",
        "_darcs",
        ".hg",
        ".bzr",
        ".svn",
        "Makefile",
        "package.json",
        "setup.py",
        "setup.cfg",
        "pyproject.toml",
        "flake.nix",
        "Cargo.toml",
    ]
    for project_file in project_files:
        path = initial_path
        while path.parent != path:
            if (path / project_file).exists():
                return path
            path = path.parent
    return initial_path


open_directly_files = {
    "COMMIT_EDITMSG",
    "MERGE_MSG",
    "TAG_EDITMSG",
    "NOTES_EDITMSG",
    "PULLREQ_EDITMSG",
    "SQUASH_MSG",
    "git-rebase-todo",
}
# zsh's Ctrl-X Ctrl-E
open_directly_regexes = [re.compile(r"^.*zsh.*\.zsh$")]


def should_open_directly(path: Path) -> bool:
    if path.name in open_directly_files:
        return True
    match = (r.match(str(path)) is not None for r in open_directly_regexes)
    return any(match)


def filter_args(args: list[str]) -> list[str]:
    new_args = []
    while args:
        arg = args.pop(0)
        match arg:
            case "-c" | "-t" | "-L" | "-u":
                if args:
                    args.pop(0)
            case "--":
                new_args += args
                return new_args
            case arg if re.match(r"-[a-zA-Z]+", arg) is not None:
                pass
            case arg if re.match(r"--[a-zA-Z]+", arg) is not None:
                pass
            case arg if re.match(r"\+[a-zA-Z0-9]+", arg) is not None:
                pass
            case _:
                new_args.append(arg)
    return new_args


def main() -> None:
    line = "0"
    project_root = Path.cwd()
    args = filter_args(sys.argv[1:])
    if len(args) >= 1:
        path = Path(args[0])
        splitted = path.name.split(":")
        # len == 2: file:line, len == 3: file:line:column
        if len(splitted) == 2 or len(splitted) == 3:
            path = path.parent.joinpath(splitted[0])
            if path.exists():
                line = splitted[1]
                args[0] = str(path.resolve())
        if path.is_file():
            project_root = find_project_root(path.parent.resolve())
        else:
            project_root = path.parent.resolve()
        if should_open_directly(path):
            os.execlp("nvim", "nvim", str(path))  # noqa: S606

    sock_hash = hashlib.blake2s(str(project_root).encode("utf-8")).hexdigest()
    sock = Path.home().joinpath(".data/nvim/").joinpath(f"sock-{sock_hash}")

    if sock.exists():
        # cleanup stale socket
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(str(sock))
        except ConnectionRefusedError:
            sock.unlink()

    os.environ["TTY"] = str(os.ttyname(sys.stdout.fileno()))
    os.environ["NVIM_LISTEN_ADDRESS"] = str(sock)

    vim_commands = ""
    if project_root.exists():
        if project_root.is_dir():
            vim_commands = f"lcd {project_root}"
    else:
        try:
            project_root.mkdir(parents=True, exist_ok=True)
            vim_commands += f"lcd {project_root}"
        except OSError:
            pass
    vim_commands += " | RaiseTmuxPane"

    args = [
        "nvr",
        f"+{line}",
        "-cc",
        vim_commands,
        "--remote-silent",
        "-s",
    ] + sys.argv[1:]
    return nvr.main(args)


if __name__ == "__main__":
    main()
