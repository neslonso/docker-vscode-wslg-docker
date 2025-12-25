# Refactoring Plan - docker-vscode-wslg

## Executive Summary

This document presents a comprehensive refactoring plan to improve the organization, cleanliness, and maintainability of the docker-vscode-wslg-docker project code.

**Objective**: Eliminate code duplication, improve modularization, establish consistent patterns, and facilitate project maintenance and extensibility.

**Current status**:
- ✅ **Phase 1 completed**: Dockerfiles consolidated (0% duplication)
- ✅ **Phase 2 completed**: Entrypoints unified
- ✅ **Phase 2.5 completed**: Profiles radically simplified
- ✅ **Extra improvements**: Elegant single-instance handling
- ⏳ **Pending**: Phases 4-8 (optional improvements)

**Next recommended objective**: **Phase 4 - Main Script Improvements** (medium priority, improves maintainability)

---

## 1. Identified Problems

### 1.1 Critical Code Duplication

#### Dockerfiles (DinD/DooD)
- **Location**: `DinD/Dockerfile-vsc-wslg` vs `DooD/Dockerfile-vsc-wslg`
- **Problem**: 95% of code is identical, only differs in:
  - 3-4 lines to install/omit Docker daemon
  - Entrypoint reference (DinD vs DooD)
- **Impact**: Any change (VSCode update, dependencies, etc.) must be replicated manually
- **Duplicated lines**: ~60 of 69 lines

#### Entrypoints
- **Location**: `DinD/entrypoint.sh` vs `DooD/entrypoint.sh`
- **Problem**:
  - Duplicated common logic: VSCode configuration, extension installation, WSLg workaround, profile processing
  - Only differ in: Docker daemon startup (DinD) and socket permissions handling (DooD)
- **Impact**: Improvements or fixes must be applied in both places
- **Common code**: ~120 of 137 lines

#### Profile Scripts
- **Location**: `profiles/*/scripts/*.sh`
- **Problem**: Identical scripts with only changes in names/emojis
  - `stop.sh`: 10 lines, 90% identical between profiles
  - `logs.sh`: 8 lines, 90% identical
  - `shell.sh`: 8 lines, 100% identical
  - `start.sh`: Identical structure, only differs in messages and validations
- **Impact**: 12 files that could be 3-4 with parameters

#### `manage` Scripts
- **Location**: `profiles/*/manage`
- **Problem**: Almost identical command routing logic
  - 48 lines per profile
  - Only differ in available commands and names
- **Impact**: Any new command requires manual update of 3+ files

### 1.2 Organization Problems

#### Lack of Separation of Responsibilities
- **vsc-wslg**: Mixes argument parsing, validation, and docker-compose execution
- **entrypoints**: Mix base configuration, profiles, extension installation, workarounds

#### Absence of Common Library
- No shared functions for:
  - Logging with consistent format
  - Precondition validation
  - Error handling
  - Common Docker operations

#### Unclear Directory Structure
```
lib/
  └── profile-loader.sh    # Why is only this script in lib/?
```
- No clear convention for where shared libraries go
- No separation between user scripts and internal scripts

### 1.3 Hardcoded vs Configurable Code

#### Hardcoded Values
- WSLg window size: `1024 768` (line 73 in entrypoints)
- Timeouts: `sleep 2`, `sleep 3` scattered throughout code
- Paths: `/home/dev/.config/Code/User` repeated multiple times
- Container names: inconsistent `${COMPOSE_PROJECT_NAME:-name}` pattern

#### Scattered Configuration
- Environment variables defined in multiple places
- No single configuration point
- Makes user customization difficult

### 1.4 Inconsistent Error Handling

- Some scripts use `set -e`, others don't
- Inconsistent precondition validation
- Error messages with different formats
- No rollback for partially failed operations

### 1.5 Profile Inconsistencies

