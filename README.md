# GitHub Token Setup Script for Arch Linux

## Overview

This script automates the process of configuring a **GitHub token** for authentication on **Arch Linux**. It securely retrieves the token from **Bitwarden CLI (`bw`)**, ensures necessary dependencies are installed, and sets up **Git credentials**.

🔹 **Features**:

- Ensures `bitwarden-cli` and `jq` are installed.
- Verifies Bitwarden login and unlocks it if necessary.
- Retrieves the GitHub token from a **custom field** in Bitwarden.
- Handles multiple search results and allows selection via **numbered index**.
- Configures `git` to use the retrieved token securely.

## Installation

### 1️⃣ Install Dependencies

Ensure you have **`bitwarden-cli`** and **`jq`** installed:

```bash
sudo pacman -S bitwarden-cli jq
```

Alternatively, the script will **automatically install them if missing**.

### 2️⃣ Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/github-token-setup.git
cd github-token-setup
```

### 3️⃣ Make the Script Executable

```bash
chmod +x setup_github_token.sh
```

## Usage

### Run the Script

```bash
./setup_github_token.sh
```

### What Happens?

1. The script **checks if `bw` and `jq` are installed** and installs them if missing.
2. It **checks if Bitwarden is logged in**:
   - If **not logged in**, prompts for login.
   - If **locked**, prompts for unlock.
3. The script **searches for your GitHub token in Bitwarden**:
   - If multiple results exist, **displays them with an index** for easy selection.
4. **Asks for the custom field name** where the token is stored.
5. **Retrieves the token** and **configures `git` authentication** using `git credential.helper`.
6. **Removes the token from memory for security**.

## Example Run

```
📦 Enter the name of the Bitwarden item storing your GitHub token: GitHub PAT
🔍 Found multiple items. Please select one:
1) Personal GitHub
2) Work GitHub
✏️ Enter the number of the correct Bitwarden item: 1
🔑 Enter the custom field name storing your GitHub token: token
🔍 Retrieving GitHub token from Bitwarden...
👤 Enter your GitHub username: myusername
🛠️ Choose Git credential storage method:
1) Store permanently (store)
2) Store temporarily (cache)
Enter your choice (1 or 2): 1
⚙️ Configuring GitHub authentication...
✅ GitHub authentication configured successfully!
```

## Security Notes

- The script **does NOT store your GitHub token in plaintext**.
- It **retrieves the token only when needed** and **removes it from memory** once configured.
- Ensure your **Bitwarden vault is secured with a strong master password**.

## Contributing

Feel free to **open issues** or **submit pull requests** to improve the script! 🚀
