*** Settings ***
Documentation    The Dynamics 365 lookup/search dialog used by lookup fields
...              across multiple entity forms.
Library          Browser

*** Variables ***
${LOOKUP_SEARCH_INPUT}    css=[data-id="lookup-search-input"]

*** Keywords ***
Zoek In Lookup
    [Documentation]    Types a search term into an open lookup dialog and selects the first result.
    [Arguments]    ${search_term}
    Fill Text    ${LOOKUP_SEARCH_INPUT}    ${search_term}
    Click    css=[data-id="lookup-result-item"] >> nth=0
