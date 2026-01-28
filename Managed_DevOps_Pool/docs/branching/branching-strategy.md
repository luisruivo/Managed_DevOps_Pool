# Branching Strategy

## Branch Structure

### Long-Lived Branches

- `main` - Source of truth, production-ready code (deployed to **Dev**, **Test**, **Prod**)

### Short-Lived Feature Branches

- `feature/<type-of-change>-<ticket-number>` - New features/changes (deployed to **dev**)
  - Examples:
    - `feature/us-123`
    - `feature/bug-456`
    - `feature/docs-789`

### Bug Fix Branches

- `bugfix/<type-of-change>-<ticket-number>`
  - Example: `bugfix/bug-234`

### Hotfix Branches (Urgent Production Fixes)

- `hotfix/<type-of-change>-<ticket-number>`
  - Example: `hotfix/crit-567`
  - Workflow: branch from `main`, then merge back into `main` (and optionally `develop` if you use it).

### Release Branches (Optional)

- `release/<version>` - Prepare for production release
  - Example: `release/v1.2.0`

### Release Tags

- `v{n}-rc.{timestamp}` – Release candidate tags created automatically by the `deployment` pipeline after **Test** deployment (e.g. `v1-rc.2025-09-12_14-30`)
- `v{n}` – Stable tags created automatically by the `deployment` pipeline after **Prod** deployment (e.g. `v1`)

## Workflow

Pipelines live under [azure-pipelines](../azure-pipelines/README-UNIFIED-PIPELINE.md):

- Build: [`build.yaml`](../azure-pipelines/build.yaml)
- Deployment: [`deployment.yaml`](../azure-pipelines/deployment.yaml)

### 1. Development (Feature Branches)

```bash
# Create feature branch from main
git checkout main
git pull
git checkout -b feature/us-123

# Make changes and commit
git add .
git commit -m "Add VMSS pool configuration"

# Push to trigger dev deployment
git push origin feature/us-123
```

**What happens:**

- Push to `feature/*`, `bugfix/*`, or `hotfix/*` branches → **Build pipeline runs** ([`build.yaml`](../azure-pipelines/build.yaml))
  - Validates Terraform/Terragrunt syntax
  - Generates plan artifacts for Dev environment
  - **No deployment occurs**
- Create Pull Request to `main` → **Build pipeline runs again** (PR validation)

### 2. Deployment to Dev Environment

After PR review and approval, merge to main.

**What happens:**

