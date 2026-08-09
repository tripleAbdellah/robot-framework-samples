"""Everything specific to the Dataverse Web API family (api/data/v9.2/) — the path
prefix and the OData headers it needs. This is deliberately separate from Requester
(generic transport) so that a different API family sharing the same environment and
auth (e.g. Dataverse's Search API, api/search/v1.0/, if that's ever needed) could add
its own small client here without Requester, TableClient, or RecordClient changing at
all — only a new client alongside this one.
"""
from typing import Any

import requests

from ._requester import Requester

PREFIX = "api/data/v9.2/"


class DataApiClient:
    """Base for any client talking to the Dataverse Web API specifically. Owns the
    api/data/ prefix and OData headers so individual methods just call
    self._request(method, path) with paths relative to that prefix.
    """

    def __init__(self, requester: Requester) -> None:
        self._requester = requester

    def _request(self, method: str, path: str, **kwargs: Any) -> requests.Response:
        headers = {"OData-MaxVersion": "4.0", "OData-Version": "4.0"}
        headers.update(kwargs.pop("headers", {}))
        return self._requester.request(method, f"{PREFIX}{path}", headers=headers, **kwargs)
