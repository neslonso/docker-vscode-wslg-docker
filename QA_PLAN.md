# Plan Maestro de QA — vsc-wslg-docker

> Documento de planificación. Editar antes de implementar.

## 1. Perfil `profiles/qa/` — Entorno de Testing Containerizado

Nuevo perfil que equipa el contenedor con todas las herramientas de QA.

### `setup.sh` instalará:

- **bats-core** + bats-support + bats-assert + bats-file (unit tests bash)
- **shellcheck** (análisis estático del launcher y scripts)
- **hadolint** (lint del Dockerfile)
- **yamllint** (validación de los docker-compose YAML)
- **jq** (ya está en base, se valida presencia)
- **python3 + pytest** (tests de integración complejos si se necesitan)
- **trivy** (escaneo de vulnerabilidades de la imagen Docker)

### `vscode/extensions.list`:

- Extensiones de testing, shell debugging, YAML, Docker, coverage

### `vscode/settings.json`:

- Configuración orientada a testing (bats runner, shellcheck integration)

---

## 2. Tests Unitarios — bats (Bash Automated Testing System)

Directorio: `tests/unit/`

| Test file | Qué valida |
|---|---|
| `test_detect_display_mode.bats` | `detect_display_mode()` retorna "wslg" o "x11" correctamente mockeando `/mnt/wslg/runtime-dir` |
| `test_argument_parsing.bats` | Parsing de `action`, `profile`, `mode` — todos los combos válidos e inválidos |
| `test_project_naming.bats` | Que `proj_name` se genera correctamente: sanitización, prefijo `vsc_`, caracteres especiales |
| `test_compose_file_chain.bats` | Que se seleccionan los compose files correctos para cada combinación modo×display |
| `test_mode_validation.bats` | Que modos inválidos producen error y exit 1 |
| `test_x11_exports.bats` | Que `HOST_XAUTHORITY` y `HOST_XDG_RUNTIME_DIR` solo se exportan en modo x11 |
| `test_sanitize_jsonc.bats` | Que `sanitize_jsonc()` elimina comentarios y trailing commas correctamente |
| `test_shell_persistence.bats` | Que `setup_shell_persistence()` crea symlinks correctos |

**Estrategia de mocking**: `bats-mock` o stubs de filesystem (tmpdir) para simular `/mnt/wslg/runtime-dir`, `.Xauthority`, etc.

---

## 3. Tests de Integración — Compose Config Validation

Directorio: `tests/integration/`

Estos tests **NO necesitan GUI** — solo validan que el merge de compose files produce la configuración correcta.

| Test | Qué valida |
|---|---|
| `test_compose_dind_wslg.bats` | DinD+WSLg: privileged=true, `/mnt/wslg` mount, `DISPLAY_MODE=wslg`, `INSTALL_DOCKER_DAEMON=true` |
| `test_compose_dind_x11.bats` | DinD+X11: privileged=true, Xauthority mount, `DISPLAY_MODE=x11` |
| `test_compose_dood_wslg.bats` | DooD+WSLg: docker.sock mount, NO privileged, `INSTALL_DOCKER_DAEMON=false` |
| `test_compose_dood_x11.bats` | DooD+X11: docker.sock + Xauthority, NO privileged |
| `test_compose_volumes.bats` | Que los 4 volúmenes persistentes están definidos en todas las combinaciones |
| `test_compose_env_vars.bats` | Variables de entorno comunes presentes: DISPLAY, PULSE_SERVER, WORKSPACE_PATH, etc. |
| `test_dockerfile_build.bats` | Build del Dockerfile para ambos modos (dind/dood) completa sin errores |

**Método**: `docker compose -f ... config` (dry-run) + `yq`/`jq` para parsear el YAML resultante.

---

## 4. Tests E2E — Container Lifecycle

Directorio: `tests/e2e/`

Tests que levantan contenedores reales (sin GUI, headless donde sea posible).

| Test | Qué valida |
|---|---|
| `test_container_boot_dind.bats` | Container DinD arranca, Docker daemon funciona dentro (`docker info`) |
| `test_container_boot_dood.bats` | Container DooD arranca, `docker ps` funciona via socket |
| `test_profile_setup.bats` | Para cada perfil: `setup.sh` ejecuta sin errores, herramientas quedan instaladas |
| `test_profile_idempotency.bats` | Ejecutar `setup.sh` dos veces no rompe nada (flag file funciona) |
| `test_vscode_extensions.bats` | Extensions de un perfil se instalan correctamente (`code --list-extensions`) |
| `test_vscode_settings_merge.bats` | Settings del perfil se mergean correctamente con las base |
| `test_shell_persistence.bats` | Crear archivo en `~/.shell_persist`, recrear container, archivo sigue ahí |
| `test_workspace_mount.bats` | Directorio de proyecto se monta correctamente en `/workspaces/<name>` |
| `test_instance_detection.bats` | Segundo `up` detecta instancia existente |
| `test_down_clean.bats` | `down` para container, `clean` elimina volúmenes |

**Nota**: Los tests E2E de GUI (VSCode renderiza correctamente, WSLg workaround funciona) quedan como **manual smoke tests** porque requieren un display server real.

---

## 5. GitHub Actions CI Pipeline

