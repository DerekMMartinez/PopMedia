from fastapi import FastAPI
import standardmedia
import numpy as np
import mergelists
import asyncio


# --------------------------------------------------------------------------------
# Our server information
# --------------------------------------------------------------------------------
CONTROLLER_PORT = "8000"
OUR_SERVER_API_URL = "http://localhost"

# -----------------------------------------------------------------------------------
# Media information
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

(
    review_uid_key,
    review_username_key,
    review_media_id_key,
    review_rating_key,
    review_text_key,
    review_visibility_key,
    review_finished_on_key,
    review_spoiler_key,
) = standardmedia.getStandardReviewKeys()

book_id_identifier, movie_id_identifier, tv_id_identifier = (
    standardmedia.getStandardMediaIdentifiers()
)
media_invalid_str_key, media_invalid_int_key = standardmedia.getInvalidMediaValues()

# --------------------------------------------------------------------------------
# time check variables and function
# --------------------------------------------------------------------------------
import os
from datetime import datetime

WEIGH_SIMILAR_TIME_CHECK = False  # time check variable for testing runtime of recommendation weight information methods, set to True to print start and end times
USER_AVERAGE_INFO_TIME_CHECK = True  # time check variable for testing runtime of getUserAverageInfo method, set to True to print start and end times
COLLECT_SIMILAR_MEDIA_TIME_CHECK = False  # time check variable for testing runtime of
REC_MEDIA_TIME_CHECK = False  # time check variable for testing runtime of getRecForMedia method, set to True to print start and end times
REC_USER_TIME_CHECK = False  # time check variable for testing runtime of getRecForUser method, set to True to print start and end times


PRESERVE_TOKENS = True # variable for whether to preserve tokens in the text for embedding (since we have limited embedding tokens on the free plan.)

import pinecone_logic
import pinecone_logic_pt

PINECONE_INSTANCE = pinecone_logic


if PRESERVE_TOKENS:
    PINECONE_INSTANCE = pinecone_logic_pt

def logTimeCheck(message: str, time_check_variable: bool):
    if time_check_variable:
        print(
            f"---------------- {message}: time({datetime.now()}), pid({os.getpid()}) -------------------"
        )


# --------------------------------------------------------------------------------
# httpx information
# --------------------------------------------------------------------------------
from httpx_logic import (
    httpx_rec_client,
    sendAsyncHttpRequestPost,
    sendAsyncHttpRequestGet,
)


# --------------------------------------------------------------------------------
# recommendation weight information
# --------------------------------------------------------------------------------

COSINE_WEIGTHT = 1
RECENT_WEIGHT = 0.6
ALL_TIME_WEIGHT = 0.4
SIMILAR_USER_WEIGHT = 0.2  # TODO: we don't have logic for friends also liked yet, so this weight is not used currently
GENRE_SIMILARITY_WEIGHT = 0.2

POPULARITY_WEIGHT = 0.2

RATING_BOUND = 3
RATING_LIKED_BOUND = 2.5

VEC_SIZE = 1024

REC_AMOUNT = 30

app = FastAPI()







