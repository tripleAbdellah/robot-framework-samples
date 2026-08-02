*** Settings ***
Documentation    The Dynamics 365 notification bar shown after form actions
...              (e.g. save confirmations, validation errors).
Library          Browser

*** Variables ***
${NOTIFICATION_BAR}    css=[data-id="notificationWrapper"]

*** Keywords ***
Lees Notificatie
    [Documentation]    Reads the current notification bar message, if any.
    ${message}=    Get Text    ${NOTIFICATION_BAR}
    RETURN    ${message}
