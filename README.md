# Robot-App

Robot Framework test automation project.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
rfbrowser init   # installs Playwright's browser binaries
cp .env.example .env   # fill in real values — .env is git-ignored, never commit it
```

## Environment variables

Credentials live in `.env` (git-ignored) — see [.env.example](.env.example) for the full list
(`DATAVERSE_USERNAME`/`PASSWORD` for `auth_mode=browser`, `DATAVERSE_CLIENT_ID`/`CLIENT_SECRET`/
`TENANT_ID` for `auth_mode=service_principal`). Load it before running `robot`:

```bash
set -a; source .env; set +a
```

`DATAVERSE_USE_API` (`true`/`false` in `.env`) picks the default `${AUTH_MODE}` — `true` means
`service_principal` (API-only, no browser/MFA), `false`/unset means `browser`. A command-line
`-v AUTH_MODE:...` still overrides it for a one-off different choice.

## Run tests

Generic/local suites (no Dynamics 365 environment needed):

```bash
robot -d results tests/example.robot tests/browser_example.robot
```

Against the real `dev` environment (`tharass.crm4.dynamics.com`), after loading `.env` as above:

```bash
robot --variablefile variables/environments.py:dev -d results tests/ww/ tests/api/
```

Or explicitly with `auth_mode=service_principal` (no browser/MFA at all — see below):

```bash
robot --variablefile variables/environments.py:dev -v AUTH_MODE:service_principal -d results tests/api/
```

**First run only:** if MFA/Authenticator is required, `Zorg Voor Ingelogde Sessie En Dataverse
Toegang` (Suite Setup) opens a *visible* browser and waits up to 2 minutes for you to approve the
sign-in on your phone. Once approved, the session (cookies + local storage) is saved to `.auth/`
(git-ignored — treat it like a password). Every run after that reuses the saved session and runs
fully headless, with no MFA prompt at all — until the session itself expires, at which point it
automatically falls back to another visible/interactive login.

## Layout

Layered enterprise structure — see [robot_framework.md](robot_framework.md) for the full rationale.

```text
tests/
├── example.robot              # generic sanity check
├── browser_example.robot      # Browser library smoke test
├── ww/
│   └── ww_application.robot   # WW business scenarios (UI + API)
└── api/
    └── table_metadata.robot   # table/entity metadata validation (API only)

resources/
├── business/     # business-process keywords (combine UI + API)
├── pages/        # page objects — selectors live here only
├── components/   # reusable UI elements (command bar, notifications, lookups)
├── api/          # Dataverse keyword wrappers — dispatches per ${AUTH_MODE}, see below
└── common/       # shared keywords

libraries/
├── DataverseLibrary.py     # Robot-facing keyword layer (auth_mode=service_principal only)
└── dataverse/
    ├── client.py            # auth-agnostic Dataverse Web API HTTP client (Python/requests)
    └── auth/
        ├── base.py                # AuthProvider interface
        └── service_principal.py  # Azure AD client-credentials via MSAL

data/
├── ww_testdata.yaml
└── persons.csv

variables/
└── environments.py       # dynamic variable file, e.g. --variablefile variables/environments.py:acc
```

## Dataverse authentication

Every keyword in [resources/api/dataverse_keywords.resource](resources/api/dataverse_keywords.resource)
(`Get Table Metadata`, `Create Record`, etc.) dispatches on `${AUTH_MODE}` between two transports —
callers above this layer never see the split:

- **`auth_mode=browser`** (default) — calls run as `fetch()` executed *inside* the already
  logged-in page (`resources/api/dataverse_browser_transport.resource`), not from Python. This is
  confirmed necessary, not a style choice: a plain cookie replay from an external Python client
  returned 401 against the real tenant, so something beyond cookies authenticates the app's own
  calls (its own requests carry `x-ms-sw-*` headers, suggesting a Service Worker-injected token).
  Running inside the page picks up whatever that is automatically. Needs `DATAVERSE_USERNAME` /
  `DATAVERSE_PASSWORD` (see `.env.example`) for the one-time interactive login.
- **`auth_mode=service_principal`** — the Python `DataverseLibrary`/`DataverseClient`, Azure AD
  client-credentials flow via MSAL. No browser or MFA needed at all. Requires an Azure AD app
  registration **and** a Dataverse Application User with a security role in the target environment
  (two separate admin steps, in two separate portals — Entra ID for the app registration,
  admin.powerplatform.microsoft.com for the Application User). Needs `DATAVERSE_CLIENT_ID` /
  `DATAVERSE_CLIENT_SECRET` / `DATAVERSE_TENANT_ID` (see `.env.example`).

`variables/environments.py`'s `dev` entry points at the real `tharass.crm4.dynamics.com` org
(confirmed live) — Dataverse's Web API is served from the org's own host, not a separate `api.*`
subdomain, so `DataverseClient` appends `/api/data/v9.2/` itself. `acc`/`prod` are still
placeholders. `EntityDefinitions` (table metadata) has real quirks confirmed against this tenant:
no server-side filtering on `DisplayName`, and no `$top` support — `get_table_logical_name` works
around both by fetching all tables and matching client-side. The `Klant` display name resolves to
logical name `new_klant` (columns: `new_name`, `new_last_name`, `new_age`, primary key
`new_klantid`) — confirmed live, used as the example in `tests/api/table_metadata.robot`.
