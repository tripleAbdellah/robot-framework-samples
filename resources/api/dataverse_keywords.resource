*** Settings ***
Documentation    Business-facing keywords for creating/reading/cleaning up test data and
...              validating table structure via the Dataverse Web API. Every keyword here
...              calls Call Dataverse, which dispatches on ${AUTH_MODE} between two
...              transports:
...
...              - service_principal: the Python DataverseLibrary (MSAL bearer token).
...              - browser (default): in-page fetch() via dataverse_browser_client.resource
...                — needed because a plain cookie replay from Python returned 401 against
...                a real tenant; running inside the already-authenticated page picks up
...                whatever actually authenticates the app's own calls.
...
...              Callers above this layer (business keywords, tests) never see this split —
...              same keyword names and signatures regardless of ${AUTH_MODE}.
...
...              DataverseLibrary's constructor takes no auth arguments — it's imported
...              unconditionally regardless of ${AUTH_MODE}, so it can't require
...              credentials at import time. Under service_principal mode, Setup For Auth
...              Mode (authentication_keywords.resource) explicitly calls
...              DataverseLibrary.Initialize Service Principal with the DATAVERSE_CLIENT_ID
...              / DATAVERSE_CLIENT_SECRET / DATAVERSE_TENANT_ID environment variables —
...              never hardcoded, these are live Azure AD credentials.
Library          Collections
Library          ../../libraries/DataverseLibrary.py    environment_url=${DATAVERSE_URL}
Resource         dataverse_browser_client.resource

*** Variables ***
${DATAVERSE_URL}    ${EMPTY}      # TODO: set via variables/environments.py
${AUTH_MODE}    ${{'service_principal' if '%{DATAVERSE_USE_API=false}'.lower() == 'true' else 'browser'}}    # driven by DATAVERSE_USE_API in .env; -v AUTH_MODE:... on the command line overrides this

*** Keywords ***
Call Dataverse
    [Documentation]    Dispatches one Dataverse operation to whichever transport
    ...                ${AUTH_MODE} selects, so business keywords below don't each need
    ...                their own IF/ELSE. ${operation} must exist as BOTH a
    ...                "<operation> In Browser" keyword (dataverse_browser_client.resource)
    ...                and a "DataverseLibrary.<operation>" keyword (DataverseLibrary.py),
    ...                with matching argument signatures.
    ...
    ...                Tradeoff worth knowing: because the keyword name is computed at
    ...                runtime (Run Keyword), `robot --dryrun` can no longer catch a
    ...                misspelled ${operation} the way the old explicit IF/ELSE calls
    ...                could — a typo here only surfaces when that AUTH_MODE branch
    ...                actually runs, not at parse time. Verify new operations live
    ...                under both auth modes, not just via dry run.
    [Arguments]    ${operation}    @{args}
    ${keyword}=    Set Variable If    "${AUTH_MODE}" == "browser"    ${operation} In Browser    DataverseLibrary.${operation}
    ${result}=    Run Keyword    ${keyword}    @{args}
    RETURN    ${result}

Who Am I
    [Documentation]    Calls the Dataverse WhoAmI endpoint — the simplest possible
    ...                connectivity/auth smoke test, useful as a fast pre-flight check
    ...                before running heavier suites.
    ${result}=    Call Dataverse    Who Am I
    RETURN    ${result}

Create Dataverse Person
    [Documentation]    Creates a person record via the Dataverse Web API. Returns its id.
    [Arguments]    ${voornaam}    ${achternaam}
    ${data}=    Create Dictionary    firstname=${voornaam}    lastname=${achternaam}
    ${person_id}=    Call Dataverse    Create Record    persons    ${data}
    RETURN    ${person_id}

Get WW Application
    [Documentation]    Fetches a WW application record via the Dataverse Web API.
    [Arguments]    ${ww_application_id}
    ${application}=    Call Dataverse    Get Record    ww_applications    ${ww_application_id}
    RETURN    ${application}

Delete Person
    [Documentation]    Deletes a person record via the Dataverse Web API (test cleanup).
    [Arguments]    ${person_id}
    Call Dataverse    Delete Record    persons    ${person_id}

Get Table Metadata
    [Documentation]    Fetches table (entity) metadata — attributes, types, display
    ...                names — for table-structure validation.
    [Arguments]    ${logical_name}
    ${metadata}=    Call Dataverse    Get Table Metadata    ${logical_name}
    RETURN    ${metadata}

Get Table Metadata By Display Name
    [Documentation]    Resolves a table's logical name from its display name (e.g. the
    ...                name shown in the UI, like "Klant") and fetches its metadata.
    ...                EntityDefinitions itself only accepts the logical name, which is
    ...                usually lowercase and often publisher-prefixed.
    [Arguments]    ${display_name}
    ${logical_name}=    Call Dataverse    Get Table Logical Name    ${display_name}
    ${metadata}=    Get Table Metadata    ${logical_name}
    RETURN    ${metadata}

Get Custom Tables
    [Documentation]    Fetches every custom table's metadata, for convention checks.
    ${tables}=    Call Dataverse    List Custom Tables
    RETURN    ${tables}

Get Main Forms
    [Documentation]    Fetches every active Main Form for a table, for convention checks.
    [Arguments]    ${logical_name}
    ${forms}=    Call Dataverse    List Main Forms    ${logical_name}
    RETURN    ${forms}
