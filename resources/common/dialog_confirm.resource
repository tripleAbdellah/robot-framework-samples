*** Settings ***
Documentation       Reusable keywords for the standard UCI modal confirm dialog
...                 ("Bevestigen" / OK / Annuleren).
...
...                 This dialog belongs to the platform shell, not to a single page.
...                 It appears on save, delete, deactivate, unsaved-changes, etc.
...                 Page objects should compose these keywords; tests should not
...                 need to know that a dialog exists.
...
...                 All locators use data-id attributes. The id suffix (_11) and the
...                 pa-* / fui-* classes are generated per build and must never be
...                 used in a locator.

Library             Collections
Library             OperatingSystem
Library             String
Library             Browser



*** Variables ***
${DLG_ROOT}                 div[id^="modalDialogContentContainer"]
${DLG_TITLE}                [data-id="dialogTitleText"]
${DLG_MESSAGE}              [data-id="dialogMessageText"]
${DLG_CONFIRM_BUTTON}       button[data-id="confirmButton"]
${DLG_CANCEL_BUTTON}        button[data-id="cancelButton"]
${DLG_CLOSE_BUTTON}         button[data-id="dialogCloseIconButton"]

${DLG_TIMEOUT}              10s


*** Keywords ***
Is Confirm Dialog Open
    [Documentation]    Returns ${True} when the confirm dialog is currently in the DOM.
    ...    Does not wait and does not fail. Use this for optional dialogs.
    ${count}=    Get Element Count    ${DLG_ROOT}
    RETURN    ${{ $count > 0 }}

Confirm Dialog Should Be Visible
    [Documentation]    Waits until the confirm dialog is rendered and visible.
    [Arguments]    ${timeout}=${DLG_TIMEOUT}
    Wait For Elements State    ${DLG_ROOT}    visible    timeout=${timeout}
    Wait For Elements State    ${DLG_CONFIRM_BUTTON}    enabled    timeout=${timeout}

Confirm Dialog Should Not Be Visible
    [Documentation]    Waits until the confirm dialog has disappeared.
    [Arguments]    ${timeout}=${DLG_TIMEOUT}
    Wait For Elements State    ${DLG_ROOT}    detached    timeout=${timeout}

Get Confirm Dialog Title
    [Documentation]    Returns the dialog heading, e.g. "Bevestigen".
    Confirm Dialog Should Be Visible
    ${title}=    Get Text    ${DLG_TITLE}
    ${title}=    Strip String    ${title}
    RETURN    ${title}

Get Confirm Dialog Message
    [Documentation]    Returns the body text of the dialog.
    ...    Assert on this at page or test level: the wording is business specific
    ...    and does not belong in this component.
    Confirm Dialog Should Be Visible
    ${message}=    Get Text    ${DLG_MESSAGE}
    ${message}=    Strip String    ${message}
    RETURN    ${message}

Confirm Dialog Message Should Contain
    [Documentation]    Verifies that the dialog body contains ${expected}.
    [Arguments]    ${expected}
    ${message}=    Get Confirm Dialog Message
    Should Contain    ${message}    ${expected}
    ...    msg=Confirm dialog message did not contain the expected text.
    ...    values=${True}

Confirm Dialog Confirm
    [Documentation]    Clicks OK. Optionally verifies the message first.
    ...
    ...    Example:
    ...    Confirm Dialog Confirm    expected_message=Wil je de klant opslaan
    [Arguments]    ${expected_message}=${EMPTY}
    Confirm Dialog Should Be Visible
    IF    $expected_message
        Confirm Dialog Message Should Contain    ${expected_message}
    END
    Click    ${DLG_CONFIRM_BUTTON}
    Confirm Dialog Should Not Be Visible

Confirm Dialog Cancel
    [Documentation]    Clicks Annuleren. Optionally verifies the message first.
    [Arguments]    ${expected_message}=${EMPTY}
    Confirm Dialog Should Be Visible
    IF    $expected_message
        Confirm Dialog Message Should Contain    ${expected_message}
    END
    Click    ${DLG_CANCEL_BUTTON}
    Confirm Dialog Should Not Be Visible

Confirm Dialog Close
    [Documentation]    Dismisses the dialog via the X icon in the header.
    ...    Functionally equal to cancel, but exercises a different control.
    Confirm Dialog Should Be Visible
    Click    ${DLG_CLOSE_BUTTON}
    Confirm Dialog Should Not Be Visible

Handle Confirm Dialog If Present
    [Documentation]    Confirms or cancels the dialog only when it happens to appear.
    ...    Use sparingly: prefer an explicit Confirm Dialog Confirm when the dialog
    ...    is part of the expected flow, so a missing dialog fails the test.
    [Arguments]    ${action}=confirm
    ${is_open}=    Is Confirm Dialog Open
    IF    not $is_open    RETURN
    IF    $action == 'confirm'
        Confirm Dialog Confirm
    ELSE IF    $action == 'cancel'
        Confirm Dialog Cancel
    ELSE
        Fail    Unsupported action '${action}'. Use 'confirm' or 'cancel'.
    END
