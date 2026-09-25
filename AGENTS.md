# Dotfiles Repository Notes

- Avoid changing `IFS` when a pipe-based command stays readable.
- Prefer the most readable shell over defensive parsing or micro-optimizations.
- Make reasonable simplifying assumptions when they keep scripts obvious.
- Temporary regression checks are fine while developing a fix.
- The regression suite lives in `test/`; run it with `test/run` after changing
  any shell configuration, and add to it when adding a feature. See
  [`test/README.md`](test/README.md) for the harness.
