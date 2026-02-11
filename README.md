Here is a polished **GitHub-ready README.md** (clean formatting, badges-ready, structured for open source):

---

# 🎮 Steam Custom Artwork Switcher (SCAS)

> A lightweight PowerShell tool to manage and switch Steam custom artwork profiles instantly.

SCAS makes it easy to save, switch, hide, backup, and manage your Steam custom grid artwork without manually copying folders.

---

## ✨ Features

* 🔍 Auto-detect Steam installation path
* 👤 Auto-detect active Steam user
* 💾 Save current grid as a named profile
* 🔄 Instantly switch between artwork profiles
* 👁 Hide / unhide profiles
* 📦 Auto-backup before deleting current grid
* 🧹 Automatically clears Steam library cache
* ⚡ No dependencies — pure PowerShell

---

## 📸 What It Manages

Steam stores custom artwork in:

```
Steam\userdata\<AccountID>\config\grid
```

SCAS stores your profiles in:

```
Steam\userdata\SCAS_grid
```

Hidden profiles:

```
Steam\userdata\SCAS_grid\.hidden
```

---

## 🧰 Requirements

* Windows
* PowerShell 5.1+ or PowerShell 7+
* Steam installed

If execution is blocked:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## 🚀 Usage

```powershell
./SCAS.ps1 [command] [options]
```

---

## 📋 Commands

### 🔹 Help

```powershell
./SCAS.ps1 -h
```

---

### 🔹 Save Current Grid

```powershell
./SCAS.ps1 -s <name>
```

Example:

```powershell
./SCAS.ps1 -s clean_layout
```

---

### 🔹 List Profiles

List visible profiles:

```powershell
./SCAS.ps1 -l
```

Include hidden profiles:

```powershell
./SCAS.ps1 -l -a
```

---

### 🔹 Switch Profile

```powershell
./SCAS.ps1 -c <name>
```

Example:

```powershell
./SCAS.ps1 -c clean_layout
```

Steam will automatically restart.

---

### 🔹 Delete

#### Backup & Delete Current Grid

```powershell
./SCAS.ps1 -d
```

Creates automatic backup:

```
backup_YYYYMMDD_HHMMSS
```

Then clears current grid.

---

#### Delete Specific Profile

```powershell
./SCAS.ps1 -d <name>
```

Works for both visible and hidden profiles.

---

### 🔹 Hide Profile

```powershell
./SCAS.ps1 -hide <name>
```

---

### 🔹 Unhide Profile

```powershell
./SCAS.ps1 -unhide <name>
```

---

## 🧪 Example Workflow

```powershell
# Save default grid
./SCAS.ps1 -s default

# Customize Steam artwork manually

# Save new layout
./SCAS.ps1 -s anime_theme

# Switch between them
./SCAS.ps1 -c default
./SCAS.ps1 -c anime_theme

# Hide profile
./SCAS.ps1 -hide anime_theme

# Show all profiles
./SCAS.ps1 -l -a
```

---

## 📁 Example Folder Structure

```
Steam
└── userdata
    ├── 123456789
    │   └── config
    │       └── grid
    └── SCAS_grid
        ├── default
        ├── anime_theme
        └── .hidden
```

---

## ⚠ Notes

* Steam will be stopped automatically when switching profiles.
* Library cache is cleared to force artwork refresh.
* Avoid running during downloads or updates.
* Profiles are stored inside your Steam directory.

---

## 📄 License

MIT License.
