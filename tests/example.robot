*** Settings ***
Documentation    Example test suite demonstrating the project scaffold.
Resource         ../resources/common/common_keywords.resource

*** Test Cases ***
Sanity Check
    [Documentation]    Confirms the Robot Framework setup runs end to end.
    Log Environment Info
    Should Be Equal    ${1 + 1}    ${2}
