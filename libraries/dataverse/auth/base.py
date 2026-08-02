from abc import ABC, abstractmethod


class AuthProvider(ABC):
    """Supplies whatever headers authenticate a Dataverse Web API call.

    DataverseClient only ever calls get_auth_headers() — it never knows or
    cares whether that's a bearer token (service principal) or session
    cookies (browser).
    """

    @abstractmethod
    def get_auth_headers(self) -> dict[str, str]:
        ...
