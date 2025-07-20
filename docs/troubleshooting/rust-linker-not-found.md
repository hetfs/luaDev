---
id: rust-linker-not-found
title: Rust Error - link.exe Not Found on Windows
sidebar_label: Fixing `link.exe` Not Found (Rust + MSVC)
description: Learn how to fix the "link.exe not found" error when building Rust projects on Windows with the MSVC toolchain.
keywords: [Rust, linker, MSVC, link.exe, cargo, build tools, Windows]
---

# ❗ Rust Error: `link.exe` Not Found on Windows

If you're running `cargo install` or building a Rust project on Windows and see this error:

```plaintext
error: linker `link.exe` not found
```

…it means Rust’s **MSVC toolchain** can’t locate `link.exe`, the Microsoft linker used to compile native code. This usually happens when the **MSVC build tools** are not installed or misconfigured.

---

## ✅ Install Visual Studio Build Tools (Recommended)

### 📥 Graphical Installer (Easy Option)

1. Download the [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/).

2. During installation, make sure to check the following:
   - ☑ **Desktop development with C++**
   - ☑ **Windows 10/11 SDK**
   - ☑ **MSVC v143 - VS 2022 C++ x64/x86 build tools**

### ⚙️ Command-Line Installer (Power Users)

You can also install the tools without opening a GUI:

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override `
  "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet"
```

> 💡 **Tip**: After installation, restart your terminal to refresh your environment.

---

## 🧪 Use the GNU Toolchain (Alternative)

If you don’t want to use MSVC or run into issues during installation, you can switch to the GNU toolchain:

```powershell
rustup default stable-x86_64-pc-windows-gnu
rustup show  # Confirms active Rust toolchain
```

> ⚠️ **Note**: Some crates (e.g. `windows-sys`) require MSVC for full compatibility with Windows APIs.

---

## 🔍 Manually Add `link.exe` to PATH

Sometimes `link.exe` is installed but still not found. You may need to manually add its location to your system’s `PATH`.

```powershell
# Example: Temporarily add MSVC linker path
$env:PATH += ";C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.39.33519\bin\Hostx64\x64"
```

> 🛠 To make it **permanent**, add the same path to your Windows **System Environment Variables**.

To confirm it’s working:

```powershell
where.exe link.exe
# You should see a valid path to link.exe
```

---

## 💡 Extra Notes

- **VS Code alone isn’t enough** — it doesn't install the MSVC toolchain.
- After installing MSVC tools, run:
  
  ```powershell
  rustup target add x86_64-pc-windows-msvc
  ```

- **MSVC vs. GNU**:
  - Prefer **MSVC** for better Windows integration, debugging support, and crate compatibility.
  - Use **GNU** if you're working on MinGW-based projects or need legacy support.

---

## ✅ Quick Setup Workflow (MSVC)

```powershell
# 1. Install MSVC Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools --override `
  "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet"

# 2. Use the MSVC toolchain
rustup default stable-x86_64-pc-windows-msvc

# 3. Build your project
cargo build
```

---

Need help with another Rust-related issue on Windows? Let us know on the [Rust forums](https://users.rust-lang.org/).
