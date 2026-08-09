"""Internal HTTP plumbing, generic across every Dynamics/Dataverse API family — this
knows the environment root and how to attach auth, and nothing else. It has no idea
"api/data/" exists; that belongs to whichever domain client actually talks to that
API family (see _data_api.py) — a client for a *different* family (e.g. Dataverse's
Search API, api/search/v1.0/, if that's ever needed) would share this same Requester
without either client needing to know the other's URL shape.

Not part of the public API — nothing outside dataverse/ should depend on Requester.
The leading underscore on this module is a real signal, not decoration: reaching
`client._requester.request(...)` from outside is deliberately awkward to do by
accident, unlike a single underscore on a flat, do-everything client.
"""
from typing import Any

import requests

from .auth.base import AuthProvider


class Requester:
    """Owns the environment root, auth headers, and the actual HTTP call. Auth-agnostic
    by design: takes any object exposing get_auth_headers() (see dataverse.auth).
    """

    def __init__(self, environment_url: str, auth_provider: AuthProvider) -> None:
        self._base_url = f"{(environment_url or '').rstrip('/')}/"
        self._auth_provider = auth_provider

    def request(self, method: str, path: str, **kwargs: Any) -> requests.Response:
        """path is relative to the environment root, e.g. 'api/data/v9.2/WhoAmI' —
        callers own their full API-family path, this doesn't assume one. Same for
        headers: only auth is attached here — OData-MaxVersion/OData-Version etc.
        are a Dataverse Web API convention, not a generic HTTP one, so those belong
        to whichever domain client actually speaks that family (see _data_api.py)."""
        headers = {"Accept": "application/json"}
        headers.update(kwargs.pop("headers", {}))
        headers.update(self._auth_provider.get_auth_headers())
        response = requests.request(method, self._base_url + path, headers=headers, timeout=30, **kwargs)
        response.raise_for_status()
        return response
