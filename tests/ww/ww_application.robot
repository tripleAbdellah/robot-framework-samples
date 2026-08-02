*** Settings ***
Documentation    WW application end-to-end scenarios. Business scenarios only —
...              no selectors, no technical implementation.
Resource         ../../resources/business/authentication_keywords.resource
Resource         ../../resources/business/person_keywords.resource
Resource         ../../resources/business/ww_keywords.resource
Suite Setup      Zorg Voor Ingelogde Sessie En Dataverse Toegang
Suite Teardown   Close Browser

*** Test Cases ***
Registreer En Controleer WW Aanvraag
    [Documentation]    Registers a WW application as a caseworker and verifies its
    ...                status both in the UI and directly via Dataverse.
    Open Persoon    Ahmed Tester
    Registreer WW Aanvraag    WW
    Controleer Status Nieuw
    Controleer Record Via API    ${WW_APPLICATION_ID}    Nieuw
