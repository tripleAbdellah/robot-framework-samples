*** Settings ***
Documentation    The Dynamics 365 command bar, shared across every entity page.
Library          Browser

*** Keywords ***
Klik Command Bar Knop
    [Documentation]    Clicks a command bar button by its visible label.
    [Arguments]    ${label}
    Click    css=button[aria-label="${label}"]
