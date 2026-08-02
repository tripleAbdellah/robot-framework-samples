"""Robot Framework library wrapping dataverse.conventions.

No auth, no network — pure rule evaluation over table metadata already fetched
by either transport (Python client or in-page fetch). Always available
regardless of ${AUTH_MODE}, unlike DataverseLibrary.
"""
from typing import Any

from robot.api.deco import keyword, library

from dataverse.conventions import check_all


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
