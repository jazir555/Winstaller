# Architecture Documentation

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │  CLI Commands    │  │ Desktop Shortcuts │  │ Steam Library │ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────┬───────┘ │
└───────────┼────────────────────┼────────────────────┼──────────┘
            │                    │                    │
            ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                   UMU Game Installer System                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 umu-game-installer.sh                     │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │  │
│  │  │ Dependency  │  │   Installer  │  │   Integration  │  │  │
│  │  │ Management  │  │   Execution  │  │    Manager     │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 umu-game-manager.sh                       │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │  │
│  │  │   Game      │  │   Launch     │  │   Maintenance  │  │  │
│  │  │  Database   │  │   Manager    │  │     Tools      │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        umu-run Layer                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Wine/Proton Compatibility Layer                         │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌───────────┐  │  │
│  │  │  Wine   │  │  DXVK   │  │  VKD3D  │  │   Proton  │  │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └───────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Linux Kernel / SteamOS                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │  Filesystem  │  │   Graphics   │  │  Process Manager   │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Installation Flow

```
User initiates installation
        ↓
┌───────────────────────┐
│ Parse installer path  │
│ Get game name         │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│ Create game prefix    │
│ ~/Games/Name/prefix/  │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│ Detect dependencies   │
│ (vcredist, directx)   │
└───────┬───────────────┘
        ↓
    ┌───▼───┐
    │ Found?│
    └───┬───┘
        │
    Yes │ No
    ┌───▼───────────────┐  ┌────────────────────┐
    │ Check deps.db     │  │ Skip dependencies  │
    └───┬───────────────┘  └────────┬───────────┘
        │                           │
    ┌───▼────────┐                 │
    │ Installed? │                 │
    └───┬────────┘                 │
        │                           │
    Yes │ No                       │
    ┌───▼──────────┐  ┌──────────▼────────────┐
    │ Link from    │  │ Install to shared     │
    │ shared deps  │  │ location & register   │
    └───┬──────────┘  └──────────┬────────────┘
        │                        │
        └────────┬───────────────┘
                 ↓
        ┌────────────────────┐
        │ Run GUI installer  │
        │ via umu-run        │
        └────────┬───────────┘
                 ↓
        ┌────────────────────┐
        │ User completes     │
        │ installation       │
        └────────┬───────────┘
                 ↓
        ┌────────────────────┐
        │ Detect executable  │
        │ (auto-scan)        │
        └────────┬───────────┘
                 ↓
        ┌────────────────────┐
        │ Create launch      │
        │ script             │
        └────────┬───────────┘
                 ↓
        ┌────────────────────┐
        │ Add to Steam       │
        │ (.desktop file)    │
        └────────┬───────────┘
                 ↓
        ┌────────────────────┐
        │ Create desktop     │
        │ shortcut           │
        └────────┬───────────┘
                 ↓
        ┌────────────────────┐
        │ Register in        │
        │ games.db           │
        └────────────────────┘
                 ↓
         ✓ Installation complete
```

### Dependency Management Flow

```
Dependency needed
        ↓
┌────────────────────┐
│ Calculate hash     │
│ of installer       │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ Query deps.db      │
│ for ID + version   │
└────────┬───────────┘
         ↓
     ┌───▼────┐
     │ Exists?│
     └───┬────┘
         │
     Yes │ No
     ┌───▼────────────┐  ┌──────────────────────┐
     │ Get path from  │  │ Create new prefix    │
     │ database       │  │ ~/.../deps/<id>_<v>  │
     └───┬────────────┘  └──────────┬───────────┘
         │                          ↓
         │                ┌──────────────────────┐
         │                │ Install using        │
         │                │ umu-run with flags   │
         │                └──────────┬───────────┘
         │                          ↓
         │                ┌──────────────────────┐
         │                │ Register in deps.db  │
         │                │ ID|VER|PATH|HASH|... │
         │                └──────────┬───────────┘
         │                          │
         └──────────┬───────────────┘
                    ↓
         ┌──────────────────────┐
         │ Link DLLs to game    │
         │ prefix:              │
         │ system32/ syswow64/  │
         └──────────────────────┘
                    ↓
            ✓ Dependency ready
```

### Launch Flow

```
User launches game
        ↓
┌────────────────────┐
│ Steam/Desktop      │
│ executes .desktop  │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ Launch script      │
│ launch_*.sh        │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ Set environment:   │
│ WINEPREFIX         │
│ GAMEID             │
│ DXVK/Wine vars     │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ Execute umu-run    │
│ with game.exe      │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ umu-run sets up    │
│ Wine environment   │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ Wine loads         │
│ - DLLs             │
│ - Dependencies     │
│ - Graphics layers  │
└────────┬───────────┘
         ↓
┌────────────────────┐
│ Game executable    │
│ runs                │
└────────────────────┘
         ↓
    Game running ✓
```

