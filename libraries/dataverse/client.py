"""Composition root for the Dataverse Web API client — see tables.py and records.py
for the actual operations, grouped by concern rather than flattened onto one class.
"""
from typing import Any

from ._data_api import DataApiClient
from ._requester import Requester
from .auth.base import AuthProvider
from .records import RecordClient
from .tables import TableClient


class DataverseClient(DataApiClient):
    """Thin facade: composes TableClient (schema/metadata) and RecordClient (CRUD),
    plus who_am_i directly (a single connectivity check that doesn't belong to
    either — inherited DataApiClient._request covers it, same as its sub-clients).

    Auth-agnostic by design: takes any object exposing get_auth_headers() (see
    dataverse.auth). Swapping auth strategies never touches this class or its
    sub-clients — only Requester ever sees the auth provider.
    """

    def __init__(self, environment_url: str, auth_provider: AuthProvider) -> None:
        requester = Requester(environment_url, auth_provider)
        super().__init__(requester)
        self.tables = TableClient(requester)
        self.records = RecordClient(requester)

    def who_am_i(self) -> dict[str, Any]:
        """Calls the Dataverse WhoAmI endpoint — the simplest possible connectivity/auth
        smoke test. Returns UserId, BusinessUnitId, OrganizationId."""
        return self._request("GET", "WhoAmI").json()
