import standardmedia as sm


def test_get_standard_empty_media_defaults_and_keys():
    media = sm.getStandardEmptyMedia()

    expected_keys = {
        sm.title_key,
        sm.description_key,
        sm.id_key,
        sm.overall_rating_key,
        sm.image_key,
        sm.api_review_count_key,
        sm.genres_key,
        sm.release_date_key,
        sm.creator_key,
        sm.media_length_key,
        sm.season_count_key,
    }

    assert set(media.keys()) == expected_keys
    assert media[sm.title_key] == "N/A"
    assert media[sm.description_key] == "N/A"
    assert media[sm.id_key] == "N/A"
    assert media[sm.overall_rating_key] == -1.0
    assert media[sm.image_key] == "N/A"
    assert media[sm.api_review_count_key] == -1
    assert media[sm.genres_key] == []
    assert media[sm.release_date_key] == "N/A"
    assert media[sm.creator_key] == "N/A"
    assert media[sm.media_length_key] == -1.0
    assert media[sm.season_count_key] == -1


def test_get_standard_empty_media_returns_fresh_genres_list_each_call():
    first = sm.getStandardEmptyMedia()
    second = sm.getStandardEmptyMedia()

    first[sm.genres_key].append("Drama")

    assert first[sm.genres_key] == ["Drama"]
    assert second[sm.genres_key] == []


def test_get_standard_empty_review_defaults_and_keys():
    review = sm.getStandardEmptyReview()

    expected_keys = {
        sm.review_uid_key,
        sm.review_username_key,
        sm.review_media_id_key,
        sm.review_rating_key,
        sm.review_text_key,
        sm.review_visibility_key,
        sm.review_finished_on_key,
        sm.review_spoiler_key,
    }

    assert set(review.keys()) == expected_keys
    assert review[sm.review_uid_key] == "N/A"
    assert review[sm.review_username_key] == "N/A"
    assert review[sm.review_media_id_key] == "N/A"
    assert review[sm.review_rating_key] == -1.0
    assert review[sm.review_text_key] == "N/A"
    assert review[sm.review_visibility_key] == "N/A"
    assert review[sm.review_finished_on_key] == "N/A"
    assert review[sm.review_spoiler_key] is False


def test_get_standard_media_keys_order_and_values():
    keys = sm.getStandardMediaKeys()

    assert keys == (
        "title",
        "description",
        "overall_rating",
        "media_id",
        "image",
        "api_review_count",
        "genres",
        "release_date",
        "creator",
        "media_length",
        "season_count",
    )


def test_get_standard_review_keys_order_and_values():
    keys = sm.getStandardReviewKeys()

    assert keys == (
        "uid",
        "username",
        "media_id",
        "rating",
        "review_text",
        "review_visibility",
        "finished_on",
        "spoiler",
    )


def test_get_standard_media_identifiers_values():
    identifiers = sm.getStandardMediaIdentifiers()

    assert identifiers == ("b", "m", "t")


def test_get_invalid_media_values_shape_and_types():
    invalid_string, invalid_number = sm.getInvalidMediaValues()

    assert invalid_string == "N/A"
    assert invalid_number == -1
    assert isinstance(invalid_string, str)
    assert isinstance(invalid_number, int)
