*** Settings ***
Documentation    Governance/convention checks for custom Dataverse tables — naming pattern,
...              description presence, icon presence, ownership type, and main form
...              availability. Stateless: no baseline/snapshot needed, applies uniformly
...              to every custom table.
Library          Collections
Library          ../../libraries/TableConventions.py
Resource         dataverse_keywords.resource

*** Variables ***
# TODO: confirm the org's actual registered publisher prefix. 'new_' (Dataverse's
# default/unmanaged prefix) is NOT it — a real custom prefix should have been
# registered via a Solution Publisher. Until confirmed, this is a placeholder.
${TABLE_PREFIX}         uwv
# Opt-in: whether every custom table should share one OwnershipType. Leave ${EMPTY}
# to skip this check entirely — see table_conventions.resource docs for why this
# isn't necessarily a single correct value across all tables.
${EXPECTED_OWNERSHIP}    ${EMPTY}

*** Keywords ***
Get Table Convention Violations
    [Documentation]    Fetches every custom table and runs naming/description/icon/
    ...                ownership/main-form-availability checks against each. Returns a
    ...                flat list of violation dicts (rule, logical_name, message) across
    ...                all tables.
    ${tables}=    Get Custom Tables
    ${ownership}=    Set Variable If    "${EXPECTED_OWNERSHIP}" != ""    ${EXPECTED_OWNERSHIP}    ${None}
    ${all_violations}=    Create List
    FOR    ${table}    IN    @{tables}
        ${table_violations}=    Check Table Conventions    ${table}    ${TABLE_PREFIX}    ${ownership}
        Append To List    ${all_violations}    @{table_violations}
        ${main_forms}=    Get Main Forms    ${table}[LogicalName]
        ${form_violations}=    Check Main Form Conventions    ${main_forms}    ${table}[LogicalName]
        Append To List    ${all_violations}    @{form_violations}
    END
    RETURN    ${all_violations}