| Aspect | symfony | rust | devops |
|---------|---------|------|--------|
| `shell` command | ✗ | ✓ | ✓ |
| `status` command | ✓ (inline) | ✓ (inline) | ✓ (script) |
| `status.sh` script | ✗ | ✗ | ✓ |
| Message format | Varied | Varied | Varied |

### 1.6 Code Documentation

- Scarce comments in complex scripts
- No docstrings in functions
- Complex logic without explanation (e.g., WSLg workaround)
- Doesn't document why certain things are done

---

## 2. Proposed Refactoring Plan

### Phase 1: Dockerfile Consolidation ✅ COMPLETED

**Priority**: HIGH
**Impact**: High - Reduces 95% duplication
**Risk**: Low - Well-defined change
**Status**: ✅ Implemented and tested

**Changes made**:
- ✅ Created `docker/Dockerfile.base` with common logic
- ✅ Uses build args for customization (INSTALL_DOCKER_DAEMON, ENTRYPOINT_MODE)
- ✅ DinD and DooD now reference the base Dockerfile
- ✅ Reduction from ~132 duplicated lines to 0% duplication

**Modified files**:
- Created: `docker/Dockerfile.base`
- Created: `docker/README.md`
- Created: `docker/test-builds.sh`
- Modified: `DinD/docker-compose.yml`
- Modified: `DooD/docker-compose.yml`
- Created: `CHANGELOG.md`

**Additional improvements implemented (outside original plan)**:
- ✅ Elegant single-instance handling
  - `check_running_instances()` function in `vsc-wslg`
  - Automatic detection of running instances
  - Interactive prompt with clear options
  - Auto-close of previous instance if user chooses
  - Documented in `SINGLE_INSTANCE.md`
- ✅ Diagnostic script `debug-display.sh` to understand WSLg communication
- ✅ Documentation of architectural limitation (single-instance)

#### 2.1.1 Create Common Base Dockerfile

**New file**: `docker/Dockerfile.base`

```dockerfile
# Contains all common logic:
# - Base image
# - Common dependencies
# - VSCode installation
# - dev user
# - profile-loader library
# - ARGs for customization
```

**Benefits**:
- Single place to update VSCode, dependencies, etc.
- Reduces build time with shared cache
- Facilitates testing of changes

#### 2.1.2 Create Minimalist Specific Dockerfiles

**DinD**: `DinD/Dockerfile-vsc-wslg`
```dockerfile
FROM ../docker/Dockerfile.base
# Only install Docker daemon + DinD dependencies
# Copy specific entrypoint
```

**DooD**: `DooD/Dockerfile-vsc-wslg`
```dockerfile
FROM ../docker/Dockerfile.base
# Only install Docker CLI
# Copy specific entrypoint
```

**Reduction**: From 69 lines x2 → 50 base lines + 10 lines x2

### Phase 2: Entrypoint Unification ✅ COMPLETED

**Priority**: HIGH
**Impact**: High - Eliminates duplication, facilitates maintenance
**Risk**: Medium - Requires careful testing
**Status**: ✅ Implemented and tested

**Changes made**:
- ✅ Created `lib/vscode-setup.sh` with all VSCode setup functions
- ✅ Created `lib/docker-setup.sh` with Docker-specific functions
- ✅ Refactored both entrypoints to use shared libraries
- ✅ Reduction from 274 total lines to 116 lines (-58%)
- ✅ All functions documented with docstrings
- ✅ Zero duplication in business logic

#### 2.2.1 Create Shared Function Library

**New file**: `lib/vscode-setup.sh`

Contains functions:
```bash
setup_vscode_permissions()    # Permissions on volumes
setup_vscode_settings()        # Merge settings.json
install_vscode_extensions()    # Extension installation
apply_wslg_workaround()       # WSLg window fix
open_profile_readme()         # Open README first time
```

**New file**: `lib/docker-setup.sh`

```bash
start_docker_daemon()         # For DinD
setup_docker_socket_perms()   # For DooD
wait_for_docker()            # Wait for Docker to be ready
```

