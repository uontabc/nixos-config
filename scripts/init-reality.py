"""Initialize machine-local REALITY credentials once; never overwrite them."""

import os
from pathlib import Path
import secrets
import subprocess
import sys
import uuid


def initialize(directory):
    if os.geteuid() != 0:
        raise SystemExit("Run reality-init with sudo on the VPS.")
    os.umask(0o077)
    directory = Path(directory)
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    if directory.is_symlink() or directory.stat().st_uid != 0:
        raise SystemExit("Credential directory must be a root-owned directory.")
    names = ("uuid", "private-key", "public-key", "short-id")
    if any((directory / name).exists() or (directory / name).is_symlink() for name in names):
        raise SystemExit("Credentials already exist; refusing to overwrite or rotate them.")
    pair_output = subprocess.check_output(["sing-box", "generate", "reality-keypair"], text=True)
    pair = dict(line.split(":", 1) for line in pair_output.splitlines() if ":" in line)
    private_key = pair["PrivateKey"].strip()
    public_key = pair["PublicKey"].strip()
    values = {
        "uuid": str(uuid.uuid4()),
        "private-key": private_key,
        "public-key": public_key,
        "short-id": secrets.token_hex(4),
    }
    directory.chmod(0o700)
    for name, value in values.items():
        descriptor = os.open(directory / name, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "w") as stream:
            stream.write(value + "\n")
    print(f"Created machine-local credentials in {directory}; no secret values were printed.")


if __name__ == "__main__":
    initialize(sys.argv[1] if len(sys.argv) > 1 else "/var/lib/sing-box-secrets")
