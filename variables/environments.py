"""Dynamic Robot Framework variable file for per-environment configuration.

Usage: robot --variablefile variables/environments.py:acc tests/
"""

ENVIRONMENTS = {
    # DataverseClient appends /api/data/v9.2/ itself — DATAVERSE_URL is just the org root,
    # same host as LOGIN_URL (Dataverse's Web API is served from the org URL itself,
    # there is no separate api.*.dynamics.com host).
    "dev": {
        "LOGIN_URL": "https://tharass.crm4.dynamics.com/",
        "DATAVERSE_URL": "https://tharass.crm4.dynamics.com/",
    },
    "acc": {
        "LOGIN_URL": "https://ww-acc.crm4.dynamics.com/",
        "DATAVERSE_URL": "https://ww-acc.crm4.dynamics.com/",
    },
    "prod": {
        "LOGIN_URL": "https://ww.crm4.dynamics.com/",
        "DATAVERSE_URL": "https://ww.crm4.dynamics.com/",
    },
}


def get_variables(environment="dev"):
    if environment not in ENVIRONMENTS:
        raise ValueError(f"Unknown environment '{environment}'. Choose one of: {list(ENVIRONMENTS)}")
    return ENVIRONMENTS[environment]
