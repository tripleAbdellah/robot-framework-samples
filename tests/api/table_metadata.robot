*** Settings ***
Documentation    Table (entity) metadata / structure validation. Uses the same
...              Get Table Metadata By Display Name keyword regardless of ${AUTH_MODE} —
...              which transport (in-page fetch vs. the Python client) runs underneath
...              is invisible from here.
Library          Browser
Library          Collections
Resource         ../../resources/business/authentication_keywords.resource
Suite Setup      Setup For Auth Mode
Suite Teardown   Teardown For Auth Mode

*** Keywords ***
Setup For Auth Mode
    [Documentation]    Only auth_mode=browser needs a logged-in browser session — MSAL
    ...                (service_principal) authenticates itself when DataverseLibrary is
    ...                imported, so opening a browser (and possibly hitting MFA) for a
    ...                purely API-driven suite would be pointless overhead.
    IF    "${AUTH_MODE}" == "browser"
        Zorg Voor Ingelogde Sessie En Dataverse Toegang
    END

Teardown For Auth Mode
    IF    "${AUTH_MODE}" == "browser"
        Close Browser
    END

*** Test Cases ***
Klant Table Exists And Is Readable
    [Documentation]    Resolves the 'Klant' table's logical name (confirmed live:
    ...                'new_klant') and confirms its metadata is readable, asserting on
    ...                its real columns (confirmed live: new_name, new_last_name,
    ...                new_age, primary key new_klantid).
    ${metadata}=    Get Table Metadata By Display Name    Klant
    Should Be Equal    ${metadata}[PrimaryIdAttribute]      new_klantid
    Should Be Equal    ${metadata}[PrimaryNameAttribute]    new_name
    ${attribute_names}=    Evaluate    [a['LogicalName'] for a in $metadata['Attributes']]
    List Should Contain Value    ${attribute_names}    new_name
    List Should Contain Value    ${attribute_names}    new_last_name
    List Should Contain Value    ${attribute_names}    new_age
