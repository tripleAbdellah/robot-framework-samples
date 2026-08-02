*** Settings ***
Documentation    Business-level keywords for the WW (unemployment benefit) application
...              process. Combines UI actions with API validation.
Resource         ../pages/ww_application_page.resource
Resource         ../api/dataverse_keywords.resource

*** Keywords ***
Registreer WW Aanvraag
    [Documentation]    Registers a new WW application via the UI.
    [Arguments]    ${uitkeringstype}
    Open Nieuwe WW Aanvraag
    Vul Uitkeringstype In    ${uitkeringstype}
    Klik Opslaan

Controleer Status Nieuw
    [Documentation]    Verifies the WW application shows status "Nieuw" in the UI.
    ${status}=    Lees Status
    Should Be Equal    ${status}    Nieuw

Controleer Record Via API
    [Documentation]    Verifies the WW application's state directly via Dataverse,
    ...                independent of what the UI displays.
    [Arguments]    ${ww_application_id}    ${expected_status}
    ${application}=    Get WW Application    ${ww_application_id}
    Should Be Equal    ${application}[status]    ${expected_status}