## Component Architecture

### umu-game-installer.sh Components

```
┌──────────────────────────────────────────────────────────┐
│                  umu-game-installer.sh                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Utility Functions                      │ │
│  │  • log() warn() error()                            │ │
│  │  • init_dirs() init_deps_db()                      │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │          Dependency Management                      │ │
│  │  • check_dependency()                              │ │
│  │  • register_dependency()                           │ │
│  │  • get_dependency_path()                           │ │
│  │  • detect_dependencies()                           │ │
│  │  • install_dependency()                            │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │          Wine Prefix Management                     │ │
│  │  • create_game_prefix()                            │ │
│  │  • link_dependencies()                             │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │           Game Installation                         │ │
│  │  • run_game_installer()                            │ │
│  │  • detect_game_executable()                        │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │          Steam Integration                          │ │
│  │  • add_to_steam()                                  │ │
│  │  • create_desktop_shortcut()                       │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Main Installation Flow                      │ │
│  │  • install_game()                                  │ │
│  │  • main()                                          │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### umu-game-manager.sh Components

```
┌──────────────────────────────────────────────────────────┐
│                  umu-game-manager.sh                      │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Game Database Management                    │ │
│  │  • init_games_db()                                 │ │
│  │  • list_games()                                    │ │
│  │  • show_game_info()                                │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │        Dependency Management                        │ │
│  │  • list_dependencies()                             │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │          Game Operations                            │ │
│  │  • launch_game()                                   │ │
│  │  • uninstall_game()                                │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │        Maintenance Tools                            │ │
│  │  • check_disk_usage()                              │ │
│  │  • clean_orphaned()                                │ │
│  │  • export_game_list()                              │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Database Schema

### deps.db (Dependency Database)

```
┌────────────┬─────────┬──────────────┬──────────┬──────────────┐
│ DEPENDENCY │ VERSION │ INSTALL_PATH │ CHECKSUM │ INSTALL_DATE │
│    ID      │         │              │          │              │
├────────────┼─────────┼──────────────┼──────────┼──────────────┤
│ vcredist   │ 2022    │ /path/to/... │ sha256...│ 2024-01-15   │
│ vcredist   │ 2019    │ /path/to/... │ sha256...│ 2024-01-15   │
│ directx    │ 9       │ /path/to/... │ sha256...│ 2024-01-16   │
│ dotnet     │ 4.8     │ /path/to/... │ sha256...│ 2024-01-16   │
└────────────┴─────────┴──────────────┴──────────┴──────────────┘

Format: PIPE-DELIMITED (|)
Example: vcredist|2022|/home/deck/.config/umu-game-installer/dependencies/vcredist_2022|abc123...|2024-01-15
```

### games.db (Games Database)

```
┌──────────┬───────────┬─────────────┬──────────────┬──────────────┐
│ GAME_ID  │ GAME_NAME │ PREFIX_PATH │   EXE_PATH   │ INSTALL_DATE │
├──────────┼───────────┼─────────────┼──────────────┼──────────────┤
│ umu-game1│ My Game   │ /path/to/...│ .../game.exe │ 2024-01-15   │
│ umu-game2│ Other Game│ /path/to/...│ .../game.exe │ 2024-01-16   │
└──────────┴───────────┴─────────────┴──────────────┴──────────────┘

Format: PIPE-DELIMITED (|)
Example: umu-mygame|My Game|/home/deck/Games/MyGame/prefix|/home/deck/Games/MyGame/prefix/drive_c/Games/MyGame/game.exe|2024-01-15
```

## File System Layout

```
/home/deck/
│
├── .config/
│   └── umu-game-installer/
│       ├── config                    # User configuration
│       ├── deps.db                   # Dependency database
│       ├── games.db                  # Games database
│       ├── installer.log             # Installation logs
│       │
│       ├── dependencies/             # Shared dependencies
│       │   ├── vcredist_2022/
│       │   │   └── drive_c/
│       │   │       └── windows/
│       │   │           ├── system32/ # 64-bit DLLs
│       │   │           └── syswow64/ # 32-bit DLLs
│       │   ├── vcredist_2019/
│       │   ├── directx_9/
│       │   └── dotnet_4.8/
│       │
│       └── launch_*.sh               # Game launch scripts
│           ├── launch_umu-game1.sh
│           └── launch_umu-game2.sh
│
├── .local/
│   └── share/
│       └── applications/             # Application menu entries
│           ├── umu-game1.desktop    # Steam integration
│           └── umu-game2.desktop
│
├── Desktop/                          # Desktop shortcuts
│   ├── Game1.desktop
│   └── Game2.desktop
│
└── Games/                            # Game installations
    ├── Game1/
    │   └── prefix/                   # Wine prefix
    │       ├── drive_c/
    │       │   ├── Program Files/
    │       │   │   └── Game1/        # Actual game files
    │       │   │       ├── game.exe
    │       │   │       └── data/
    │       │   └── windows/
    │       │       ├── system32/     # Linked from deps
    │       │       └── syswow64/
    │       ├── dosdevices/
    │       ├── system.reg
    │       └── user.reg
    │
    └── Game2/
        └── prefix/
            └── ...
```

