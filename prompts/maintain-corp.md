Maintain the repository's corporate packages by following the encrypted instructions.

For this task, access to `prompts/maintain-corp.md.sops` and
`nix/secrets/corp/packages_info.sops.json` is explicitly authorized.
All other secrets remain off-limits.
Do not display secret values or write decrypted content to disk.

From the repository root, execute:

```sh
sops --decrypt prompts/maintain-corp.md.sops
```

Read the decrypted prompt and follow its instructions.
