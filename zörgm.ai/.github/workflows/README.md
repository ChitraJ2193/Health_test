# GitHub Actions Workflows

## SonarCloud Analysis

This workflow runs SonarCloud code analysis on every push and pull request to `main` and `develop` branches.

### Setup Requirements

1. **SonarCloud Token**: Add `SONAR_TOKEN` to your GitHub repository secrets
   - Go to: Settings → Secrets and variables → Actions
   - Add a new secret named `SONAR_TOKEN`
   - Get the token from: https://sonarcloud.io → My Account → Security

2. **Project Structure**: Ensure the following structure exists:
   ```
   zorgm.ai-app/
     ios/
       sonar-project.properties
       Sources/
   ```

3. **SonarCloud Project**: Make sure the project is configured in SonarCloud with:
   - Project Key: `zorgm.ai-ios`
   - Organization: `laennec-ai`

### Workflow Steps

1. **Checkout**: Checks out the repository code
2. **Install Sonar Scanner**: Downloads and installs Sonar Scanner CLI
3. **Run Analysis**: Executes Sonar Scanner in the `ios` folder
4. **Quality Gate Check**: Verifies the quality gate status and blocks merge if failed

### Quality Gate

The workflow will:
- ✅ **PASS**: If quality gate status is "OK" → merge allowed
- ❌ **FAIL**: If quality gate status is not "OK" → merge blocked