## Integration Points

### Steam Integration

```
┌─────────────────────┐
│  Steam Desktop Mode │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  .desktop file      │
│  discovery          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Launch script      │
│  execution          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  umu-run            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Game process       │
└─────────────────────┘
```

### Desktop Environment Integration

```
┌─────────────────────┐
│  File Manager       │
│  (Dolphin/Nautilus) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Right-click menu   │
│  "Install with UMU" │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Terminal opens     │
│  umu-game-installer │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Installation flow  │
└─────────────────────┘
```

## State Machine

### Installation State Machine

```
       ┌──────────┐
       │  IDLE    │
       └────┬─────┘
            │ start
            ▼
       ┌──────────┐
       │  INIT    │────error───┐
       └────┬─────┘            │
            │ success          │
            ▼                  │
    ┌───────────────┐          │
    │ DETECTING_DEPS│─error────┤
    └───────┬───────┘          │
            │ found/none       │
            ▼                  │
    ┌───────────────┐          │
    │ INSTALLING_   │─error────┤
    │ DEPS          │          │
    └───────┬───────┘          │
            │ complete         │
            ▼                  │
    ┌───────────────┐          │
    │ RUNNING_      │─error────┤
    │ INSTALLER     │          │
    └───────┬───────┘          │
            │ complete         │
            ▼                  │
    ┌───────────────┐          │
    │ DETECTING_EXE │─error────┤
    └───────┬───────┘          │
            │ found            │
            ▼                  │
    ┌───────────────┐          │
    │ INTEGRATING   │─error────┤
    └───────┬───────┘          │
            │ complete         │
            ▼                  │
       ┌──────────┐            │
       │ SUCCESS  │            │
       └──────────┘            │
                               │
            ┌──────────────────┘
            │
            ▼
       ┌──────────┐
       │  ERROR   │
       └──────────┘
```

## Error Handling

### Error Propagation

```
Component Error
      ↓
┌─────────────┐
│ Log to      │
│ stderr      │
└─────┬───────┘
      ↓
┌─────────────┐
│ Exit with   │
│ error code  │
└─────┬───────┘
      ↓
┌─────────────┐
│ User sees   │
│ error msg   │
└─────────────┘
```

### Rollback Strategy

```
Installation fails
      ↓
┌─────────────────┐
│ Remove partial  │
│ game prefix     │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Keep dependency │
│ installations   │
│ (may be valid)  │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Remove database │
│ entries         │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Clean up        │
│ launch scripts  │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Report error    │
│ to user         │
└─────────────────┘
```

## Performance Considerations

### Optimization Points

1. **Dependency Linking**
   - Symlinks vs copies: Symlinks used for instant "installation"
   - Reduces storage: ~80% savings on dependencies
   - Instant reuse: No reinstallation time

2. **Executable Detection**
   - Limited search depth: Max 3 levels
   - Pattern filtering: Excludes uninstallers early
   - Parallel scanning: Could be added for large installs

3. **Database Queries**
   - Simple grep: Fast for small databases (< 1000 entries)
   - Linear search: O(n) but n is small
   - No indexing needed: Fast enough for use case

## Security Architecture

### Isolation

```
┌───────────────────────────────────┐
│     User Space                    │
│  ┌─────────────────────────────┐ │
│  │   Game 1 Prefix (Isolated)  │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │   Game 2 Prefix (Isolated)  │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │   Shared Dependencies       │ │
│  │   (Read-only links)         │ │
│  └─────────────────────────────┘ │
└───────────────────────────────────┘
         │
         │ Wine/umu-run boundary
         ▼
┌───────────────────────────────────┐
│     Wine Sandbox                  │
└───────────────────────────────────┘
```

## Extensibility

### Plugin Architecture (Future)

```
┌─────────────────────────────────────┐
│  Core Installer                     │
└───────────┬─────────────────────────┘
            │
            ▼
┌─────────────────────────────────────┐
│  Plugin Interface                   │
│  ┌────────────┐  ┌────────────┐    │
│  │ Pre-hook   │  │ Post-hook  │    │
│  └────────────┘  └────────────┘    │
└───────────┬─────────────────────────┘
            │
            ▼
   ┌────────┴────────┐
   │                 │
   ▼                 ▼
┌──────────┐    ┌──────────┐
│ Plugin 1 │    │ Plugin 2 │
│ (GOG)    │    │ (Epic)   │
└──────────┘    └──────────┘
```

---

This architecture provides **modularity**, **maintainability**, and **extensibility** while keeping the implementation simple and transparent for users.
