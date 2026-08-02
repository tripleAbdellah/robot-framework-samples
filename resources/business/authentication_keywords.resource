*** Settings ***
Documentation    Business-level login/session keywords. Hides page objects and auth mechanics
...              from test cases.
Library          Browser
Library          OperatingSystem
Resource         ../pages/login_page.resource
Resource         ../api/dataverse_keywords.resource

*** Variables ***
# Saved browser session (cookies + local storage) lives outside results/ so it survives
# between separate `robot` invocations — Browser library's own Save Storage State output
# is auto-deleted at the start of every run. Never commit this file: it holds live session
# tokens, equivalent to a password.
${STORAGE_STATE_DIR}     ${CURDIR}/../../.auth
${STORAGE_STATE_PATH}    ${STORAGE_STATE_DIR}/dataverse_storage_state.json

*** Keywords ***
Login Als Behandelaar
    [Documentation]    Logs in as a caseworker ("behandelaar") user via the login form.
    ...                Credentials default to the DATAVERSE_USERNAME / DATAVERSE_PASSWORD
    ...                environment variables so they never need to be hardcoded or
    ...                committed to the repo.
    [Arguments]    ${username}=%{DATAVERSE_USERNAME=${EMPTY}}    ${password}=%{DATAVERSE_PASSWORD=${EMPTY}}
    Open Login Page
    Log In    ${username}    ${password}

Zorg Voor Ingelogde Sessie En Dataverse Toegang
    [Documentation]    Suite Setup entry point. Reuses a saved, already-MFA'd browser
    ...                session when one exists, so headless runs never hit the
    ...                Authenticator prompt. The very first run (or once the session
    ...                expires) has no saved session yet, so it opens a *visible*
    ...                browser and waits for you to approve MFA once — after that,
    ...                the session is saved and every later run reuses it headlessly.
    ...                Leaves an authenticated page open — under auth_mode=browser, later
    ...                Dataverse calls run as fetch() inside that same page (see
    ...                resources/api/dataverse_browser_transport.resource), so nothing
    ...                further needs to be captured or handed off here.
    ${session_exists}=    Run Keyword And Return Status    File Should Exist    ${STORAGE_STATE_PATH}
    IF    ${session_exists}
        New Browser    headless=True
        New Context    storageState=${STORAGE_STATE_PATH}
        New Page    ${LOGIN_URL}
    ELSE
        Log    No saved session at ${STORAGE_STATE_PATH} — opening a visible browser so you can approve the Authenticator prompt once. Later runs will reuse this session and skip login/MFA entirely.    level=WARN
        New Browser    headless=False
        New Context
        Login Als Behandelaar
        ${state_file}=    Save Storage State
        Create Directory    ${STORAGE_STATE_DIR}
        Copy File    ${state_file}    ${STORAGE_STATE_PATH}
        Log    Session saved to ${STORAGE_STATE_PATH} for future headless runs.    level=WARN
    END