# TODO: IN THE FUTURE INCLUDE ANGEL SIMILARITY TO DISLIKES?
async def weighSimilarMediaScores(query: dict) -> list:
    """
    Weighs the similar media scores based on various factors

    query is of form:
    {
        'similar_media_pinecone': list (list of media items similar to the user's liked media from pinecone),
        'genres_liked': set of str (set of all genres the user liked)
    }

    returns a list of tuple of form:
        - (media items, weighed scores)
    """

    logTimeCheck("weighSimilarMediaScores START", WEIGH_SIMILAR_TIME_CHECK)
    similar_media_pinecone = query["similar_media_pinecone"]
    user_genres_liked = set(query["genres_liked"])
    similar_media_weighted = []

    for media_pinecone_item in similar_media_pinecone:
        media_pinecone_item[id_key] = media_pinecone_item[
            "id"
        ]  # TODO: this should be fixed in the future, pinecone should return the id with the key 'id' not 'media_id' or whatever we decide it should be, but for now just add the id to the media_pinecone_item with the correct key so we can use the getMediaUsingID function
        media_item = await getMediaFromPineconeInfo(media_pinecone_item)

        media_item = media_item

        media_genres = media_item[genres_key]

        original_score = media_pinecone_item["score"]
        final_score = original_score
        genre_bonus = 0

        # calculate genre similarity bonus
        media_genres = set(media_item[genres_key])
        common_genres = user_genres_liked.intersection(media_genres)

        if common_genres:
            genre_bonus = (
                len(common_genres) / len(media_genres)
            ) * GENRE_SIMILARITY_WEIGHT

        # calculate final weighed score
        genre_weighed_score = (
            COSINE_WEIGTHT * original_score * (1 - GENRE_SIMILARITY_WEIGHT)
        ) + genre_bonus

        # normalizing the rating to be between 0 and 1
        normalized_rating = media_item[overall_rating_key] / 5.0

        star_weighed_score = (
            COSINE_WEIGTHT * original_score * (1 - POPULARITY_WEIGHT)
        ) + (normalized_rating * POPULARITY_WEIGHT)

        final_score = (genre_weighed_score + star_weighed_score) / 2

        similar_media_weighted.append((media_item, final_score))

    logTimeCheck("weighSimilarMediaScores END", WEIGH_SIMILAR_TIME_CHECK)
    return similar_media_weighted





from sklearn.cluster import KMeans


async def getUserReviews(uid: str) -> tuple:
    """
    Collects the users reviews and seperates them into 2 lists, one for liked media and one for disliked media.

    Return tuple of form:
    {
    'liked': list of tuples of form (review, media) for media the user liked
    'disliked': list of tuples of form (review, media) for media the user disliked
    }
    """
    user_review_media = await sendAsyncHttpRequestGet(
        httpx_rec_client,
        f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getUserMediaReviews",
        params={"request_uid": uid, "target_uid": uid, "type": "a"},
    )

    liked = []
    disliked = []

    for review_media in user_review_media:
        review = review_media[0]
        media = review_media[1]
        user_review_rating = review[review_rating_key]

        if user_review_rating < RATING_BOUND:
            disliked.append((review, media))
        else:
            liked.append((review, media))

    return (liked, disliked)













# =================================================================================
# new code
# =================================================================================

# =================================================================================
# Pinecone information cleaning functions
# =================================================================================

async def getShiftedAmount(amount: int, ignored_media: list):
    """
    Shifts the amount of media being requested to account for the media being ignored (such as reviewed, the current media etc)
    """
    amount += len(ignored_media)
    return amount

async def cleanResults(ignore_media: list, recommended_media: list) -> list:
    """
    Removes any media from the recommended media list that is in the ignore media list and returns the cleaned recommended media list.
    """
    ignored_ids = set([media[id_key] for media in ignore_media])
    results = []
    for media in recommended_media:
        if media[id_key] not in ignored_ids:
            results.append(media)
    
    return results

async def getMediaFromPineconeInfo(media_pinecone_item: dict) -> dict:
    """
    cleans the media information retrieved from pinecone and returns a media item of our standard form
    returns a media item of our standard form
    """

    media_item = (
        media_pinecone_item["metadata"] if "metadata" in media_pinecone_item else []
    )

    return media_item


async def cleanPineconeResults(pinecone_results: list) -> list:
    """
    Cleans the results from Pinecone by converting each item to a media object.
    """
    cleaned_results = []
    tasks = [
        getMediaFromPineconeInfo(media_pinecone_item) for media_pinecone_item in pinecone_results
    ]
    cleaned_results = await asyncio.gather(*tasks)
    return cleaned_results


