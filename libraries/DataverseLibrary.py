"""Robot Framework library wrapping the Dataverse Web API via service_principal
(Azure AD client-credentials, MSAL) — the only auth strategy this Python library
implements. Under auth_mode=browser, none of these keywords are used at all; that
mode runs entirely inside the browser page instead, via
resources/api/dataverse_browser_client.resource — see resources/api/dataverse_keywords.resource
for the ${AUTH_MODE} dispatch between the two.

The constructor takes no auth arguments on purpose. It's called unconditionally at
Library-import time regardless of ${AUTH_MODE} (Robot can't make a Library import
conditional), so it must never do anything that could fail under browser mode.
Call `Initialize Service Principal` explicitly instead — from Setup For Auth Mode in
authentication_keywords.resource, only when ${AUTH_MODE} != browser — to actually
build a working client. That's also where MSAL's tenant validation happens (a real,
live network call) — still at Suite Setup time, so it still fails fast before any
test case runs, just no longer forced onto suites that never asked for it.
"""
from typing import Any

from robot.api.deco import keyword, library

from dataverse.auth.service_principal import ServicePrincipalTokenProvider
from dataverse.client import DataverseClient


@library(scope="SUITE")
class DataverseLibrary:

    def __init__(self, environment_url: str = "") -> None:
        self._environment_url = environment_url
        self._client: DataverseClient | None = None

    def _require_client(self) -> DataverseClient:
        if self._client is None:
            raise RuntimeError(
                "DataverseLibrary keywords aren't usable yet — call 'Initialize Service "
                "Principal' first (only relevant under auth_mode=service_principal; "
                "browser mode uses resources/api/dataverse_browser_client.resource instead)."
            )
        return self._client

    @keyword
    def initialize_service_principal(self, client_id: str, client_secret: str, tenant_id: str) -> None:
        """Builds the real Dataverse client via Azure AD client-credentials (MSAL).
        Call this explicitly, never at import time — it validates the tenant against
        Azure AD immediately, a real network call."""
        required = {"client_id": client_id, "client_secret": client_secret, "tenant_id": tenant_id}
        missing = [name for name, value in required.items() if not value]
        if missing:
            raise ValueError(f"Initialize Service Principal requires: {', '.join(missing)}")
        auth_provider = ServicePrincipalTokenProvider(tenant_id, client_id, client_secret, self._environment_url)
        self._client = DataverseClient(self._environment_url, auth_provider)

    @keyword
    def who_am_i(self) -> dict[str, Any]:
        """Calls the Dataverse WhoAmI endpoint — the simplest possible connectivity/auth
        smoke test."""
        return self._require_client().who_am_i()

    @keyword
    def get_table_logical_name(self, display_name: str) -> str:
        """Resolves a table's logical name from its display name."""
        return self._require_client().tables.get_table_logical_name(display_name)

    @keyword
    def get_table_metadata(self, logical_name: str) -> dict[str, Any]:
        """Fetches table (entity) metadata: attributes, types, display names."""
        return self._require_client().tables.get_table_metadata(logical_name)

    @keyword
    def list_custom_tables(self) -> list[dict[str, Any]]:
        """Fetches every custom table's metadata, for convention checks."""
        return self._require_client().tables.list_custom_tables()

    @keyword
    def list_main_forms(self, logical_name: str) -> list[dict[str, Any]]:
        """Fetches every active Main Form for a table, for convention checks."""
        return self._require_client().tables.list_main_forms(logical_name)

    @keyword
    def create_record(self, entity_set: str, data: dict[str, Any]) -> str | None:
        """Creates a record in the given entity set. Returns its id."""
        return self._require_client().records.create_record(entity_set, data)

    @keyword
    def get_record(self, entity_set: str, record_id: str, select: str | None = None) -> dict[str, Any]:
        """Fetches a record by id, optionally limiting fields via select."""
        return self._require_client().records.get_record(entity_set, record_id, select=select)

    @keyword
    def delete_record(self, entity_set: str, record_id: str) -> None:
        """Deletes a record by id."""
        self._require_client().records.delete_record(entity_set, record_id)
