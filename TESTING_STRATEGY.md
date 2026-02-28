# Testing Strategy Notes

Testing matrix: **2 docker modes** (dind, dood) x **2 display modes** (wslg, x11) = **4 combinations**.

## Strategy 1: Manual smoke tests (immediate)

Checklist per combination:

- [ ] `vsc-wslg build <mode>` succeeds
- [ ] `vsc-wslg up <profile> <mode>` launches VS Code window
- [ ] VS Code renders correctly (not blank/black window)
- [ ] Terminal inside VS Code works
- [ ] Docker commands work inside container (`docker ps`)
- [ ] Audio plays (optional, PulseAudio)
- [ ] `vsc-wslg down` / `vsc-wslg clean` cleanly stops and removes resources
- [ ] Instance detection works (launch second instance, get prompted)

Environments needed:
- WSL2 with WSLg enabled (Windows 11)
- Ubuntu VM with XFCE (or any X11-based desktop)

## Strategy 2: Automated unit tests for the launcher (bats)

Test `vsc-wslg` and `detect_display_mode()` with bats (Bash Automated Testing System, already in the devops profile):

- Mock `/proc/sys/fs/binfmt_misc/WSLInterop` to simulate WSL detection
- Verify correct compose file chain is built for each display mode
- Verify `HOST_XAUTHORITY` and `HOST_XDG_RUNTIME_DIR` are exported only in x11 mode
- Verify Xauthority warning when file doesn't exist
- Test argument parsing still works (no regressions in mode/profile handling)

## Strategy 3: Container-level integration tests

Use `docker compose config` (dry-run) to validate the merged compose output:

```bash
# Verify WSLg compose includes /mnt/wslg mount and DISPLAY_MODE=wslg
docker compose -f base.yml -f dind.yml -f wslg.yml config | grep -q '/mnt/wslg'
docker compose -f base.yml -f dind.yml -f wslg.yml config | grep -q 'DISPLAY_MODE=wslg'

# Verify X11 compose includes Xauthority mount and DISPLAY_MODE=x11
docker compose -f base.yml -f dood.yml -f x11.yml config | grep -q 'DISPLAY_MODE=x11'
docker compose -f base.yml -f dood.yml -f x11.yml config | grep -q '.Xauthority'

# Verify base compose does NOT contain WSLg-specific entries
docker compose -f base.yml -f dind.yml -f wslg.yml config | grep -vq 'WAYLAND_DISPLAY'  # should fail for wslg
```

These can run in CI without a GUI (compose config is a dry-run).

## Strategy 4: CI pipeline (GitHub Actions)

- **Build matrix**: test image build for both docker modes (dind/dood) - no display needed
- **Compose config validation**: run strategy 3 checks for all 4 combinations
- **Launcher unit tests**: run bats tests (strategy 2)
- **Note**: actual GUI rendering can't be tested in CI (no X server) - that stays manual

## Priority

1. Strategy 3 first (fast, scriptable, no GUI needed, catches compose misconfigurations)
2. Strategy 2 next (catches launcher logic regressions)
3. Strategy 1 for final validation on real environments
4. Strategy 4 when/if CI is set up