**Benefits**:
- Unit testable code
- Reusable in future modes
- Easy to maintain and document

#### 2.2.2 Refactor Entrypoints

**DinD/entrypoint.sh** (reduced to ~40 lines):
```bash
#!/bin/bash
set -e

source /usr/local/lib/vscode-setup.sh
source /usr/local/lib/docker-setup.sh

setup_vscode_permissions
start_docker_daemon
wait_for_docker
setup_vscode_settings
process_profile_if_set
apply_wslg_workaround
install_vscode_extensions
open_profile_readme
launch_vscode "$@"
```

**DooD/entrypoint.sh** (similar):
```bash
#!/bin/bash
set -e

source /usr/local/lib/vscode-setup.sh
source /usr/local/lib/docker-setup.sh

setup_vscode_permissions
setup_docker_socket_perms
setup_vscode_settings
process_profile_if_set
apply_wslg_workaround
install_vscode_extensions
open_profile_readme
launch_vscode "$@"
```

**Reduction**: From 137 lines x2 → ~120 shared lines + ~40 lines x2

### Phase 2.5: Radical Profile Simplification ✅ COMPLETED

**Priority**: HIGH
**Impact**: High - Eliminates unnecessary complexity
**Risk**: Low - Simplifies architecture
**Status**: ✅ Implemented

**New philosophy**: Profiles are **only VSCode configuration**, not service orchestration.

#### Changes made:

**Removed** (unnecessary):
- ❌ `profiles/*/scripts/` - Orchestration scripts
- ❌ `profiles/*/manage` - Management commands
- ❌ `profiles/*/docker-compose.yml` - Services (belong in project, not profile)
- ❌ `profiles/*/services/` - Service configuration

**Simplified structure**:
```
profiles/profile-name/
├── README.md              # Documentation
└── vscode/
    ├── extensions.list    # Extensions to install
    └── settings.json      # VSCode configuration
```

**Benefits**:
- ✅ Profiles are portable and self-contained
- ✅ Clear separation: profile = editor, project = infrastructure
- ✅ Easier to create new profiles (only 2 files)
- ✅ No duplicated code (no scripts to duplicate)
- ✅ Smaller maintenance surface

**Documentation**:
- Created `profiles/README.md` with complete profile guide
- Explains separation of responsibilities philosophy
- Includes examples of how to create profiles
- Usage tips and troubleshooting

**Architectural decision**:
If a project needs services (MySQL, Redis, etc.), it should use its own `docker-compose.yml` in the project workspace, not mix it with VSCode profile configuration.

### Phase 4: Main Script Improvements

**Priority**: MEDIUM
**Impact**: Medium - Improves readability and maintainability
**Risk**: Low

#### 2.4.1 Separate Responsibilities

**New file**: `lib/vsc-wslg-core.sh`

Functions:
```bash
parse_arguments()         # CLI args parsing
validate_mode()          # Mode validation
validate_action()        # Action validation
validate_profile()       # Profile validation
get_compose_file()       # Get compose file
set_environment_vars()   # Configure variables
execute_action()         # Execute docker-compose action
```

**Refactored vsc-wslg**:
```bash
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/lib/vsc-wslg-core.sh"

parse_arguments "$@"
validate_inputs
set_environment_vars
execute_action
```

**Reduction**: From 137 monolithic lines → ~80 lib lines + ~20 main lines

#### 2.4.2 Improve Validations

```bash
# Validate Docker is installed
# Validate profile exists (if specified)
# Validate mode is compatible with system
# Show useful warnings
```

### Phase 5: Centralized Configuration

**Priority**: LOW
**Impact**: Medium - Facilitates customization
**Risk**: Low

#### 2.5.1 Create Configuration File

**New file**: `config/defaults.conf`

