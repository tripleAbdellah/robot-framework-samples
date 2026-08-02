"""Robot Framework library wrapping the Dataverse Web API.

auth_mode=service_principal (Azure AD client-credentials via MSAL, requires client_id,
client_secret, tenant_id) is the only mode this Python library implements. Its keywords
are not meant to be called under auth_mode=browser — a plain cookie replay from an
external Python client returned 401 against a real tenant, meaning something beyond
cookies (most likely a Service Worker-injected token) authenticates the app's own calls.
Getting that "for free" requires executing the call *inside* the browser page itself, via
resources/api/dataverse_browser_transport.resource — see resources/api/dataverse_keywords.resource
for the auth_mode dispatch between the two.

auth_mode=browser still exists here as an accepted, inert import argument (rather than
raising) purely so the unconditional `Library ... auth_mode=${AUTH_MODE}` import in
dataverse_keywords.resource doesn't fail when ${AUTH_MODE} defaults to browser.
"""
from typing import Any

from robot.api.deco import keyword, library

from dataverse.auth.service_principal import ServicePrincipalTokenProvider
from dataverse.client import DataverseClient


@library(scope="SUITE")
class DataverseLibrary:

    def __init__(
        self,
        environment_url: str = "",
        auth_mode: str = "browser",
        client_id: str | None = None,
        client_secret: str | None = None,
        tenant_id: str | None = None,
    ) -> None:
        self._auth_mode = auth_mode
        self._client: DataverseClient | None = None
        if auth_mode == "service_principal":
            required = {"client_id": client_id, "client_secret": client_secret, "tenant_id": tenant_id}
            missing = [name for name, value in required.items() if not value]
            if missing:
                raise ValueError(f"auth_mode=service_principal requires: {', '.join(missing)}")
            auth_provider = ServicePrincipalTokenProvider(tenant_id, client_id, client_secret, environment_url)
            self._client = DataverseClient(environment_url, auth_provider)
        elif auth_mode != "browser":
            raise ValueError(f"Unknown auth_mode '{auth_mode}'. Use 'browser' or 'service_principal'.")

    def _require_client(self) -> DataverseClient:
        if self._client is None:
            raise RuntimeError(
                f"DataverseLibrary keywords aren't usable under auth_mode={self._auth_mode!r} — "
                "use the keywords in resources/api/dataverse_browser_transport.resource instead."
            )
        return self._client

    @keyword
    def get_table_logical_name(self, display_name: str) -> str:
        """Resolves a table's logical name from its display name."""
        return self._require_client().get_table_logical_name(display_name)

    @keyword
    def get_table_metadata(self, logical_name: str) -> dict[str, Any]:
        """Fetches table (entity) metadata: attributes, types, display names."""
        return self._require_client().get_table_metadata(logical_name)

    @keyword
    def list_custom_tables(self) -> list[dict[str, Any]]:
        """Fetches every custom table's metadata, for convention checks."""
        return self._require_client().list_custom_tables()

    @keyword
    def create_record(self, entity_set: str, data: dict[str, Any]) -> str | None:
        """Creates a record in the given entity set. Returns its id."""
        return self._require_client().create_record(entity_set, data)

    @keyword
    def get_record(self, entity_set: str, record_id: str, select: str | None = None) -> dict[str, Any]:
        """Fetches a record by id, optionally limiting fields via select."""
        return self._require_client().get_record(entity_set, record_id, select=select)

    @keyword
    def delete_record(self, entity_set: str, record_id: str) -> None:
        """Deletes a record by id."""
        self._require_client().delete_record(entity_set, record_id)
