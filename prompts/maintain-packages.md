Maintain the repository's custom packages, version overrides, and patches.

## Investigation

- Inventory explicit package versions, source revisions, patches, and packaging workarounds.
  Distinguish external packages from repository-local utilities and pinned data assets.
- Determine which package set each consumer uses: stable or unstable.
  Neovim plugins use unstable; verify other consumers rather than assuming.
- Compare locked inputs with the latest relevant channel sources.
  Distinguish changes available upstream from changes already available through the current lock.
- Use live nixpkgs queries and upstream release information.
  Cross-check package sources when search indexes are stale or disagree.
- Leave libp11's compatibility pin untouched unless explicitly requested.

## Package decisions

1. If a package exists in nixpkgs, compare its version with the local pin.
   If nixpkgs provides a newer version, recommend removing the local version override
   or replacing the custom package with the nixpkgs package.
   Preserve any independently necessary packaging adjustments.
   Prefer the existing channel; propose unstable when only unstable has a suitable newer version.
   If nixpkgs is not newer, leave the package completely unchanged.
   Do not update its local pin from upstream.
1. If a package is absent from nixpkgs, check for a newer upstream release.
   For packages pinned to commits without releases, check the relevant upstream branch.
   Update only when a newer release or revision exists.
   Verify source and dependency hashes, bundled assets, wrappers, and runtime compatibility.
1. Do not mistake a similarly named package for an equivalent replacement.
   Check that it provides the required executable, skills, assets, and functionality.

## Patches and workarounds

- Check necessity against the latest version in each package's selected channel.
  Do not switch channels solely to eliminate a patch without approval.
- Inspect actual source and packaging behavior, not just issue or pull-request status.
  An open PR may be independently superseded; a merged fix may not yet be packaged.
- Classify each patch as still needed, fully superseded, partially superseded, or uncertain.
- Remove fully superseded patches only when their replacement is available to the selected package.
  Retain necessary portions of partially superseded patches.
  Rebase retained patches when updating their base.
- Check wrappers, substitutions, build dependencies, and test workarounds as well as patch files.
  Do not delete an entire overlay merely because one responsibility became redundant.

## Review and implementation

- Present a recommendation table before editing.
  Include local version, latest relevant nixpkgs version, upstream version where applicable,
  selected channel, proposed action, and supporting evidence.
- Follow repository decision-review requirements.
  Explain input-refresh effects and obtain approval for unresolved scope or compatibility choices.
- Review generated-config changes caused by input updates.
  Preserve custom shortcuts and Russian aliases.
  Ask before accepting new shortcut conflicts or externally visible behavior.
  Edit overlay sources and regenerate; never hand-maintain generated bindings.
- Preserve unrelated work and settings.
  Do not change OmO model assignments as part of package maintenance unless requested.
- Plan focused commit boundaries before implementation.
  Separate dependency preparation, obsolete-workaround removal, package updates, and meaningful integration.
  Follow repository commit and history-maintenance instructions.

## Validation and report

- Run repository formatting, lint, and generated-config checks.
- Build changed packages and verify retained patches against updated inputs.
  Run focused smoke tests for affected functionality, including browser integration,
  native-library loading, or installed skills where relevant.
- Isolate tests from the user's browser profiles, credentials, and running services.
- Keep Nix configuration evaluation and builds near the end.
  Run any required flake check as the final validation step.
- Report updates, removals, unchanged pins, retained patches, validation results, and commits.
  State any remaining uncertainty and whether changes were only committed or also activated.
