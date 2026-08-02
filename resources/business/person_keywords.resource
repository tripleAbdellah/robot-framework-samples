*** Settings ***
Documentation    Business-level keywords for the Person entity. Combines UI navigation
...              (page objects) with API setup/verification (Dataverse keywords).
Resource         ../pages/person_page.resource
Resource         ../api/dataverse_keywords.resource

*** Keywords ***
Open Persoon
    [Documentation]    Navigates to an existing person record by name.
    [Arguments]    ${person_name}
    Open Person Page    ${person_name}

Registreer Nieuwe Persoon
    [Documentation]    Creates a person via the API, then opens it in the UI.
    [Arguments]    ${voornaam}    ${achternaam}
    ${person_id}=    Create Dataverse Person    ${voornaam}    ${achternaam}
    Open Persoon    ${voornaam} ${achternaam}
    RETURN    ${person_id}
