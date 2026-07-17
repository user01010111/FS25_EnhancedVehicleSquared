# Enhanced Vehicle Squared roadmap

## Project status

Enhanced Vehicle Squared is the active, independent continuation of the
archived Enhanced Vehicle project, maintained and released by `user01010111`
with Enhanced Vehicle Squared contributors. The original project was explicitly
discontinued and made read-only on 17 July 2026 after about 275 days without a
substantive code release. Its owner closed the two outstanding pull requests
unreviewed and unmerged, closed the three outstanding issues as not planned,
and supplied no maintainer response with those closures. No public successor
maintainer or transition plan was identified. We therefore treat upstream as
abandoned for maintenance purposes.

All prepared upstream contribution branches are retired. We will not publish,
rebase, or reconcile them against the archived repository. Their useful changes
live in the Squared history and test suite.

## Release 2.0.0.0

The first Squared release establishes an independently controlled baseline:

- new project, in-game, documentation, icon, and release branding;
- English-only distributed text;
- retained technical mod identity for savegame, binding, configuration, and
  multiplayer compatibility;
- transactional licensed client and dedicated-server acceptance;
- deterministic manifest-selected packaging with shipped license and
  attribution;
- guidance offset, grouped fold, grass/headland, configuration, and dedicated
  lifecycle remediation.

The release is complete only when the exact tagged tree passes source checks,
runtime tests, installed-game contract checks, deterministic package checks,
licensed client acceptance, licensed dedicated-server acceptance, and full
restoration verification.

## Near-term priorities

1. Monitor Farming Simulator 25 updates and keep engine contracts current.
2. Reproduce and fix Squared issues with regression tests before release.
3. Exercise genuine multi-machine multiplayer and document results separately
   from simulated networking and single-host dedicated testing.
4. Expand compatibility coverage for unusual tool carriers, complex fold
   groups, and mod interactions.
5. Improve maintainability without breaking the retained technical ABI.

## Compatibility policy

The following identifiers remain stable unless a future migration release
provides a tested upgrade path:

- `FS25_EnhancedVehicle.zip`;
- `FS25_EnhancedVehicle_*` input actions;
- `modSettings/FS25_EnhancedVehicle` configuration files;
- savegame specialization keys, network event identity, and public Lua globals.

Visible branding may change without changing those interfaces. Any future ABI
break requires an explicit migration design, release note, rollback plan, and
licensed savegame validation.

## Project boundaries

- Development, support, documentation, test output, and releases are English
  only.
- The project is non-commercial under CC BY-NC-SA 4.0.
- Console distribution is out of scope.
- Upstream publication is cancelled while the original repository remains
  archived.
- No release will claim genuine multiplayer validation until multiple real game
  instances have been tested together.
