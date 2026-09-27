"""
File that contains logic for retrieving and storing media information in our Pinecone vector database.
"""

import os
from pinecone import Pinecone
from dotenv import load_dotenv
import standardmedia
from fastapi import FastAPI

app = FastAPI()
# -----------------------------------------------------------------------------------
# media information
# -----------------------------------------------------------------------------------
(
    title_key,
    description_key,
    overall_rating_key,
    id_key,
    image_key,
    api_review_count_key,
    genres_key,
    release_date_key,
    creator_key,
    media_length_key,
    season_count_key,
) = standardmedia.getStandardMediaKeys()
book_id_identifier, movie_id_identifier, tv_id_identifier = (
    standardmedia.getStandardMediaIdentifiers()
)
media_invalid_str_key, media_invalid_int_key = standardmedia.getInvalidMediaValues()

load_dotenv()  # loads the .env environment
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = "index1"
PINECONE_INDEX_MODEL_NAME = "llama-text-embed-v2"

PINECONE_BOOK_NAMESPACE = book_id_identifier
PINECONE_MOVIE_NAMESPACE = movie_id_identifier
PINECONE_TV_NAMESPACE = tv_id_identifier

pinecone_connection = Pinecone(PINECONE_API_KEY)

PINECONE_INDEX = pinecone_connection.Index(PINECONE_INDEX_NAME)

# PINECONE_INDEX_MODEL = pinecone_connection.Index(PINECONE_INDEX_MODEL_NAME)


# -----------------------------------------------------------------------------------
# cache and lock logic
# -----------------------------------------------------------------------------------
from collections import defaultdict
import asyncio
from cachetools import LRUCache

GET_VECTOR_FROM_PINECONE_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the getMediaFromPineconeUsingID cache, using a defaultdict to create a new lock for each unique key
GET_VECTOR_FROM_PINECONE_LRU = LRUCache(
    maxsize=1000
)  # LRU cache for getMediaFromPineconeUsingID results, with a max size of 1000 items

GET_VECTOR_FROM_TEXT_LOCK = defaultdict(
    asyncio.Lock
)  # Lock for synchronizing access to the getMediaFromPineconeUsingID cache, using a defaultdict to create a new lock for each unique key
GET_VECTOR_FROM_TEXT_LRU = LRUCache(
    maxsize=1000
)  # LRU cache for getMediaFromPineconeUsingID results, with a max size of 100
# -----------------------------------------------------------------------------------
# time check variables and function
# -----------------------------------------------------------------------------------
from datetime import datetime

STORE_MEDIA_TIME_CHECK = False  # time check variable for testing runtime of storeMediaInPinecone method, set to True to print start and end times
GET_MEDIA_TIME_CHECK = (
    False  # time check variable for testing runtime of getMediaFromPine
)


def logTimeCheck(message: str, time_check_variable: bool):
    if time_check_variable:
        print(
            f"---------------- {message}: time({datetime.now()}), pid({os.getpid()}) -------------------"
        )


async def getInfoForVectorization(media: dict) -> tuple:
    """
    Gets imformation for the text to embed and the metadata to store in the vector database from the given media.
    """

    metadata = media
    # adding genres
    genres_str = ", ".join(media[genres_key])

    text = f"{media[title_key]} -  {media[description_key]} - {genres_str}"

    return (text, metadata)


async def embedText(text: str, embed_type: str) -> list:
    """
    gets the embedding of the given text.
    """
    print('='*60)
    print('==================================================================================')
    print(f'EMBEDDING TEXT EMBEDDING TEXT EMBEDDING TEXT')
    print('==================================================================================')
    print('='*60)

    # vector = await cohere_logic.embed_text(text)
    embed_response = pinecone_connection.inference.embed(
        model="llama-text-embed-v2",
        inputs=[text],
        parameters={
            "input_type": embed_type,
            "truncate": "END",
        },
    )

    response_data = (
        embed_response.get("data", [])
        if isinstance(embed_response, dict)
        else getattr(embed_response, "data", [])
    )
    if response_data:
        first_embedding = response_data[0]
        if isinstance(first_embedding, dict):
            vector = first_embedding.get("values", [])
        else:
            vector = getattr(first_embedding, "values", [])

        return vector

    return []


async def getQueryVectorFromText(text: str) -> list:
    """
    gets the embedding of the given text, but first checks if the embedding is already stored in pinecone and returns that if it is.
    """

    vector = await embedText(text, embed_type="query")
    return vector


