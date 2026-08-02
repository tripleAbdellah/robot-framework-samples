*** Settings ***
Documentation    Selectors and interactions for the Person entity form.
Library          Browser

*** Variables ***
${PERSON_SEARCH_INPUT}    css=[data-id="quickFindBox"]

*** Keywords ***
Open Person Page
    [Documentation]    Searches for and opens a person record by full name.
    [Arguments]    ${person_name}
    Fill Text    ${PERSON_SEARCH_INPUT}    ${person_name}
    Press Keys    ${PERSON_SEARCH_INPUT}    Enter
    Click    text=${person_name}
