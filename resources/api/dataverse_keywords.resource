*** Settings ***
Documentation    Business-facing keywords for creating/reading/cleaning up test data and
...              validating table structure via the Dataverse Web API. Every keyword here
...              dispatches on ${AUTH_MODE} between two transports:
...
...              - service_principal: the Python DataverseLibrary (MSAL bearer token).
...              - browser (default): in-page fetch() via dataverse_browser_transport.resource
...                — needed because a plain cookie replay from Python returned 401 against
...                a real tenant; running inside the already-authenticated page picks up
...                whatever actually authenticates the app's own calls.
...
...              Callers above this layer (business keywords, tests) never see this split —
...              same keyword names and signatures regardless of ${AUTH_MODE}.
...
...              ${AUTH_MODE}=service_principal also requires the DATAVERSE_CLIENT_ID /
...              DATAVERSE_CLIENT_SECRET / DATAVERSE_TENANT_ID environment variables —
...              never hardcoded, these are live Azure AD credentials.
Library          Collections
Library          ../../libraries/DataverseLibrary.py
...              environment_url=${DATAVERSE_URL}
...              auth_mode=${AUTH_MODE}
...              client_id=%{DATAVERSE_CLIENT_ID=${EMPTY}}
...              client_secret=%{DATAVERSE_CLIENT_SECRET=${EMPTY}}
...              tenant_id=%{DATAVERSE_TENANT_ID=${EMPTY}}
Resource         dataverse_browser_transport.resource

*** Variables ***
${DATAVERSE_URL}    ${EMPTY}      # TODO: set via variables/environments.py
${AUTH_MODE}    ${{'service_principal' if '%{DATAVERSE_USE_API=false}'.lower() == 'true' else 'browser'}}    # driven by DATAVERSE_USE_API in .env; -v AUTH_MODE:... on the command line overrides this

*** Keywords ***
Create Dataverse Person
    [Documentation]    Creates a person record via the Dataverse Web API. Returns its id.
    [Arguments]    ${voornaam}    ${achternaam}
    ${data}=    Create Dictionary    firstname=${voornaam}    lastname=${achternaam}
    IF    "${AUTH_MODE}" == "browser"
        ${person_id}=    Create Record In Browser    persons    ${data}
    ELSE
        ${person_id}=    DataverseLibrary.Create Record    persons    ${data}
    END
    RETURN    ${person_id}

Get WW Application
    [Documentation]    Fetches a WW application record via the Dataverse Web API.
    [Arguments]    ${ww_application_id}
    IF    "${AUTH_MODE}" == "browser"
        ${application}=    Get Record In Browser    ww_applications    ${ww_application_id}
    ELSE
        ${application}=    DataverseLibrary.Get Record    ww_applications    ${ww_application_id}
    END
    RETURN    ${application}

Delete Person
    [Documentation]    Deletes a person record via the Dataverse Web API (test cleanup).
    [Arguments]    ${person_id}
    IF    "${AUTH_MODE}" == "browser"
        Delete Record In Browser    persons    ${person_id}
    ELSE
        DataverseLibrary.Delete Record    persons    ${person_id}
    END

Get Table Metadata
    [Documentation]    Fetches table (entity) metadata — attributes, types, display
    ...                names — for table-structure validation.
    [Arguments]    ${logical_name}
    IF    "${AUTH_MODE}" == "browser"
        ${metadata}=    Get Table Metadata In Browser    ${logical_name}
    ELSE
        ${metadata}=    DataverseLibrary.Get Table Metadata    ${logical_name}
    END
    RETURN    ${metadata}

Get Table Metadata By Display Name
    [Documentation]    Resolves a table's logical name from its display name (e.g. the
    ...                name shown in the UI, like "Klant") and fetches its metadata.
    ...                EntityDefinitions itself only accepts the logical name, which is
    ...                usually lowercase and often publisher-prefixed.
    [Arguments]    ${display_name}
    IF    "${AUTH_MODE}" == "browser"
        ${logical_name}=    Get Table Logical Name In Browser    ${display_name}
    ELSE
        ${logical_name}=    DataverseLibrary.Get Table Logical Name    ${display_name}
    END
    ${metadata}=    Get Table Metadata    ${logical_name}
    RETURN    ${metadata}

Get Custom Tables
    [Documentation]    Fetches every custom table's metadata, for convention checks.
    IF    "${AUTH_MODE}" == "browser"
        ${tables}=    List Custom Tables In Browser
    ELSE
        ${tables}=    DataverseLibrary.List Custom Tables
    END
    RETURN    ${tables}

Get Main Forms
    [Documentation]    Fetches every active Main Form for a table, for convention checks.
    [Arguments]    ${logical_name}
    IF    "${AUTH_MODE}" == "browser"
        ${forms}=    List Main Forms In Browser    ${logical_name}
    ELSE
        ${forms}=    DataverseLibrary.List Main Forms    ${logical_name}
    END
    RETURN    ${forms}
