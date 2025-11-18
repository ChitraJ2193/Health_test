# SonarCloud Setup Instructions

## ⚠️ IMPORTANT: Security Notice

**DO NOT commit tokens or secrets to the repository!** Always use GitHub Secrets.

## Setting Up SonarCloud Token

### Step 1: Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following:
   - **Name**: `_IOS_SONAR_TOKEN`
   - **Value**: `d0a8aa2ee18640b8892ecb6040f775566ffdd4df`
5. Click **Add secret**

### Step 2: Verify Workflow

The workflow file (`.github/workflows/sonarcloud.yml`) is already configured to use:
- Secret name: `_IOS_SONAR_TOKEN`
- Project key: `zorgm.ai-ios`
- Organization: `laennec-ai`

### Step 3: Test the Workflow

1. Push to `main` or `develop` branch, OR
2. Create a pull request, OR
3. Manually trigger via **Actions** tab → **SonarCloud Analysis** → **Run workflow**

## Token Information (for reference)

- **Key**: `_IOS_SONAR_TOKEN`
- **Value**: `d0a8aa2ee18640b8892ecb6040f775566ffdd4df`
- **Location**: GitHub Repository Secrets (not in code files)

## Project Configuration

- **Project Key**: `zorgm.ai-ios`
- **Organization**: `laennec-ai`
- **SonarCloud URL**: `https://sonarcloud.io`

