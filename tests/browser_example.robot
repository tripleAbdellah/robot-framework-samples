*** Settings ***
Documentation    Example browser test using the Playwright-based Browser library.
Library          Browser
Suite Setup      New Browser    headless=True
Suite Teardown   Close Browser

*** Variables ***
${SAMPLE_PAGE}    ${CURDIR}/data/sample.html

*** Test Cases ***
Loads Sample Page
    [Documentation]    Confirms the Browser library can open a page and read its content.
    New Page    file://${SAMPLE_PAGE}
    Get Title    ==    Robot-App Sample Page
    Get Text    id=heading    ==    Hello, Robot Framework!
