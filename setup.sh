#!/bin/bash

# Function to check if a package is installed and install it if missing
install_package() {
    local package=$1
    if ! pacman -Q "$package" &> /dev/null; then
        echo "🛠️ $package is not installed. Installing..."
        sudo pacman -S "$package"
    else
        echo "✅ $package is already installed."
    fi
}

# Ensure Bitwarden CLI (`bitwarden-cli`) and `jq` are installed
install_package "bitwarden-cli"
install_package "jq"

# Check Bitwarden authentication status
BW_STATUS=$(bw status | jq -r '.status')

if [[ "$BW_STATUS" == "unauthenticated" ]]; then
    echo "🔑 You are not logged into Bitwarden. Please log in."
    bw login
elif [[ "$BW_STATUS" == "locked" ]]; then
    echo "🔒 Bitwarden is locked. Unlocking..."
    bw unlock
else
    echo "✅ Bitwarden is already unlocked."
fi

# Ask for the Bitwarden item name that contains the GitHub token
read -p "📦 Enter the name of the Bitwarden item storing your GitHub token: " BW_GITHUB_ITEM

# Search for the Bitwarden item and handle multiple results
ITEMS_JSON=$(bw list items --search "$BW_GITHUB_ITEM")
ITEM_COUNT=$(echo "$ITEMS_JSON" | jq '. | length')

if [[ "$ITEM_COUNT" -eq 0 ]]; then
    echo "❌ No matching Bitwarden items found. Please check the item name."
    exit 1
elif [[ "$ITEM_COUNT" -eq 1 ]]; then
    # Automatically select the only result
    BW_ITEM_ID=$(echo "$ITEMS_JSON" | jq -r '.[0].id')
    echo "✅ Found one matching item: $(echo "$ITEMS_JSON" | jq -r '.[0].name')"
else
    echo "🔍 Found multiple items. Please select one:"
    for i in $(seq 0 $((ITEM_COUNT - 1))); do
        ITEM_NAME=$(echo "$ITEMS_JSON" | jq -r ".[$i].name")
        echo "$((i + 1))) $ITEM_NAME"
    done

    # Ask user to select an item by number
    read -p "✏️ Enter the number of the correct Bitwarden item: " ITEM_INDEX
    ITEM_INDEX=$((ITEM_INDEX - 1)) # Convert to zero-based index

    # Validate input
    if [[ "$ITEM_INDEX" -lt 0 || "$ITEM_INDEX" -ge "$ITEM_COUNT" ]]; then
        echo "❌ Invalid selection. Please try again."
        exit 1
    fi

    # Get the selected item's ID
    BW_ITEM_ID=$(echo "$ITEMS_JSON" | jq -r ".[$ITEM_INDEX].id")
fi

# Ask for the custom field name where the token is stored
read -p "🔑 Enter the custom field name storing your GitHub token: " BW_FIELD_NAME

# Retrieve the GitHub token from the selected Bitwarden item (from user-specified custom field)
echo "🔍 Retrieving GitHub token from Bitwarden..."
GITHUB_TOKEN=$(bw get item "$BW_ITEM_ID" | jq -r --arg FIELD_NAME "$BW_FIELD_NAME" '.fields[] | select(.name==$FIELD_NAME) | .value')

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Failed to retrieve GitHub token. Ensure the correct custom field exists in Bitwarden."
    exit 1
fi

# Ask for the GitHub username
read -p "👤 Enter your GitHub username: " GITHUB_USERNAME

# Ask whether to store the credentials permanently or temporarily
echo "🛠️ Choose Git credential storage method:"
echo "1) Store permanently (store)"
echo "2) Store temporarily (cache)"
read -p "Enter your choice (1 or 2): " STORAGE_CHOICE

if [[ "$STORAGE_CHOICE" == "1" ]]; then
    GIT_CREDENTIAL_HELPER="store"
elif [[ "$STORAGE_CHOICE" == "2" ]]; then
    GIT_CREDENTIAL_HELPER="cache"
else
    echo "❌ Invalid choice. Defaulting to 'store'."
    GIT_CREDENTIAL_HELPER="store"
fi

# Configure git with the token
echo "⚙️ Configuring GitHub authentication..."
git config --global credential.helper "$GIT_CREDENTIAL_HELPER"
git credential reject "https://github.com" > /dev/null 2>&1  # Remove any old credentials

# Store credentials for GitHub
cat <<EOF | git credential approve
protocol=https
host=github.com
username=$GITHUB_USERNAME
password=$GITHUB_TOKEN
EOF

# Securely remove token from memory
unset GITHUB_TOKEN

echo "✅ GitHub authentication configured successfully!"
