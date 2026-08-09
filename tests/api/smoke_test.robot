*** Settings ***
Documentation    Fast connectivity/auth smoke test — confirms Dataverse is reachable and
...              authentication works, before running heavier suites. Same Who Am I
...              keyword regardless of ${AUTH_MODE}.
Resource         ../../resources/business/authentication_keywords.resource
Suite Setup      Setup For Auth Mode
Suite Teardown   Teardown For Auth Mode

*** Test Cases ***
Dataverse Connection Is Healthy
    [Documentation]    Calls WhoAmI and confirms a valid user/org identity comes back —
    ...                the minimal-privilege, minimal-cost way to prove auth + connectivity
    ...                both work before trusting the result of anything heavier.
    ${who}=    Who Am I
    Should Not Be Empty    ${who}[UserId]
    Should Not Be Empty    ${who}[BusinessUnitId]
    Should Not Be Empty    ${who}[OrganizationId]
    Log    Connected as UserId=${who}[UserId] in OrganizationId=${who}[OrganizationId]    level=WARN
