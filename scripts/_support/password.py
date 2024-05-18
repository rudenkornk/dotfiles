import secrets


def generate_password(alphabet: str, length: int) -> str:
    password = "".join(secrets.choice(alphabet) for _ in range(length))
    return password
