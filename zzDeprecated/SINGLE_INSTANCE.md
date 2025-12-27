# Single Instance Limitation

## Why Only One Instance?

This project uses **isolated Docker environments** for each project, where each container has:
- Its own VSCode extensions
- Its own configuration
- Its own tools and dependencies

However, all containers share the same **WSLg display** (`:0`). VSCode detects other instances running on the same display and attempts to communicate with them, causing conflicts.

**Discarded solutions:**
- ✗ Share configuration between containers → Loses isolation (mixed extensions)
- ✗ Separate virtual displays → Too complex, loses WSLg integration

**Adopted solution:**
- ✅ Single-instance with elegant conflict handling

## Behavior

### Scenario 1: First Instance

```bash
$ cd ~/rust-project
$ ./vsc-wslg dood up

🚀 Starting VSCode...
# VSCode opens normally
```

### Scenario 2: Attempting Second Instance

```bash
$ cd ~/symfony-project
$ ./vsc-wslg dood up

⚠️  There's already a vsc-wslg instance running:

   Project:    vsc_rust-project (DooD)
   Container:  vsc_rust-project_vscode_1
   Workspace:  /home/user/rust-project

What do you want to do?
  1) Cancel (keep existing instance)
  2) Close existing instance and open this one

Option [1-2]:
```

**Option 1**: Cancels the operation, leaves current VSCode running.

**Option 2**: Automatically closes the existing instance and opens the new one:
```bash
🛑 Closing existing instance(s)...
   Stopping vsc_rust-project...
✓ Done, proceeding to open new instance...

🚀 Starting VSCode...
# VSCode for symfony-project opens
```

## Recommended Workflow

### Quick Project Switching

```bash
# You're working on project A
cd ~/project-a
./vsc-wslg dood up

# You want to switch to project B
# Option A: Manual
./vsc-wslg dood down
cd ~/project-b
./vsc-wslg dood up

# Option B: Automatic (use option 2 from prompt)
cd ~/project-b
./vsc-wslg dood up
# → Select option 2
```

### Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Quick switch with confirmation
alias vsc-switch='cd "$1" && /path/to/vsc-wslg dood up'

# Close current instance from anywhere
alias vsc-down='docker ps --filter "name=vsc_" --format "{{.Names}}" | head -1 | xargs -I {} docker stop {}'
```

## Special Cases

### Multiple Simultaneous Projects (Not Supported)

If you need to work on multiple projects **at the same time**, consider:

1. **VSCode Remote**: Use Windows VSCode + Remote-Containers
2. **Virtual Displays**: Complex implementation with Xvfb/VNC (see extended documentation)
3. **Secondary Editor**: Use `vim`/`nano` in a container for quick edits while VSCode is in another

### Detecting Running Instance

```bash
# See which instance is active
docker ps --filter "name=vsc_" --format "Project: {{.Names}}\nImage: {{.Image}}"

# Stop all instances
docker ps --filter "name=vsc_" -q | xargs docker stop
```

## Technical Architecture

```
┌─────────────────────────────────────┐
│  WSLg Display Server (:0)           │
│  - Manages all GUI windows          │
│  - Allows detection between apps    │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
   Container A      Container B
   (Rust env)       (PHP env)
       │                │
       └────────────────┘
       Only ONE can
       use the display
       at a time
```

## Trade-offs

| Aspect | Evaluation |
|---------|------------|
| **Environment isolation** | ✅ Complete |
| **Reproducibility** | ✅ Total |
| **Ease of use** | ✅ Simple |
| **Concurrent instances** | ❌ Not supported |
| **Project switching** | ⚠️ Requires close/open (~5-10 sec) |

This limitation is a **conscious compromise** between simplicity, isolation, and the technical reality of WSLg.
