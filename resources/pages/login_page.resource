*** Settings ***
Documentation    Selectors and interactions for the login page. Centralizes locators
...              so business keywords never reference them directly.
Library          Browser

*** Variables ***
${LOGIN_URL}              ${EMPTY}    # TODO: set Dynamics 365 environment URL
${USERNAME_INPUT}         id=i0116
${PASSWORD_INPUT}         id=i0118
# Microsoft reuses this same button id for "Next", "Sign in" and the "Stay signed in?"
# prompt — that reuse is real Microsoft login behavior, not a mistake here.
${SUBMIT_BUTTON}          id=idSIButton9
${MFA_APPROVAL_TIMEOUT}   120s

*** Keywords ***
Open Login Page
    [Documentation]    Navigates to the login page.
    New Page    ${LOGIN_URL}

Log In
    [Documentation]    Fills in credentials, submits, then waits (generously — this is a
    ...                manual, out-of-band step on your phone) for Microsoft Authenticator
    ...                approval, and handles the optional "Stay signed in?" prompt if shown.
    ...                Selectors/flow are best-effort and unverified against a real tenant —
    ...                expect to adjust after a first real run.
    [Arguments]    ${username}    ${password}
    Fill Text    ${USERNAME_INPUT}    ${username}
    Click    ${SUBMIT_BUTTON}
    Fill Text    ${PASSWORD_INPUT}    ${password}
    Click    ${SUBMIT_BUTTON}
    ${stay_signed_in_shown}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${SUBMIT_BUTTON}    visible    timeout=${MFA_APPROVAL_TIMEOUT}
    IF    ${stay_signed_in_shown}
        Click    ${SUBMIT_BUTTON}
    END