```bash
# Global project configuration
DEFAULT_WINDOW_WIDTH=1024
DEFAULT_WINDOW_HEIGHT=768
VSCODE_CONFIG_DIR="/home/dev/.config/Code/User"
DOCKER_WAIT_TIMEOUT=30
WSLG_WORKAROUND_ENABLED=true
PROFILE_MOUNT_PATH_PATTERN="/home/dev/vsc-wslg-{profile}-profile"
```

**Optional file**: `.vsc-wslg.conf` (in user's project)

```bash
# Allows user to override defaults
WINDOW_WIDTH=1920
WINDOW_HEIGHT=1080
```

#### 2.5.2 Update Scripts to Use Configuration

```bash
source /usr/local/etc/vsc-wslg/defaults.conf
[ -f ~/.vsc-wslg.conf ] && source ~/.vsc-wslg.conf

# Use variables instead of hardcoded values
xdotool windowsize "$WID" $WINDOW_WIDTH $WINDOW_HEIGHT
```

### Phase 6: Error Handling Improvements

**Priority**: MEDIUM
**Impact**: High - Improves robustness and debugging
**Risk**: Low

#### 2.6.1 Logging Library

**New file**: `lib/logger.sh`

```bash
log_info()     # Informational messages with timestamp
log_success()  # Success messages
log_warning()  # Warnings
log_error()    # Errors (not fatal)
log_fatal()    # Fatal errors (exit 1)
log_debug()    # Only if DEBUG=1
```

**Usage**:
```bash
source /usr/local/lib/logger.sh

log_info "Starting Docker daemon..."
docker daemon &>/dev/null || log_fatal "Could not start Docker daemon"
log_success "Docker daemon started successfully"
```

#### 2.6.2 Robust Validations

```bash
# Validate preconditions before executing
check_docker_installed() {
  command -v docker &>/dev/null || log_fatal "Docker is not installed"
}

check_compose_file_exists() {
  [ -f "$1" ] || log_fatal "Compose file not found: $1"
}

check_wslg_available() {
  [ -d /tmp/.X11-unix ] || log_warning "WSLg might not be available"
}
```

#### 2.6.3 Dry-run Mode

```bash
# Add --dry-run flag to main script
# Shows what it would do without executing

./vsc-wslg dood up symfony --dry-run
# Output:
# Would execute: docker-compose -f .../DooD/docker-compose.yml up
# Environment variables:
#   COMPOSE_PROJECT_NAME=vsc_myproject
#   PROJECT_DIR=/home/user/myproject
#   VSCODE_EXTENSIONS_PROFILE=symfony
```

### Phase 7: Profile Standardization

**Priority**: LOW
**Impact**: Medium - Improves consistency
**Risk**: Low

#### 2.7.1 Define Standard Commands

All profiles should support:
- `start` - Start services
- `stop` - Stop services
- `restart` - Restart services
- `status` - View status
- `logs` - View logs
- `shell` - Open shell (if applicable)

#### 2.7.2 Profile Template

**New file**: `profiles/TEMPLATE/`

Complete structure with:
- `README.md` template
- `docker-compose.yml` example
- Pre-configured `manage`
- `scripts/` with all standard commands
- `vscode/` with recommended structure

#### 2.7.3 Profile Creation Documentation

Update `README.md` with:
- Step-by-step guide using template
- Best practices
- Examples of common use cases

### Phase 8: Testing and Quality

**Priority**: LOW
**Impact**: High in long term
**Risk**: Low

#### 2.8.1 Testing Scripts

**New file**: `tests/test-profiles.sh`

```bash
# Test that each profile:
# - Can be built (build)
# - Can be started (up)
# - manage commands work
# - Stops correctly (down)
```

#### 2.8.2 Shell Script Linting

```bash
# Use shellcheck in CI/CD
find . -name "*.sh" -exec shellcheck {} \;
```

#### 2.8.3 API Documentation

Document library functions:
```bash
# lib/profile-manager.sh

##
# Starts profile services
#
# Globals:
#   PROFILE_NAME - Profile name
#   SCRIPT_DIR - Profile directory
# Arguments:
#   None
# Outputs:
#   Progress messages to stdout
# Returns:
#   0 if success, 1 if error
##
profile_start() {
  ...
}
```

---

## 3. Proposed New Directory Structure

```
.
├── vsc-wslg                      # Main script (simplified)
├── config/
│   └── defaults.conf             # Default configuration
├── lib/                          # Shared libraries
│   ├── vsc-wslg-core.sh         # Core logic of main script
│   ├── vscode-setup.sh          # VSCode setup
│   ├── docker-setup.sh          # Docker setup (DinD/DooD)
│   ├── profile-loader.sh        # Profile loading (existing, improved)
│   ├── profile-manager.sh       # Profile management
│   ├── profile-manage-base.sh   # Base for manage scripts
│   └── logger.sh                # Standardized logging
├── docker/
│   ├── Dockerfile.base          # Common base Dockerfile
│   └── scripts/                 # Auxiliary build scripts
├── DinD/
│   ├── Dockerfile-vsc-wslg     # Extends base, DinD specific
│   ├── docker-compose.yml      # No changes
│   └── entrypoint.sh           # Simplified
├── DooD/
│   ├── Dockerfile-vsc-wslg     # Extends base, DooD specific
│   ├── docker-compose.yml      # No changes
│   └── entrypoint.sh           # Simplified
├── profiles/
│   ├── TEMPLATE/               # Template for new profiles
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   ├── manage
│   │   ├── scripts/
│   │   ├── services/
│   │   └── vscode/
│   ├── symfony/                # Simplified
│   ├── rust/                   # Simplified
│   └── devops/                 # Simplified
├── tests/
│   ├── test-profiles.sh        # Profile tests
│   └── test-core.sh            # Core functionality tests
├── docs/
│   ├── architecture.md         # Project architecture
│   ├── creating-profiles.md    # Profile creation guide
│   └── troubleshooting.md      # Problem solving
└── README.md                    # Updated
```

**Improvements**:
- Clear separation between config, code, tests, docs
- `lib/` contains ALL libraries
- `docker/` groups everything related to Docker builds
- `tests/` to maintain quality
- `docs/` for extended documentation

---

## 4. Implementation Strategy

### 4.1 Recommended Order

1. **Phase 6 (partial)**: Implement `lib/logger.sh` first
   - Allows using consistent logging in all following phases
   - Low risk, high benefit

2. **Phase 3**: Common library for profile scripts
   - High duplication reduction
   - Low risk
   - Doesn't affect main functionality (only profiles)

3. **Phase 1**: Dockerfile consolidation
   - High impact
   - Requires testing but is well-defined
   - Facilitates later phases

4. **Phase 2**: Entrypoint unification
   - Requires Phase 3 libraries
   - Medium risk, requires exhaustive testing

5. **Phase 4**: Main script improvements
   - Benefits from previous libraries
   - Improves UX

6. **Phase 7**: Profile standardization
   - Benefits from all previous infrastructure

7. **Phase 5**: Centralized configuration
   - Nice to have, can be done in parallel

8. **Phase 8**: Testing and quality
   - Continuous during all phases

### 4.2 Incremental Approach

**Development branch**: `refactor/code-organization`

**For each phase**:
1. Create new functionality (without breaking existing)
2. Migrate one component as test
3. Exhaustive testing
4. Migrate rest of components
5. Deprecate old code (comment, don't delete yet)
6. Commit and document

**Safe rollback**: Keep old code commented until everything works

### 4.3 Testing

**For each change**:
- [ ] Successful build of DinD and DooD images
- [ ] `up` works with symfony profile
- [ ] `up` works with rust profile
- [ ] `up` works with devops profile
- [ ] `up` works without profile
- [ ] Extensions install correctly
- [ ] Settings apply correctly
- [ ] `manage` commands work in each profile
- [ ] WSLg workaround works
- [ ] DinD mode: Docker daemon starts
- [ ] DooD mode: Docker socket accessible

---

## 5. Success Metrics

### 5.1 Duplication Reduction

| Component | Before | After | Reduction |
|------------|-------|---------|-----------|
| Dockerfiles | 138 lines (69x2) | 70 lines (50+10x2) | ~49% |
| Entrypoints | 274 lines (137x2) | 200 lines (120+40x2) | ~27% |
| Profile scripts | ~162 lines | ~50 lines | ~69% |
| manage scripts | ~144 lines (48x3) | ~36 lines (12x3) | ~75% |
| **TOTAL** | **~718 lines** | **~356 lines** | **~50%** |

### 5.2 Maintainability

**Before**:
- Update VSCode: modify 2 Dockerfiles
- Add logging: modify 10+ files
- New profile command: modify 3+ files
- Extension fix: modify 2 entrypoints

**After**:
- Update VSCode: modify 1 base Dockerfile
- Add logging: use existing `lib/logger.sh`
- New profile command: modify 1 lib file
- Extension fix: modify 1 function in 1 file

### 5.3 Extensibility

**Time to create new profile**:
- Before: ~30-45 min (copy/paste, adapt scripts)
- After: ~10-15 min (use template, configure)

### 5.4 Code Quality

- [ ] 0 business logic duplication
- [ ] 100% of scripts with `set -e`
- [ ] 100% of main functions documented
- [ ] Consistent logging in all scripts
- [ ] All preconditions validated

---

## 6. Risks and Mitigations

### Risk 1: Breaking existing functionality
**Mitigation**:
- Exhaustive testing after each phase
- Keep old code until validating new
- Atomic commits with rollback possibility

### Risk 2: Added complexity
**Mitigation**:
- Document each function and library
- Clear usage examples
- Don't over-engineer (YAGNI principle)

### Risk 3: Implementation time
**Mitigation**:
- Prioritize phases by ROI
- Incremental implementation
- Can pause between phases

### Risk 4: Compatibility with existing projects
**Mitigation**:
- Don't change public command names
- Environment variables maintain compatibility
- Document any breaking changes

---

## 7. Effort Estimation

| Phase | Estimated Time | Priority |
|------|----------------|-----------|
| Phase 1: Dockerfiles | 2-3 hours | HIGH |
| Phase 2: Entrypoints | 4-5 hours | HIGH |
| Phase 3: Profile scripts | 3-4 hours | MEDIUM |
| Phase 4: Main script | 2-3 hours | MEDIUM |
| Phase 5: Configuration | 1-2 hours | LOW |
| Phase 6: Errors/logging | 2-3 hours | MEDIUM |
| Phase 7: Standardization | 2-3 hours | LOW |
| Phase 8: Testing/docs | 3-4 hours | LOW |
| **TOTAL** | **19-27 hours** | |

**Recommended approach**:
- Sprint 1 (1 week): Phases 6 (partial), 3, 1
- Sprint 2 (1 week): Phases 2, 4
- Sprint 3 (1 week): Phases 7, 5, 8

---

## 8. Long-term Benefits

1. **Maintainability**: Centralized changes, easy to apply
2. **Extensibility**: New profiles in minutes, not hours
3. **Quality**: Testable code, fewer bugs
4. **Onboarding**: Easier for new contributors to understand the project
5. **Documentation**: Self-documenting code with well-named functions
6. **Performance**: Possibility to optimize shared functions
7. **Evolution**: Solid foundation for future features (e.g., other modes besides DinD/DooD)

---

## 9. Conclusion

This refactoring plan systematically addresses the organization and code duplication problems identified in the project. Incremental implementation minimizes risks while maximizing benefits.

**Recommendation**: Start with high-priority phases (1, 2, 3, 6) that give the highest ROI in terms of duplication reduction and maintainability improvement.

The result will be a cleaner, more maintainable, and extensible codebase, facilitating both future development and the incorporation of new contributors.