Archivo: `.github/workflows/qa.yml`

**Triggers**: `push`, `pull_request` (main, develop)

### Jobs:

```
┌─────────────────────────────────────────────┐
│ lint:                                        │
│   - shellcheck vsc-wslg docker/entrypoint.sh │
│     docker/lib/*.sh profiles/*/setup.sh      │
│   - hadolint docker/Dockerfile.base          │
│   - yamllint docker/docker-compose*.yml      │
├─────────────────────────────────────────────┤
│ unit-tests:                                  │
│   - Install bats-core + helpers              │
│   - Run tests/unit/*.bats                    │
├─────────────────────────────────────────────┤
│ integration-tests:                           │
│   - docker compose config validation         │
│   - Matrix: [dind,dood] × [wslg,x11]        │
│   - Run tests/integration/*.bats            │
├─────────────────────────────────────────────┤
│ build-matrix:                                │
│   - Build Dockerfile for dind                │
│   - Build Dockerfile for dood                │
│   - Trivy scan on both images                │
├─────────────────────────────────────────────┤
│ e2e-tests: (needs build-matrix)              │
│   - Boot container (headless, no VSCode)     │
│   - Run tests/e2e/*.bats                     │
│   - Profile setup validation                 │
└─────────────────────────────────────────────┘
```

---

## 6. Estructura de Directorios Resultante

```
docker-vscode-wslg-docker/
├── profiles/
│   └── qa/                          ← NUEVO perfil
│       ├── setup.sh
│       ├── README.md
│       └── vscode/
│           ├── extensions.list
│           └── settings.json
├── tests/                           ← NUEVO directorio
│   ├── helpers/
│   │   ├── setup.bash              (common bats setup)
│   │   └── mocks.bash              (filesystem mocks)
│   ├── unit/
│   │   ├── test_detect_display_mode.bats
│   │   ├── test_argument_parsing.bats
│   │   ├── test_project_naming.bats
│   │   ├── test_compose_file_chain.bats
│   │   ├── test_mode_validation.bats
│   │   ├── test_x11_exports.bats
│   │   ├── test_sanitize_jsonc.bats
│   │   └── test_shell_persistence.bats
│   ├── integration/
│   │   ├── test_compose_dind_wslg.bats
│   │   ├── test_compose_dind_x11.bats
│   │   ├── test_compose_dood_wslg.bats
│   │   ├── test_compose_dood_x11.bats
│   │   ├── test_compose_volumes.bats
│   │   ├── test_compose_env_vars.bats
│   │   └── test_dockerfile_build.bats
│   ├── e2e/
│   │   ├── test_container_boot_dind.bats
│   │   ├── test_container_boot_dood.bats
│   │   ├── test_profile_setup.bats
│   │   ├── test_profile_idempotency.bats
│   │   ├── test_vscode_extensions.bats
│   │   ├── test_vscode_settings_merge.bats
│   │   ├── test_shell_persistence.bats
│   │   ├── test_workspace_mount.bats
│   │   ├── test_instance_detection.bats
│   │   └── test_down_clean.bats
│   └── manual/
│       └── SMOKE_TEST_CHECKLIST.md  (checklist para tests manuales de GUI)
├── .github/
│   └── workflows/
│       └── qa.yml
└── TESTING_STRATEGY.md              ← actualizado con todo esto
```

---

## 7. Manual Smoke Test Checklist (lo que NO se puede automatizar)

Estos requieren un humano con display real:

| # | Test | WSLg | X11 |
|---|---|---|---|
| 1 | VSCode window renders (no black/blank screen) | [ ] | [ ] |
| 2 | Terminal inside VSCode works | [ ] | [ ] |
| 3 | Fonts render correctly (Nerd Font icons visible) | [ ] | [ ] |
| 4 | VSCode extensions load in sidebar | [ ] | [ ] |
| 5 | File explorer shows mounted workspace | [ ] | [ ] |
| 6 | Firefox opens from terminal | [ ] | [ ] |
| 7 | Audio plays (PulseAudio) | [ ] | [ ] |
| 8 | WSLg workaround resizes window correctly | [ ] | N/A |
| 9 | Profile README opens on first launch | [ ] | [ ] |

---

## 8. Orden de Implementación Propuesto

1. **Perfil `qa/`** — fundamento, instala las herramientas
2. **Tests unitarios** (bats) — lo más rápido de implementar, mayor ROI
3. **Tests de integración** (compose config) — no necesitan Docker build
4. **CI pipeline** (GitHub Actions) — automatiza lo anterior
5. **Tests E2E** — los más pesados, necesitan build + container
6. **Actualizar TESTING_STRATEGY.md** — documenta todo

---

## Notas / decisiones pendientes

<!-- Edita aquí tus cambios, dudas, preferencias antes de ejecutar el plan -->

- [ ] ¿Queremos coverage reports (kcov) para los scripts bash?
- [ ] ¿Añadir badge de CI en el README principal?
- [ ] ¿Limitar los profiles que se testean en E2E (todos es costoso) o solo python+qa?
- [ ] ¿Trivy severity threshold? (HIGH/CRITICAL solamente, o todo?)
- [ ] ¿El perfil QA debe incluir también Playwright/Cypress/Selenium para E2E de aplicaciones web?
