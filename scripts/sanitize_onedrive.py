#!/usr/bin/env python3
"""Sanitize file and folder names in OneDrive for upload compatibility.

Global:
    ONEDRIVE_DIR = '/home/niko/OneDrive'

Features:
 - Walks the directory tree (bottom-up), sanitizes each path segment
   (removes/replaces invalid characters, trims spaces/dots, handles reserved names),
   and renames in-place (no copies left behind).
 - Sends desktop notifications via `notify-send` on Linux when a rename occurs.
 - Offers --dry-run and --verbose modes.
    - Skips active sync work to avoid racing external tools (e.g. PFERD/onedrive):
            * files matching temporary patterns like "*.tmp.*"
            * directories containing such temporary files
            * recently modified paths (configurable grace period)

Note: Run with care. Prefer --dry-run first.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
import unicodedata
from pathlib import Path
from typing import Optional

# Global OneDrive directory (user requested)
ONEDRIVE_DIR = '/home/niko/OneDrive'

# Characters not allowed in OneDrive/SharePoint/Windows file names
INVALID_CHARS_RE = re.compile(r'["\*:<>\\?/\|]')

# Reserved names (Windows/SharePoint)
RESERVED_NAMES = {"CON","PRN","AUX","NUL"} | {f"COM{i}" for i in range(10)} | {f"LPT{i}" for i in range(10)}


def normalize_unicode(name: str) -> str:
    # Normalize to NFC to avoid weird decomposed characters
    return unicodedata.normalize("NFC", name)


def sanitize_segment(name: str, *, is_dir: bool = False) -> str:
    """Return a sanitized single path segment (file or folder name).

    Rules applied:
    - Normalize unicode
    - Strip leading/trailing spaces; strip trailing dots for files only (keep for dirs)
    - Replace invalid characters with underscore
    - Convert names starting with '~$' (Office temp) to 'x_' + rest
    - Handle reserved names by appending an underscore
    - Trim each segment to 255 characters (preserving extension if present)
    """
    if not name:
        return name

    name = normalize_unicode(name)

    # Strip leading/trailing spaces
    name = name.strip()

    # Remove trailing dots for files; keep for directories as requested
    if not is_dir:
        name = name.rstrip('.')

    # Handle Office temp prefix
    if name.startswith('~$'):
        name = 'x_' + name[2:]

    # Replace invalid characters with underscore
    name = INVALID_CHARS_RE.sub('_', name)

    # If name is a reserved name (case-insensitive), append underscore
    if name.upper() in RESERVED_NAMES or name.upper().split('.')[0] in RESERVED_NAMES:
        name = name + '_'

    # Enforce max segment length (255). Try to preserve extension.
    max_len = 255
    if len(name) > max_len:
        # preserve extension
        p = name.rpartition('.')
        if p[1] == '':
            name = name[:max_len]
        else:
            ext = p[2]
            base = p[0]
            keep = max_len - (len(ext) + 1)
            if keep <= 0:
                # no room for base, just truncate the whole thing
                name = name[:max_len]
            else:
                name = base[:keep] + '.' + ext

    # Avoid empty names
    if not name:
        name = '_'

    return name


def unique_name_in_dir(parent: Path, name: str) -> Path:
    """If name exists in parent, append a numeric suffix until unique.

    Example: file.txt -> file_1.txt
    """
    candidate = parent / name
    if not candidate.exists():
        return candidate

    p = name.rpartition('.')
    base, dot, ext = p[0], p[1], p[2]
    counter = 1
    while True:
        if dot:
            new_name = f"{base}_{counter}.{ext}"
        else:
            new_name = f"{name}_{counter}"
        candidate = parent / new_name
        if not candidate.exists():
            return candidate
        counter += 1


def send_notification(summary: str, body: str) -> None:
    """Try to send a desktop notification using notify-send; otherwise print."""
    try:
        subprocess.run(["notify-send", summary, body], check=False)
    except FileNotFoundError:
        # notify-send not available; fallback to printing
        print(f"NOTIFY: {summary} - {body}")


TEMP_FILE_PATTERNS = (
    # PFERD style: <name>.tmp.<random>
    re.compile(r"\.tmp\.[^/]+$"),
    # Generic temporary endings
    re.compile(r"\.partial$"),
)


def is_temp_like(name: str) -> bool:
    """Heuristics to detect temporary/sync-in-progress files we must not touch."""
    # Office temp prefix already handled elsewhere but keep here just in case
    if name.startswith('~$'):
        return True
    for pat in TEMP_FILE_PATTERNS:
        if pat.search(name):
            return True
    return False


def dir_contains_active_work(path: Path, grace_seconds: int, now: Optional[float] = None) -> bool:
    """Return True if directory subtree appears to be under active modification.

    Signals:
      - Any file/dir mtime newer than (now - grace_seconds)
      - Any filename matching temp-like patterns (e.g., *.tmp.*)
    """
    if now is None:
        now = time.time()

    threshold = now - grace_seconds
    for dpath, dnames, fnames in os.walk(path):
        dp = Path(dpath)
        try:
            if dp.stat().st_mtime >= threshold:
                return True
        except FileNotFoundError:
            return True
        for n in fnames:
            if is_temp_like(n):
                return True
            try:
                if (dp / n).stat().st_mtime >= threshold:
                    return True
            except FileNotFoundError:
                return True
    return False


def sanitize_tree(root: Path, dry_run: bool = True, verbose: bool = False, grace_seconds: int = 600) -> int:
    """Walk the tree bottom-up and sanitize names. Returns number of renames."""
    if not root.exists():
        raise FileNotFoundError(f"Root path does not exist: {root}")

    renames = 0
    now_ts = time.time()

    # Walk bottom-up so we rename children before parent directories
    for dirpath, dirnames, filenames in os.walk(root, topdown=False):
        parent = Path(dirpath)

        # Files
        for fname in filenames:
            old_path = parent / fname
            # Skip symlinks to avoid surprises
            if old_path.is_symlink():
                if verbose:
                    print(f"Skipping symlink: {old_path}")
                continue

            # Skip hidden (dot) files entirely
            if fname.startswith('.'):
                if verbose:
                    print(f"Skipping dotfile: {old_path}")
                continue

            # Skip temp-like files or very recently modified files
            if is_temp_like(fname):
                if verbose:
                    print(f"Skipping temp-like file: {old_path}")
                continue
            try:
                if old_path.stat().st_mtime >= now_ts - grace_seconds:
                    if verbose:
                        print(f"Skipping recently modified file: {old_path}")
                    continue
            except FileNotFoundError:
                # If it vanished mid-scan, treat as active
                if verbose:
                    print(f"Skipping vanished file (likely active): {old_path}")
                continue

            new_fname = sanitize_segment(fname)
            if new_fname == fname:
                continue

            target = unique_name_in_dir(parent, new_fname)

            if dry_run:
                print(f"[DRY] Rename file: {old_path} -> {target}")
            else:
                try:
                    old_path.rename(target)
                except Exception as e:
                    print(f"Failed to rename {old_path} -> {target}: {e}", file=sys.stderr)
                    continue
                send_notification("OneDrive: Renamed file", f"{old_path} -> {target}")
            renames += 1

        # Directories
        # Note: dirnames is a list of directory names in the current dir
        for dname in dirnames:
            old_dir = parent / dname
            # Skip symlinks
            if old_dir.is_symlink():
                if verbose:
                    print(f"Skipping symlink dir: {old_dir}")
                continue

            # Skip hidden top-level dirs (start with '.') to avoid surprising app behavior
            if dname.startswith('.'):
                if verbose:
                    print(f"Skipping hidden dir: {old_dir}")
                continue

            # Skip directories that appear active (temp files or recent mtimes)
            try:
                if old_dir.stat().st_mtime >= now_ts - grace_seconds:
                    if verbose:
                        print(f"Skipping recently modified dir: {old_dir}")
                    continue
            except FileNotFoundError:
                if verbose:
                    print(f"Skipping vanished dir (likely active): {old_dir}")
                continue
            if dir_contains_active_work(old_dir, grace_seconds, now=now_ts):
                if verbose:
                    print(f"Skipping active dir (contains temp/young files): {old_dir}")
                continue

            new_dname = sanitize_segment(dname, is_dir=True)
            if new_dname == dname:
                continue

            target = unique_name_in_dir(parent, new_dname)
            if dry_run:
                print(f"[DRY] Rename dir: {old_dir} -> {target}")
            else:
                try:
                    old_dir.rename(target)
                except Exception as e:
                    print(f"Failed to rename dir {old_dir} -> {target}: {e}", file=sys.stderr)
                    continue
                send_notification("OneDrive: Renamed folder", f"{old_dir} -> {target}")
            renames += 1

    return renames


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Sanitize OneDrive filenames for upload compatibility.")
    p.add_argument("root", nargs='?', default=ONEDRIVE_DIR,
                   help=f"Root OneDrive folder to scan (default: {ONEDRIVE_DIR})")
    p.add_argument("--dry-run", action="store_true", help="Show what would be renamed without changing files")
    p.add_argument("--verbose", action="store_true", help="Verbose output")
    p.add_argument("--yes", action="store_true", help="Do changes without asking for confirmation")
    p.add_argument("--grace-seconds", type=int, default=600,
                   help="Skip paths modified within this many seconds and any temp-like trees (default: 600)")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    root = Path(args.root).expanduser().resolve()

    print(f"Scanning: {root}")
    if not args.dry_run and not args.yes:
        ans = input("Proceed with renaming (this will rename files in-place)? [y/N]: ")
        if ans.lower() != 'y':
            print("Aborted by user.")
            return

    try:
        count = sanitize_tree(root, dry_run=args.dry_run, verbose=args.verbose, grace_seconds=args.grace_seconds)
    except FileNotFoundError as e:
        print(e, file=sys.stderr)
        sys.exit(2)

    if args.dry_run:
        print(f"Dry-run: {count} potential renames found.")
    else:
        print(f"Completed: {count} items renamed.")


if __name__ == '__main__':
    main()
