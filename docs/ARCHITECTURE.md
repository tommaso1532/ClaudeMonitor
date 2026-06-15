# Architecture

ClaudeMonitor is a native macOS wrapper around the `cswap` command line tool. It keeps the UI native and leaves account switching/account storage to `cswap`.

## Data Flow

```text
cswap --list
    |
    v
Sources/Shared/Producer.swift
    |
    v
ClaudeData
    |
    +--> Menu bar UI
    |
    +--> ~/Library/Application Support/ClaudeMonitor/data.json
    |
    +--> ~/Library/Containers/app.claudemonitor.ClaudeMonitor.ClaudeWidget/Data/data.json
             |
             v
         WidgetKit timeline
```

## cswap Contract

The app expects `cswap --list` to print account and instance sections. The parser recognizes:

```text
Accounts:
  1: account-name (active)
     5h: 12% resets ... in ...
     7d: 34% resets ... in ...

Running instances:
  • claude /path/to/project (...)
```

ClaudeMonitor does not manage Claude credentials. It only calls:

```bash
cswap --list
cswap --switch-to <account>
```

That keeps the repo focused on presentation, widget refresh, and macOS packaging.

## Bundle IDs

```text
app.claudemonitor.ClaudeMonitor
app.claudemonitor.ClaudeMonitor.ClaudeWidget
```

Do not change these after public releases unless you intend users to reinstall and re-add the widget.

## Icons

- `AppIcon` is generated from `Resources/Source/ClaudeMonitorLogo.svg`.
- `StatusBarIcon` is generated from `Resources/Source/ClaudeAISymbol.svg`.
- `ClaudeMenuBar` remains available for widget imagery.
