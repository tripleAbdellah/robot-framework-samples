*** Settings ***
Documentation    Governance audit: every custom Dataverse table must follow naming
...              convention, have a description, have an icon configured, and (if
...              ${EXPECTED_OWNERSHIP} is set) share the expected ownership type.
...              Stateless — no baseline file, applies to whatever custom tables
...              currently exist. Uses the same Get Custom Tables keyword regardless
...              of ${AUTH_MODE}.
Library          Collections
Resource         ../../resources/business/authentication_keywords.resource
Resource         ../../resources/api/table_conventions.resource
Suite Setup      Setup For Auth Mode
Suite Teardown   Teardown For Auth Mode

*** Keywords ***
Setup For Auth Mode
    [Documentation]    Only auth_mode=browser needs a logged-in browser session — MSAL
    ...                (service_principal) authenticates itself when DataverseLibrary is
    ...                imported.
    IF    "${AUTH_MODE}" == "browser"
        Zorg Voor Ingelogde Sessie En Dataverse Toegang
    END

Teardown For Auth Mode
    IF    "${AUTH_MODE}" == "browser"
        Close Browser
    END

*** Test Cases ***
All Custom Tables Follow Naming, Description, Icon Conventions
    [Documentation]    Audits every custom table at once and reports every violation
    ...                found, not just the first — this is meant to read as a QA
    ...                report, not a single yes/no.
    ${violations}=    Get Table Convention Violations
    FOR    ${violation}    IN    @{violations}
        Log    [${violation}[rule]] ${violation}[message]    level=WARN
    END
    ${violation_count}=    Get Length    ${violations}
    Should Be Equal As Integers    ${violation_count}    0
    ...    msg=${violation_count} table(s) violate naming/description/icon conventions — see the WARN-level log entries above for details.
