# `nix` reproducibility and infrastructure shifts

THIS IS A DRAFT ISSUE, WHICH WAS NEVER PUBLISHED.\
It appears that proposed solution is already active and the issue itself does not exist.
This file is only for history since I spent some time writing it and I want to keep it for future reference.

______________________________________________________________________

**TLDR:** would all existing flakes in different repositories still be reproducible (as claimed) if in a fantastic scenario `github.com` moves its URL?

## The problem

Before I get pelted with rotten tomatoes, let me try to motivate this request with more realistic example.

I would like to consider this organization-oriented scenario.\
Suppose you want to deploy a `nix`-based package management inside a medium-to-large-sized developing organization,
which includes private cache substituters, forks of the most notable repos (`nixpkgs`, `nur`, etc.) and repos with custom flakes for internal organization packages.

However, such developing organizations tend to often change their internal infrastructure due to various business processes.\
For example migrating entire internal `bitbucket` repository base to `gitlab` due to a brand new policy of unification with neighbouring department,
which uses `gitlab`. Or moving entire artifactory storage from `Nexus` to `Artifactory`.\
Examples are arbitrary, but very real (at least to my experience). Unlike a seemingly rock-solid `github.com` locations, internal infrastructure of developing company is volatile.

This, unfortunately, makes flakes seemingly irreproducible. Originally locked URLs inside `flake.lock` and inputs in `flake.nix` may no longer exist after such migration.\
Of course, such infrastructure change may be accompanied by transition period allowing to update lockfiles in all repositories and not to break existing CI.
However, all commits existing before updated lockfiles will eventually become invalid, thus irreproducible.

## Proposed solution

Allow treating flake inputs just like any resource fetched with `FetchContent`. Allow caching them in cache substituters.\
If allowed, all commits can withstand infrastructure shifts, given flake inputs were preventively cached.\
Cache URL itself is a global setting, and can be changed according to infrastructure changes dynamically.

## Alternative solutions

### Registries

Previously it was possible to define inputs in [registry form](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-registry),
which fixes issue at least to some degree (though still missing ability to override URLs).\
Recent changes have disabled [user-level registries](https://discourse.nixos.org/t/nix-2-26-released/59211) with potential removal of registries in flake inputs whatsoever.
[A similar ongoing discussion](https://github.com/NixOS/nix/issues/7422) also suggests disabling registries at all.

### CLI override

There is also a `--override-input <input> <url>` CLI option, but it has downsides, which make it unsuitable for this problem:

1. It does not perform `narHash` checks from `flake.lock`. It does not even take `git` revision from the lockfile.
1. It is inconvenient to use, requiring dynamic crafting of CLI command based on the current state of input URLs.
1. After another internal infrastructure shift it requires from users to re-craft their `nix` commands, instead of one-time regeneration of some global config with registries.

## Additional context

### `nix` already solving this problem for packages

It appears to me that this problem is not completely alien to `nix`.\
`nixpkgs` has tons of dynamically fetched source code for packages with `FetchContent`.\
Allowing using cache for flake inputs would be a natural extension of this existing solution.
For such a large collection it is inevitable for packages to find some of these resources gone permanently or temporarily unavailable, producing unnecessary build failures.
I guess this is one of reasons for having cache substituters at all.

### Other package managers allow similar mechanisms

`poetry` (`python` package manager) does not pin `wheels` URLs in its lockfile (but pins hashes) and allows to define package source dynamically using global settings.\
`cargo` [allows custom registries for `crates` with global config](https://doc.rust-lang.org/cargo/reference/registries.html).\
`uv` has an [ongoing discussion about similar topic](https://github.com/astral-sh/uv/issues/6349). (A good summary of it in [this comment](https://github.com/astral-sh/uv/issues/6349#issuecomment-3036813482).)

## Checklist

- [x] checked [latest Nix manual] ([source])
- [x] checked [open feature issues and pull requests] for possible duplicates

______________________________________________________________________

Add :+1: to [issues you find important](https://github.com/NixOS/nix/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc).

[latest nix manual]: https://nix.dev/manual/nix/development/
[open feature issues and pull requests]: https://github.com/NixOS/nix/labels/feature
[source]: https://github.com/NixOS/nix/tree/master/doc/manual/source
