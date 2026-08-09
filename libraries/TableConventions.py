"""Robot Framework library wrapping dataverse.conventions.

No auth, no network — pure rule evaluation over table metadata already fetched
by either transport (Python client or in-page fetch). Always available
regardless of ${AUTH_MODE}, unlike DataverseLibrary.
"""
from typing import Any

from robot.api import logger
from robot.api.deco import keyword, library

from dataverse.conventions import check_all, check_main_form_available_to_everyone


@library(scope="GLOBAL")
class TableConventions:

    @keyword
    def check_table_conventions(
        self,
        entity: dict[str, Any],
        prefix: str,
        expected_ownership: str | None = None,
    ) -> list[dict[str, Any]]:
        """Runs naming/description/icon/ownership rules against one table's metadata.

        Returns a list of violation dicts (rule, logical_name, message) — empty if
        the table is fully compliant.
        """
        violations = check_all(entity, prefix=prefix, expected_ownership=expected_ownership)
        return [vars(v) for v in violations]

    @keyword
    def check_main_form_conventions(
        self, main_forms: list[dict[str, Any]], logical_name: str
    ) -> list[dict[str, Any]]:
        """Runs the main-form-availability rule against a table's active Main Forms.

        Returns a list of violation dicts — empty if none are role-restricted.
        """
        logger.console(f"Checking main form conventions for table '{logical_name}' with {len(main_forms)} active main forms")
        violation = check_main_form_available_to_everyone(main_forms, logical_name)
        return [vars(violation)] if violation else []
