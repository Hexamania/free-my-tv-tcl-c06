# FreeMyTV (TCL C06 Edition)

A project for managing, customizing, and replacing the default launcher experience on Android TV, Fire TV, Google TV, WebOS, and Tizen platforms.

---

## ⚠️ Critical Prerequisite: Required Tools & Environment

To successfully compile binaries or run scripts from Windows, **you must use Git Bash (or MSYS2)** paired with specific toolchains. Standard Windows Command Prompt (`cmd.exe`) or PowerShell will fail due to automatic path translation and Gradle execution mismatches.

### 1. Required Toolchains
Before running any build scripts, ensure you have downloaded and installed/extracted the following dependencies:
* **Shell Environment:** [Git for Windows (Git Bash)](https://git-scm.com/download/win) or MSYS2.
* **Java Development Kit:** [Adoptium Eclipse Temurin JDK 17 LTS](https://adoptium.net/).
* **Android SDK:** [Android Command-line Tools Only](https://developer.android.com/studio#command-tools) (extracted to your SDK directory, e.g., `F:/Android`).

### 2. Environment Variables & Compilation One-Liner
When compiling the project via Git Bash, execute the following environment configuration to patch JDK 17 paths, bypass version checks, and force MSYS path-translation compliance (`MSYS_NO_PATHCONV=1`):

```bash
export JAVA_HOME="/f/jdk-17.0.20.1+1" PATH="/f/jdk-17.0.20.1+1/bin:/f/platform-tools:$PATH" ANDROID_HOME="F:/Android" ANDROID_SDK_ROOT="F:/Android" SKIP_JDK_VERSION_CHECK=1 MSYS_NO_PATHCONV=1
(Note: Adjust drive letters and folder names to match your actual local installation paths).

🧹 Debloating & Storage Optimization
If your TV reports "not enough space" or low storage errors, or if you want to debloat system packages safely, use the companion debloat suite built specifically for this TV model:

👉 TCL C06 Debloat Suite Repository

🛠️ The Core Technical Discovery: The "Leanback Focus Bug"
Many generic community debloat utilities break Bluetooth pairing menus on Android TVs.

The Issue: Disabling stock background packages can inadvertently disable com.google.android.tvrecommendations ("Android TV Core Services"). While often perceived as home screen adware, Google tightly couples the Leanback User Interface Framework into this package on Android TV versions 9, 10, and 11.

The Symptom: Without this package, the system cannot calculate D-Pad focus trees or load theme layouts for custom system overlay windows (such as BluetoothPairingDialog). The pairing window renders completely "dead" to remote control inputs (ignoring keycode 23 / OK button clicks), causing Bluetooth audio pairings to time out and fail.

The Solution: Keep com.google.android.tvrecommendations enabled to safeguard focus tree navigation:

Bash
adb shell pm enable com.google.android.tvrecommendations
🚀 Building & Usage
Clone the repository:

Bash
git clone [https://github.com/Hexamania/free-my-tv-tcl-c06.git](https://github.com/Hexamania/free-my-tv-tcl-c06.git)
cd free-my-tv-tcl-c06
Set terminal variables:
Run the environment export one-liner in Git Bash.

Execute the build script:

Bash
./build.sh

# 📜 License
Distributed under the MIT License. See LICENSE for more information.