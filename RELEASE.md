# Release process

This document simply outlines the release process:

1. Ensure you are running on the oldest supported Elixir version (check `.travis.yml`)

2. Ensure `CHANGELOG.md` is updated and add current date

3. Change the version number in `mix.exs` and `README.md`

4. Run `mix test` to ensure all tests pass

5. Commit changes above with title "Release vVERSION" and push to GitHub

    git add .
    git commit -m"Release vX.Y.Z"
    git push origin master

6. Check CI is green

7. Create a release on GitHub and add the CHANGELOG from step #2 (https://github.com/graphql-elixir/graphql/releases/new) using VERSION as the tag and title

8. Publish new hex release with `mix hex.publish`

9. Publish hex docs with `mix hex.docs`

10. Update upstream repos `plug_graphql` and `graphql_relay` and release as appropriate

## Deprecation policy

GraphQL deprecations happen in 3 steps:

  1. The feature is soft-deprecated. It means both CHANGELOG and documentation must list the feature as deprecated but no warning is effectively emitted by running the code. There is no requirement to soft-deprecate a feature.

  2. The feature is effectively deprecated by emitting warnings on usage. In order to deprecate a feature, the proposed alternative MUST exist for AT LEAST two versions.

  3. The feature is removed. This can only happen on major releases.
