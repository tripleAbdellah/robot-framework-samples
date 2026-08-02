import msal

from .base import AuthProvider


class ServicePrincipalTokenProvider(AuthProvider):
    """Acquires a bearer token via the Azure AD client-credentials flow (MSAL).

    MSAL caches the token internally and only calls out to Azure AD again once
    it's near expiry, so callers can just call get_auth_headers() before every
    request.
    """

    def __init__(self, tenant_id: str, client_id: str, client_secret: str, environment_url: str) -> None:
        self._app = msal.ConfidentialClientApplication(
            client_id,
            authority=f"https://login.microsoftonline.com/{tenant_id}",
            client_credential=client_secret,
        )
        self._scope: list[str] = [f"{environment_url.rstrip('/')}/.default"]

    def get_auth_headers(self) -> dict[str, str]:
        result: dict = self._app.acquire_token_for_client(scopes=self._scope)
        if "access_token" not in result:
            raise RuntimeError(
                f"Failed to acquire Dataverse token: {result.get('error')}: "
                f"{result.get('error_description')}"
            )
        return {"Authorization": f"Bearer {result['access_token']}"}
