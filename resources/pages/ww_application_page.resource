*** Settings ***
Documentation    Selectors and interactions for the WW application form.
Library          Browser
Resource         ../components/command_bar.resource

*** Variables ***
${UITKERINGSTYPE_FIELD}    css=[data-id="uitkeringstype.fieldControl-text-box-text"]
${STATUS_FIELD}            css=[data-id="statuscode.fieldControl-text-box-text"]

*** Keywords ***
Open Nieuwe WW Aanvraag
    [Documentation]    Opens a blank WW application form.
    Klik Command Bar Knop    Nieuw

Vul Uitkeringstype In
    [Documentation]    Fills in the benefit type field.
    [Arguments]    ${uitkeringstype}
    Fill Text    ${UITKERINGSTYPE_FIELD}    ${uitkeringstype}

Klik Opslaan
    [Documentation]    Saves the current form via the command bar.
    Klik Command Bar Knop    Opslaan

Lees Status
    [Documentation]    Reads the current status value shown on the form.
    ${status}=    Get Text    ${STATUS_FIELD}
    RETURN    ${status}