async def getSimilarMediaUsingVector(vector: list, media_type: str, amount: int) -> list:
    """
    gets similar/recommended media for a given vector.
    """
    similar_media_pinecone = await PINECONE_INSTANCE.getSimilarMediaUsingVector(
        vector=vector, 
        namespace=media_type, 
        amount=amount
    )

    similar_media = await  cleanPineconeResults(similar_media_pinecone)

    return similar_media


async def getSimilarMediaUsingText(text: str, media_type: str, amount: int) -> list:
    """
    gets similar/recommended media for a given text string.
    """
    similar_media_pinecone = await PINECONE_INSTANCE.getSimilarMediaUsingText(
        text=text, 
        namespace=media_type, 
        amount=amount
    )

    similar_media = await cleanPineconeResults(similar_media_pinecone)

    return similar_media


async def getSimilarMediaUsingMedia(media: dict, media_type: str, amount: int) -> list:
    """
    gets similar/recommended media for a given media item.
    """

    similar_media_pinecone = await PINECONE_INSTANCE.getSimilarMediaUsingMedia(
        media=media, 
        namespace=media_type, 
        amount=amount
    )

    similar_media = await cleanPineconeResults(similar_media_pinecone)

    return similar_media


async def getMediaUsingID(media_id: str) -> dict:
    """
    gets an entire media item using the media id by requesting the media from our server.
    """
    media_item = await sendAsyncHttpRequestPost(
        httpx_rec_client,
        f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getMediaUsingIdSearch",
        json={"mode": "id_search", id_key: media_id, "type": media_id[0]},
    )

    media_item = media_item[0]

    return media_item   


async def getSimilarMedia(query_value: object, media_type: str, amount: int, getSimilarMediaFunc: callable) -> list:
    """
    gets similar/recommended media for the given query value (which can be a text string, a media item, or a vector) and media type by using the given getSimilarMediaFunc function to get similar media for each media type and then merging the results into a single list of recommendations sorted by similarity score in descending order and returning the top amount recommendations
    """
    result = {book_id_identifier: [], movie_id_identifier: [], tv_id_identifier: []}
    media_types = standardmedia.getMediaTypeList(media_type)
    

    task_per_type = {}

    for curr_media_type in media_types:
        task_per_type[curr_media_type] = getSimilarMediaFunc(query_value, curr_media_type, amount)

    similar_media_lists = await asyncio.gather(*[task_per_type[curr_media_type] for curr_media_type in media_types])

    result = await mergelists.mergeKLists(similar_media_lists)

    return result[:amount]


async def getVectorForMedia(media: dict) -> list:
    """
    gets the vector information for the given media
    """
    media_vector_info = await PINECONE_INSTANCE.getMediaUsingIDReplace(media)

    media_vector_info = media_vector_info[0]

    media_vector = media_vector_info["values"]

    return media_vector

async def getVectorsForMediaList(media_list: list) -> list:
    """
    gets a list of vectors for a list of media items by making concurrent requests to get the vector information for each media item in the list using asyncio.gather
    """
    tasks = [getVectorForMedia(media) for media in media_list]

    vectors = await asyncio.gather(*tasks)

    return vectors

# =================================================================================
# K clusters functions
# =================================================================================

async def makeClusters(vectors: list, cluster_amount: int) -> list:
    """
    makes clusters of the given vectors using k-means clustering and returns a list of clusters, where each cluster is a list of vectors that belong to that cluster
    """
    cluster_amount = min(cluster_amount, len(vectors))

    if cluster_amount == 0:
        return []

    vectors = [np.array(v) for v in vectors]

    kmean_clusters = KMeans(n_clusters=cluster_amount, random_state=0)
    labels = kmean_clusters.fit_predict(vectors)
    
    clusters = [
        [vectors[i] for i in range(len(vectors)) if labels[i] == j]
        for j in range(cluster_amount)
    ]

    
   
    return clusters

