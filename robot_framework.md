# Robot Framework Enterprise Structure

A common enterprise setup separates business logic, UI interactions, API calls, test data, and reusable components.

```text
tests/
├── ww/
│   └── ww_application.robot

resources/
├── business/
│   ├── authentication_keywords.resource
│   ├── person_keywords.resource
│   └── ww_keywords.resource
│
├── pages/
│   ├── login_page.resource
│   ├── person_page.resource
│   └── ww_application_page.resource
│
├── components/
│   ├── notification_bar.resource
│   ├── lookup_dialog.resource
│   └── command_bar.resource
│
├── api/
│   └── dataverse_keywords.resource
│
└── common/
    └── common_keywords.resource

libraries/
└── DataverseLibrary.py

data/
├── ww_testdata.yaml
└── persons.csv

variables/
└── environments.py
```

## Layered architecture

```text
Test Case
    ↓
Business Keywords
    ↓
Page / Component Objects
    ↓
Browser Library (Playwright)
    ↓
Dynamics 365 UI

                +

Business Keywords
    ↓
API Keywords
    ↓
Python Library
    ↓
Dataverse Web API
```

## Responsibilities

### Test Cases
- Describe the business scenario.
- No selectors.
- No technical implementation.

Example:

```robot
Login Als Behandelaar
Open Persoon
Registreer WW Aanvraag
Controleer Status Nieuw
Controleer Record Via API
```

---

### Business Keywords
- Describe business processes.
- Combine UI and API actions.
- Hide technical implementation.

Example:

```robot
Registreer WW Aanvraag
Controleer WW Status
```

---

### Page Objects
- Contain UI interactions.
- Centralize selectors.
- Hide browser implementation.

Example:

```robot
Open Nieuwe WW Aanvraag
Vul Uitkeringstype In
Klik Opslaan
Lees Status
```

---

### Component Objects
Reusable UI elements shared across pages.

Examples:

- Notification Bar
- Lookup Dialog
- Command Bar
- Grid
- Tabs
- Date Picker

---

### API Layer
- Create test data
- Read records
- Cleanup
- Validate database state

Example:

```robot
Create Dataverse Person
Get WW Application
Delete Person
```

---

### Python Libraries
Contain technical implementation:

- Dataverse REST API
- Authentication
- Utility functions
- UUID generation
- JSON handling

---

### Test Data

Prefer external data sources.

Example:

```yaml
persoon:
  voornaam: Ahmed
  achternaam: Tester

ww_aanvraag:
  uitkeringstype: WW
  verwacht_status: Nieuw
```

or

- CSV
- JSON
- Database
- Test Data Builder

---

## Recommended Flow

```text
YAML / CSV
      ↓
Test Case
      ↓
Business Keywords
      ↓
Page Objects
      ↓
Browser Library
      ↓
Dynamics UI

           +

Business Keywords
      ↓
API Layer
      ↓
Dataverse
```

This architecture keeps business scenarios readable while separating UI logic, API interactions, and test data for maintainability and reuse.