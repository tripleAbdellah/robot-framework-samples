"""Record CRUD operations against the Dataverse Web API."""
import re
from typing import Any

from ._data_api import DataApiClient

ENTITY_ID_PATTERN = re.compile(r"\(([0-9a-fA-F-]{36})\)")


class RecordClient(DataApiClient):
    """Record CRUD operations against the Dataverse Web API."""

    def create_record(self, entity_set: str, data: dict[str, Any]) -> str | None:
        """Creates a record in the given entity set. Returns its id (GUID string)."""
        response = self._request(
            "POST", entity_set, headers={"Content-Type": "application/json"}, json=data
        )
        entity_id_header = response.headers.get("OData-EntityId", "")
        match = ENTITY_ID_PATTERN.search(entity_id_header)
        return match.group(1) if match else None

    def get_record(self, entity_set: str, record_id: str, select: str | None = None) -> dict[str, Any]:
        """Fetches a record by id, optionally limiting fields via $select."""
        path = f"{entity_set}({record_id})"
        params = {"$select": select} if select else None
        return self._request("GET", path, params=params).json()

    def delete_record(self, entity_set: str, record_id: str) -> None:
        """Deletes a record by id."""
        self._request("DELETE", f"{entity_set}({record_id})")
