"""Stateless governance/convention rules for Dataverse custom tables.

Each rule is a pure function: entity metadata dict -> Violation | None. No I/O,
no Robot Framework dependency — takes whatever EntityDefinitions already
returned, from either transport (Python client or in-page fetch).
"""
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from typing import Any


@dataclass
class Violation:
    rule: str
    logical_name: str
    message: str


def _label(entity: dict[str, Any], field: str) -> str | None:
    """Extracts a Label-typed property's text (Description, DisplayName, ...).

    Handles UserLocalizedLabel being present-but-null, not just missing —
    confirmed live on this same EntityDefinitions endpoint: some entities have
    DisplayName.UserLocalizedLabel as an explicit null, not an absent key.
    """
    obj = entity.get(field) or {}
    localized = obj.get("UserLocalizedLabel") or {}
    return localized.get("Label")


def check_naming_convention(entity: dict[str, Any], prefix: str) -> Violation | None:
    """Logical name must be '{prefix}_' followed by lowercase letters/digits/underscores."""
    logical_name = entity["LogicalName"]
    pattern = re.compile(rf"^{re.escape(prefix)}_[a-z][a-z0-9_]*$")
    if not pattern.match(logical_name):
        return Violation(
            rule="naming_convention",
            logical_name=logical_name,
            message=f"'{logical_name}' does not match required pattern '{prefix}_<lowercase>'",
        )
    return None


def check_has_description(entity: dict[str, Any]) -> Violation | None:
    logical_name = entity["LogicalName"]
    if not _label(entity, "Description"):
        return Violation(
            rule="has_description",
            logical_name=logical_name,
            message=f"'{logical_name}' has no description",
        )
    return None


# Confirmed live: unconfigured custom tables have all four of these fields as null
# (not some non-null default), so "not null" is a meaningful "has a real icon" check —
# at least for the "no icon at all" case; a table with an icon hasn't been checked yet.
ICON_FIELDS = ("IconVectorName", "IconSmallName", "IconMediumName", "IconLargeName")


def check_has_icon(entity: dict[str, Any]) -> Violation | None:
    logical_name = entity["LogicalName"]
    if not any(entity.get(field) for field in ICON_FIELDS):
        return Violation(
            rule="has_icon",
            logical_name=logical_name,
            message=f"'{logical_name}' has no icon configured on any of {ICON_FIELDS}",
        )
    return None


def check_ownership_type(entity: dict[str, Any], expected: str) -> Violation | None:
    logical_name = entity["LogicalName"]
    actual = entity.get("OwnershipType")
    if actual != expected:
        return Violation(
            rule="ownership_type",
            logical_name=logical_name,
            message=f"'{logical_name}' has OwnershipType '{actual}', expected '{expected}'",
        )
    return None


def _form_has_role_restriction(form_xml: str) -> bool:
    """True if a form's XML restricts it to specific security roles.

    Confirmed live: this is NOT exposed as a queryable attribute or relationship on
    systemform at all (checked both — neither exists). It's embedded in the formxml
    blob itself: a restricted form has a <roles> element listing role GUIDs; an open
    form has no <roles> element. Only presence/child-count is checked here — the
    inner <role> element's own attribute names weren't verified, since no restricted
    form exists in this tenant to check against.
    """
    root = ET.fromstring(form_xml)
    roles_element = root.find(".//roles")
    return roles_element is not None and len(roles_element) > 0


def check_main_form_available_to_everyone(
    main_forms: list[dict[str, Any]], logical_name: str
) -> Violation | None:
    """Every active Main Form must have no security-role restrictions.

    Flags ANY restricted active main form, not just "at least one open" — a table can
    have multiple main forms, and the concern here is accidentally locking some users
    out of the default view, so this defaults to the stricter reading. Adjust if "at
    least one open form is enough" better matches the actual policy.
    """
    restricted = [f for f in main_forms if _form_has_role_restriction(f["formxml"])]
    if restricted:
        names = [f["name"] for f in restricted]
        return Violation(
            rule="main_form_available_to_everyone",
            logical_name=logical_name,
            message=f"'{logical_name}' has main form(s) restricted to specific security roles: {names}",
        )
    return None


def check_all(
    entity: dict[str, Any],
    *,
    prefix: str,
    expected_ownership: str | None = None,
) -> list[Violation]:
    """Runs every rule against one table's metadata. expected_ownership is opt-in —
    whether one ownership type is correct for *every* custom table is a real open
    question (case-style tables may legitimately want UserOwned, reference tables
    OrganizationOwned), so this check is skipped unless a value is supplied.
    """
    violations = [
        check_naming_convention(entity, prefix),
        check_has_description(entity),
        check_has_icon(entity),
    ]
    if expected_ownership is not None:
        violations.append(check_ownership_type(entity, expected_ownership))
    return [v for v in violations if v is not None]
