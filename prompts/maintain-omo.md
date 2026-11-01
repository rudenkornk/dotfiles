Update the OmO package and configuration in this repository.

1. Inspect the current OmO overlay and configuration.
1. Find the latest stable OmO release and review relevant release notes.
1. Update the overlay version and verify the release asset checksum.
1. Update the configuration schema URL to match the selected release.
   Check existing settings against that schema and handle any required migrations.
1. Review the latest release's model recommendations, agent roles, profiles, and fallback chains.
1. Check newly available models within the provider/model family already used by the OmO configuration.
   For example, retain the ChatGPT subscription pool for a ChatGPT configuration,
   or the Claude pool for a Claude configuration.
   Preserve provider IDs and authentication mode; do not introduce API-billed providers or other families.
   If the configuration mixes families, preserve each role's existing pool.
1. Update model assignments, reasoning levels, and fallback ordering using upstream recommendations
   and verified availability in OmO's engine.
   Distinguish available models from upstream-recommended models.
   Do not promote a newly released model solely because it is newer.
1. Preserve unrelated settings and user changes.
1. Follow repository instructions for decision approval, validation, and commit boundaries.
   Verify configuration compatibility, build the updated package, and run its smoke checks.
1. Summarize the version change, model changes, newly considered models, validation results, and commits.
   Explain any relevant difference between interactive TUI and desktop/headless model selection.

Use release-pinned upstream documentation and source where possible.
Do not treat another client's model catalog as proof of availability in OmO.
If availability or recommendations cannot be verified, report the uncertainty before changing defaults.
