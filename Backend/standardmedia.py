"""
Discribes and Contains our standard format of a piece of media

Media is of form:
    - title: str (title of the media)
    - description: str (description of the media)
    - overall_rating: float (rating of the media)
    - id: str (unique identifier of structure:  b<isbn> for books, m<int> for movies, t<int> for tv shows)
    - image: str (url to image of the media)
    - api_review_count: int (number of reviews from the API)
    - genres: list (list of genres the media belongs to)
    - release_date: str (release date of the media)
    - creator: str (creator of the media - author for books, director for movies, creator for tv shows)

if any of the fields are missing from the original data, they will be filled with default values:
    - for string fields: 'N/A'
    - for int/float fields: -1.0
"""

# standard review keys
review_uid_key = "uid"
review_username_key = "username"
review_media_id_key = "media_id"
review_rating_key = "rating"
review_text_key = "review_text"
review_visibility_key = "review_visibility"
review_finished_on_key = "finished_on"
review_spoiler_key = "spoiler"


# Standard key value pairs
title_key = "title"
description_key = "description"
overall_rating_key = "overall_rating"
id_key = "media_id"
image_key = "image"
api_review_count_key = "api_review_count"
genres_key = "genres"
release_date_key = "release_date"
creator_key = "creator"
media_length_key = "media_length"
season_count_key = "season_count"

# review_count_key = 'review_count'   # TODO CURRENTLY NOT IN USE (since our data isn't set up to hold these yet (i dont think idk))

# standard identifiers
book_id_identifier = "b"
movie_id_identifier = "m"
tv_id_identifier = "t"


def getStandardEmptyMedia() -> dict:
    """
    returns an empty media dictionary with default values
    for string fields: 'N/A'
    overall_rating: -1.0,
    genres: []
    """
    return {
        title_key: "N/A",
        description_key: "N/A",
        id_key: "N/A",
        overall_rating_key: -1.0,
        image_key: "N/A",
        api_review_count_key: -1,
        genres_key: [],
        release_date_key: "N/A",
        creator_key: "N/A",
        media_length_key: -1.0,
        season_count_key: -1,
    }


def getStandardEmptyReview() -> dict:
    """
    returns an empty review dictionary with default values
    for string fields: 'N/A'
    overall_rating: -1.0
    spoiler: False
    """
    return {
        review_uid_key: "N/A",
        review_username_key: "N/A",
        review_media_id_key: "N/A",
        review_rating_key: -1.0,
        review_text_key: "N/A",
        review_visibility_key: "N/A",
        review_finished_on_key: "N/A",
        review_spoiler_key: False,
    }


def getStandardMediaKeys() -> tuple:
    """
    returns the standard media keys as a tuple in form:
            'title',
            'description',
            'overall_rating',
            'id',
            'image',
            'api_review_count',
            'genres',
            'release_date',
            'creator_key',
            'media_length',
            'season_count',
    """
    return (
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
    )


def getStandardReviewKeys() -> tuple:
    """
    returns the standard review keys as a tuple in form:
        review_uid_key,
        review_username_key,
        review_media_id_key,
        review_rating_key,
        review_text_key,
        review_visibility_key,
        review_finished_on_key,
        review_spoiler_key
    """
    return (
        review_uid_key,
        review_username_key,
        review_media_id_key,
        review_rating_key,
        review_text_key,
        review_visibility_key,
        review_finished_on_key,
        review_spoiler_key,
    )


def getStandardMediaIdentifiers() -> tuple:
    """
    Returns a tuple of the standard media identifiers (what will preceed the id in the media)

    tuple is of form:
    (book_id_identifier, movie_id_identifier, tv_id_identifier)
    """
    return (book_id_identifier, movie_id_identifier, tv_id_identifier)


def getInvalidMediaValues() -> tuple:
    """
    Returns a tuple of the standard media invalid values (both string and int)

    tuple is form of
    (invalid string value 'N/A',invalid int value '-1')
    """

    return ("N/A", -1)

def getMediaTypeList(media_type: str):
    if media_type == "a":
        return [book_id_identifier, movie_id_identifier, tv_id_identifier]
    else:
        return [media_type]