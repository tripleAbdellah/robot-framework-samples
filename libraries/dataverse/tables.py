"""Table/schema metadata operations against the Dataverse Web API."""
from typing import Any

from ._data_api import DataApiClient

# Fields needed for the table-convention checks (naming, description, icon, ownership).
TABLE_CONVENTION_FIELDS = (
    "LogicalName,DisplayName,Description,IsCustomEntity,IsManaged,OwnershipType,"
    "IconVectorName,IconSmallName,IconMediumName,IconLargeName"
)


class TableClient(DataApiClient):
    """Table/schema metadata operations against the Dataverse Web API."""

    def get_table_logical_name(self, display_name: str) -> str:
        """Resolves a table's logical name from its display name (e.g. 'Klant' -> 'new_klant').

        EntityDefinitions doesn't support filtering on DisplayName server-side — confirmed
        against a real tenant, where filtering on it returns 400 "Conditions based on
        property DisplayName is not supported" ($top isn't supported there either). So
        this fetches every table and matches display names client-side instead.
        """
        entities: list[dict[str, Any]] = self._request(
            "GET", "EntityDefinitions?$select=LogicalName,DisplayName"
        ).json()["value"]

        def label_of(entity: dict[str, Any]) -> str | None:
            display = entity.get("DisplayName") or {}
            localized = display.get("UserLocalizedLabel") or {}
            return localized.get("Label")

        matches = [e for e in entities if label_of(e) == display_name]
        if not matches:
            raise ValueError(f"No table found with display name '{display_name}'")
        if len(matches) > 1:
            names = [m["LogicalName"] for m in matches]
            raise ValueError(f"Multiple tables found with display name '{display_name}': {names}")
        return matches[0]["LogicalName"]

    def list_custom_tables(self) -> list[dict[str, Any]]:
        """Fetches every table actually created by this org (for convention checks).

        IsCustomEntity=true alone isn't enough — confirmed live it also covers tables
        shipped by Microsoft's own optional modules (msdyn_*, skill matching, workflow
        internals, etc.), just because they weren't part of the base platform. The
        correct signal is IsCustomEntity=true AND IsManaged=false: unmanaged means it
        was created directly in this org, not installed via any managed solution
        (Microsoft's or otherwise). Filtered client-side, same reasoning as
        get_table_logical_name — EntityDefinitions filter support has already
        surprised us once (DisplayName isn't filterable).
        """
        entities: list[dict[str, Any]] = self._request(
            "GET", f"EntityDefinitions?$select={TABLE_CONVENTION_FIELDS}"
        ).json()["value"]
        return [e for e in entities if e.get("IsCustomEntity") and not e.get("IsManaged")]

    def list_main_forms(self, logical_name: str) -> list[dict[str, Any]]:
        """Fetches every active Main Form (type=2) for a table, including formxml so
        conventions.check_main_form_available_to_everyone can inspect role restrictions.

        Unlike EntityDefinitions, systemforms is a regular data entity — confirmed live
        that compound $filter (objecttypecode + type + formactivationstate) works
        normally here, no client-side filtering workaround needed.
        """
        path = (
            "systemforms?$select=name,type,formactivationstate,formxml"
            f"&$filter=objecttypecode eq '{logical_name}' and type eq 2 and formactivationstate eq 1"
        )
        return self._request("GET", path).json()["value"]

    def get_table_metadata(self, logical_name: str) -> dict[str, Any]:
        """Fetches entity (table) metadata: attributes, types, display names."""
        path = (
            f"EntityDefinitions(LogicalName='{logical_name}')"
            "?$expand=Attributes($select=LogicalName,AttributeType,DisplayName)"
        )
        return self._request("GET", path).json()