async def getMeanVectorsForClusters(clusters: list) -> list:
    """
    returns a list of the average vectors for each cluster, the average vector is calculated by taking the mean of all the vectors in the cluster
    """
    average_in_buckets = [np.mean(cluster, axis=0) for cluster in clusters]

    return average_in_buckets




async def getRecForUnclusteredVectors(vectors: list, media_type: str, amount: int) -> list:
    """
    Gets recommendations for a list of vectors by using clustering.
    """
    clusters = await makeClusters(vectors, cluster_amount=5)
    average_vectors = await getMeanVectorsForClusters(clusters)

    vectors_tasks = [
        getSimilarMedia(average_vector, media_type=media_type, amount=amount, getSimilarMediaFunc=getSimilarMediaUsingVector)
        for average_vector in average_vectors
    ]

    vectors_results = await asyncio.gather(*vectors_tasks)

    merged_results = await mergelists.mergeKLists(vectors_results)
    
    return merged_results[:amount]


# =================================================================================
# recommendation functions
# =================================================================================


@app.get('/getRecForVibeSearch')
async def getRecForVibeSearch(text: str, media_type: str, amount: int = REC_AMOUNT) -> list:
    """
    Gets recommendations for a vibe search
    """
    result = await getSimilarMedia(text, media_type, amount, getSimilarMediaUsingText)
    # cleaned_results = await cleanResults(ignore_media=[], recommended_media=result)
    return result


@app.get('/getRecForMedia')
async def getRecForMedia(media_id: str, media_type: str, amount: int = REC_AMOUNT) -> list:
    """
    Gets recommendations similar to the given media item
    """
    

    media = await getMediaUsingID(media_id=media_id)
    shifted_amount = await getShiftedAmount(amount=amount, ignored_media=[media])

    result = await getSimilarMedia(media, media_type, shifted_amount, getSimilarMediaUsingMedia)

    cleaned_results = await cleanResults(ignore_media=[media], recommended_media=result)
    return cleaned_results


@app.get('/getRecForUser')  
async def getRecForUser(uid: str, media_type: str, amount: int = REC_AMOUNT) -> list:
    """
    Gets recommendations for the given user
    """
    # collecting user reviews and media
    user_reviews_liked, user_reviews_disliked = await getUserReviews(uid)
    reviewed_media = [review_media[1] for review_media in user_reviews_liked]
    
    # TODO: currently just accounting for media the user liked in the recommendations, we should probably account for both. 
    # I also want to use the dislikes to additionally eliminate media from being suggested. But that is a larger problem for later
    shifted_amount = await getShiftedAmount(amount=amount, ignored_media=user_reviews_liked)

    # collecting vectors for the reviewed media
    liked_review_vectors = await getVectorsForMediaList(reviewed_media)
    
    # getting recommendations for the liked media vectors using clusters
    result = await getRecForUnclusteredVectors(liked_review_vectors, media_type, shifted_amount)

    cleaned_results = await cleanResults(ignore_media=reviewed_media, recommended_media=result)

    return cleaned_results[:amount]


# =================================================================================
# playlist recommendation functions
# =================================================================================


async def getPlaylistMedia(pid: str):
    platlist = await sendAsyncHttpRequestGet(httpx_rec_client,
                                        f"{OUR_SERVER_API_URL}:{CONTROLLER_PORT}/getPlaylistMedia",
                                        params={"pid": pid,
                                                'media_type': 'a'})
    
    return platlist


@app.get('/getRecForPlayList')
async def getRecForPlayList(pid: str, media_type: str, amount: int = REC_AMOUNT):
    """
    Gets recommendations for the given playlist id.
    """
    playlist_media_list = await getPlaylistMedia(pid)

    vectors = await getVectorsForMediaList(playlist_media_list)
    result = await getRecForUnclusteredVectors(vectors, media_type, amount=amount)

    cleaned_results = await cleanResults(ignore_media=playlist_media_list, recommended_media=result)

    return cleaned_results[:amount]