# TODO: come back and have check vector database? currently we can just use embedder so dont need
async def getPassageVectorFromText(media_id: str, text: str) -> list:
    """
    gets the embedding of the given text, but first checks if the embedding is already stored in pinecone and returns that if it is.
    """

    if media_id != media_invalid_str_key:
        result = PINECONE_INDEX.fetch(ids=[media_id], namespace=media_id[0])
        vector = (
            result["vectors"][media_id]["values"]
            if media_id in result["vectors"]
            else None
        )

    # # if result is stored in our vector database already
    # if result['vectors'] and media_id in result['vectors']:
    #     vector = result['vectors'][media_id]['values']
    #     return vector

    # else embed the text and return the embedding
    if not vector:
        vector = await embedText(text, embed_type="passage")
        if vector:
            return vector

    return []


async def getSimilarMediaUsingText(text: str, namespace: str, amount: int) -> list:
    """
    gets similar media to the given text of the given media type.

    returns a list of similar media to the given text of the given media type.
    """
    # vector = await embedText(text, embed_type=embed_type)
    vector = await getQueryVectorFromText(text)

    if not vector:
        return []

    query_params = {
        "vector": vector,
        "top_k": amount,
        "namespace": namespace,
        "include_metadata": True,
    }

    result = PINECONE_INDEX.query(**query_params)
    hits = [match.to_dict() for match in result["matches"]]

    return hits


async def getSimilarMediaUsingVector(
    vector: list, namespace: str, amount: int
) -> list:
    """
    gets similar media to the given vector of the given media type.

    returns a list of similar media to the given vector of the given media type.
    """
    # ensuring the vector is a list (not numpy array or other format) before sending to pinecone
    vector = vector.tolist()

    if not vector:
        return []

    query_params = {
        "vector": vector,
        "top_k": amount,
        "namespace": namespace,
        "include_metadata": True,
    }

    result = PINECONE_INDEX.query(**query_params)
    hits = [match.to_dict() for match in result["matches"]]

    return hits


async def getSimilarMediaUsingMedia(media: dict, namespace: str, amount: int) -> list:
    """
    gets similar media to the given media of the given media type.

    returns a list of similar media to the given media of the given media type.
    """

    text_for_embedding, metadata = await getInfoForVectorization(media=media)
    vector = await getQueryVectorFromText(text_for_embedding)

    if not vector:
        return []

    query_params = {
        "vector": vector,
        "top_k": amount,
        "namespace": namespace,
        "include_metadata": True,
    }

    result = PINECONE_INDEX.query(**query_params)
    hits = [match.to_dict() for match in result["matches"]]

    return hits


async def storeMedia(index, media: dict) -> dict:
    """
    stores the given media in pinecone.

    returns: {'status': 'success', 'message': 'success'} if successful and
     {'status': 'error', 'message': 'storeMediaInPinecone failed: '} if not successful
    """
    try:
        media_type = media[id_key][0]

        text_for_embedding, metadata = await getInfoForVectorization(media=media)

        vector = await embedText(text_for_embedding, embed_type="passage")

        index.upsert(
            vectors=[{"id": media[id_key], "values": vector, "metadata": metadata}],
            namespace=media_type,
        )
        return {"status": "success", "message": "success"}

    except Exception as e:
        print(f"============= FAILED IN storeMediaInPinecone media {media}:")
        print(f"{e} ==================== ")
        return {"status": "error", "message": f"storeMediaInPinecone failed: {e}"}


async def getMediaUsingIDSingle(media_id: str) -> list:
    """
    attempts to get the given media ids corresponding media and it's vectorization from pinecone.
    if successful the data is returned, if not an empty list is returned.
    """

    logTimeCheck("getMediaFromPineconeUsingID STARTING", GET_MEDIA_TIME_CHECK)

    result = PINECONE_INDEX.fetch(
        ids=[media_id],
        namespace=media_id[
            0
        ],  # use the first character of the id to determine the namespace
    )

    logTimeCheck("getMediaFromPineconeUsingID FINISHED", GET_MEDIA_TIME_CHECK)

    if media_id not in result["vectors"]:
        return []

    return [result["vectors"][media_id]]


# TODO improve so not double request?
async def getMediaUsingID(media: dict) -> list:
    """
    attempts to get the given media corresponding media and it's vectorization from pinecone.
    if the media is not stored in pinecone it is them vectorized and then stored within pinecone.
    if vectorization does not work then an empty list is returned.
    """

    pinecone_data = await getMediaUsingIDSingle(
        media_id=media[id_key]
    )

    if not pinecone_data:
        await storeMedia(index=PINECONE_INDEX, media=media)

    result = await getMediaUsingIDSingle(media_id=media[id_key])

    return result


async def getMediaUsingIDReplace(media: dict) -> list:
    """
    attempts to get the given media corresponding media and it's vectorization from pinecone.
    if the media is not stored in pinecone it is them vectorized and then stored within pinecone.
    if vectorization does not work then an empty list is returned.
    """

    pinecone_data = await getMediaUsingIDSingle(
        media_id=media[id_key]
    )

    if not pinecone_data:
        await storeMedia(index=PINECONE_INDEX, media=media)

    result = await getMediaUsingIDSingle(media_id=media[id_key])

    return result