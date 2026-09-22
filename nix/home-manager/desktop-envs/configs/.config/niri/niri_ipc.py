# ruff: noqa: INP001

import json
import os
import socket
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from typing import cast

type Request = Callable[[str | dict[str, object]], object]


@contextmanager
def connection() -> Iterator[Request]:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(2)
        client.connect(os.environ["NIRI_SOCKET"])
        with client.makefile("rb") as response:

            def request(payload: str | dict[str, object]) -> object:
                client.sendall(json.dumps(payload).encode() + b"\n")
                reply = json.loads(response.readline())
                if "Err" in reply:
                    raise RuntimeError(reply["Err"])
                return cast("object", reply["Ok"])

            yield request