- Merge to `main`:
  - **Build pipeline** ([`build.yaml`](../azure-pipelines/build.yaml)) runs automatically:
    - Validates infrastructure code
    - Generates and publishes Terraform plan artifacts
    - Publishes artifacts with Build ID (e.g., Build #123)
  - **Deployment pipeline** ([`deployment.yaml`](../azure-pipelines/deployment.yaml)) auto-triggers:
    - Downloads plan artifacts from Build #123
    - **DeployDev** stage runs:
      - **Manual approval required** (configurable via `requiresApproval` parameter)
      - Applies infrastructure from Build #123 plan artifacts
      - Deploys to Dev environment

**Alternative: Manual Deployment from Feature Branch:**

If you need to test a feature branch in Dev without merging:

1. Go to Azure DevOps → Pipelines → **Deployment Pipeline**
2. Click **Run pipeline**
3. Select your `feature/*` branch
4. Specify the Build ID from your feature branch build
5. Approve the deployment (if approval is enabled)

---

### 3. Testing (Test Environment)

Test deployment happens automatically after Dev succeeds.

**What happens:**

- After **Dev** deployment succeeds:
  - **DeployTest** stage runs automatically:
    - Downloads plan artifacts from the same Build ID used in Dev
    - Applies infrastructure to Test environment
    - **Manual approval required** before apply
    - Uploads deployment logs to blob storage

### 4. Production (Prod Environment)

After Test succeeds, the deployment pipeline:

1. Creates an RC tag (e.g. `v1-rc.2025-09-12_14-30`).
2. That RC tag is used to trigger the **Prod** deployment.

**Prod flow:**

- RC tag push (`v*-rc.*`) triggers [`deployment.yaml`](../azure-pipelines/deployment.yaml).
- Pipeline:
  - Downloads plan artifacts from the Build ID
  - **Manual approval required** before Prod apply
  - After successful Prod deployment, promotes RC tag to stable tag (e.g., `v1`)

## Branch Naming Conventions

### Feature Branches Naming

- **Format:** `feature/<type-of-change>-<ticket-number>`
- **Examples:**
  - `feature/us-123`
  - `feature/bug-456`
  - `feature/docs-789`

### Bug Fix Branches Naming

- **Format:** `bugfix/<type-of-change>-<ticket-number>`
- **Example:** `bugfix/bug-234`

### Hotfix Branches Naming (Urgent Production Fixes)

- **Format:** `hotfix/<type-of-change>-<ticket-number>`
- **Example:** `hotfix/crit-567`
- **Workflow:** Branch from `main`, merge back to `main` AND `develop`

## Branch Protection Rules

### `main` (Production)

- ✅ Require pull request reviews (minimum 2 approvers)
- ✅ Require status checks (Build pipelines must pass).
- ✅ No direct pushes
- ✅ Enforce for administrators

### `feature/*`, `bugfix/*`, `hotfix/*`  (Dev)

- ℹ️ **No branch protection rules** (allow direct pushes for development speed)
- ✅ Build pipeline runs automatically on every push (validation only)

---

## Environment Mapping

| Source Branch           | Trigger Event    | Build Pipeline | Deployment Pipeline | Environment | Approval Required |
|-------------------------|------------------|----------------|---------------------|-------------|-------------------|
| `feature/*`             | Push             | ✅ Auto         | ❌ No               | -           | -                 |
| `bugfix/*`              | Push             | ✅ Auto         | ❌ No               | -           | -                 |
| `hotfix/*`              | Push             | ✅ Auto         | ❌ No               | -           | -                 |
| `feature/*` → `main` PR | PR Created       | ✅ Auto         | ❌ No               | -           | -                 |
| `main`                  | Merge/Commit     | ✅ Auto         | ✅ Auto (Dev)       | Dev         | ✅ Yes            |
| `main`                  | After Dev        | ❌ No           | ✅ Auto (Test)      | Test        | ✅ Yes            |
| `v*-rc.*` tag           | RC Tag Push      | ❌ No           | ✅ Auto (Prod)      | Prod        | ✅ Yes           |

---

## Build Artifact Linking

The deployment pipeline uses a **Build Linkage Pattern** to ensure deployment consistency:

```yaml
# In deployment.yaml
resources:
  pipelines:
  - pipeline: buildPipeline
    source: 'Build Pipeline'
    trigger:
      branches:
        include:
        - main
```

**How it works:**

1. **Build Pipeline** runs on merge to `main` → Creates Build #123
2. Build #123 generates and publishes Terraform plan artifacts
3. **Deployment Pipeline** automatically triggers
4. Deployment downloads Build #123's plan artifacts
5. Deployment applies the exact plans from Build #123

**Benefits:**

- ✅ Guarantees Dev1 deploys Dev1's infrastructure (not someone else's changes)
- ✅ Immutable plans (no race conditions)
- ✅ Full traceability (Build ID → Deployment)
- ✅ Can redeploy any previous build by specifying `buildId` parameter

## Pull Request Guidelines

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Feature
- [ ] Bug fix
- [ ] Infrastructure change
- [ ] Documentation update

## Testing
- [ ] Tested locally
- [ ] Deployed to dev
- [ ] Verified in dev environment

## Checklist
- [ ] Code follows project style
- [ ] Tests pass
- [ ] Documentation updated
```

### Types of feature branches

- `us`: User story
- `bug`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Build/config changes
