import httpx

httpx_timeout = httpx.Timeout(
    connect=10.0,
    read=10.0,
    write=5.0,
    pool=5.0,
)

httpx_controller_client = httpx.AsyncClient(
    timeout=httpx_timeout,  # Timmeout to ignore request
)

httpx_rec_client = httpx.AsyncClient(
    timeout=httpx_timeout,  # Timmeout to ignore request
)

httpx_annual_recap_client = httpx.AsyncClient(
    timeout=httpx_timeout,
)


async def sendAsyncHttpRequestPost(client: httpx.AsyncClient, url: str, json: dict):
    """
    Sends async httpx request to the given url (assuming post) with the given json body and returns the response
    """
    reponse = await client.post(url, json=json)
    reponse.raise_for_status()
    return reponse.json()


async def sendAsyncHttpRequestGet(
    client: httpx.AsyncClient, url: str, params: dict, headers: dict = None
):
    """
    Sends async httpx request to the given url (assuming get) with the given params and returns the response
    """
    if headers:
        reponse = await client.get(url, params=params, headers=headers)
    else:
        reponse = await client.get(url, params=params)

    reponse.raise_for_status()
    return reponse.json()
