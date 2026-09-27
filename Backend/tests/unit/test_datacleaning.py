import os
import re
import sys
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))


_STUBBED_MODULES = ["fastapi", "standardmedia", "requests", "markdown", "bs4"]
_ORIGINAL_MODULES = {name: sys.modules.get(name) for name in _STUBBED_MODULES}


class DummyFastAPI:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


class DummySoup:
    def __init__(self, html, parser):
        self.html = html

    def get_text(self):
        return re.sub(r"<[^>]+>", "", self.html)


def _install_stubs():
    fastapi_mod = types.ModuleType("fastapi")
    fastapi_mod.FastAPI = DummyFastAPI
    fastapi_mod.Response = object
    sys.modules["fastapi"] = fastapi_mod

    standardmedia_mod = types.ModuleType("standardmedia")
    standardmedia_mod.title_key = "title"
    standardmedia_mod.description_key = "description"
    standardmedia_mod.overall_rating_key = "overall_rating"
    standardmedia_mod.id_key = "id"
    standardmedia_mod.image_key = "image"
    standardmedia_mod.api_review_count_key = "api_review_count"
    standardmedia_mod.genres_key = "genres"
    standardmedia_mod.release_date_key = "release_date"
    standardmedia_mod.creator_key = "creator"
    standardmedia_mod.media_length_key = "media_length"
    standardmedia_mod.season_count_key = "season_count"
    standardmedia_mod.review_uid_key = "uid"
    standardmedia_mod.review_username_key = "username"
    standardmedia_mod.review_media_id_key = "media_id"
    standardmedia_mod.review_rating_key = "rating"
    standardmedia_mod.review_text_key = "review_text"
    standardmedia_mod.review_visibility_key = "visibility"
    standardmedia_mod.review_finished_on_key = "finished_on"
    standardmedia_mod.review_spoiler_key = "spoiler"
    standardmedia_mod.getStandardMediaKeys = lambda: (
        standardmedia_mod.title_key,
        standardmedia_mod.description_key,
        standardmedia_mod.overall_rating_key,
        standardmedia_mod.id_key,
        standardmedia_mod.image_key,
        standardmedia_mod.api_review_count_key,
        standardmedia_mod.genres_key,
        standardmedia_mod.release_date_key,
        standardmedia_mod.creator_key,
        standardmedia_mod.media_length_key,
        standardmedia_mod.season_count_key,
    )
    standardmedia_mod.getStandardMediaIdentifiers = lambda: ("b", "m", "t")
    standardmedia_mod.getInvalidMediaValues = lambda: ("INVALID_STR", -1)
    standardmedia_mod.getStandardReviewKeys = lambda: (
        standardmedia_mod.review_uid_key,
        standardmedia_mod.review_username_key,
        standardmedia_mod.review_media_id_key,
        standardmedia_mod.review_rating_key,
        standardmedia_mod.review_text_key,
        standardmedia_mod.review_visibility_key,
        standardmedia_mod.review_finished_on_key,
        standardmedia_mod.review_spoiler_key,
    )
    standardmedia_mod.getStandardEmptyMedia = lambda: {
        standardmedia_mod.title_key: "N/A",
        standardmedia_mod.description_key: "N/A",
        standardmedia_mod.overall_rating_key: -1,
        standardmedia_mod.id_key: "N/A",
        standardmedia_mod.image_key: "INVALID_STR",
        standardmedia_mod.api_review_count_key: -1,
        standardmedia_mod.genres_key: [],
        standardmedia_mod.release_date_key: "N/A",
        standardmedia_mod.creator_key: "INVALID_STR",
        standardmedia_mod.media_length_key: -1,
        standardmedia_mod.season_count_key: -1,
    }
    standardmedia_mod.getStandardEmptyReview = lambda: {
        standardmedia_mod.review_uid_key: "N/A",
        standardmedia_mod.review_username_key: "N/A",
        standardmedia_mod.review_media_id_key: "N/A",
        standardmedia_mod.review_rating_key: -1,
        standardmedia_mod.review_text_key: "N/A",
        standardmedia_mod.review_visibility_key: "N/A",
        standardmedia_mod.review_finished_on_key: "N/A",
        standardmedia_mod.review_spoiler_key: False,
    }
    sys.modules["standardmedia"] = standardmedia_mod

    requests_mod = types.ModuleType("requests")
    requests_mod.head = lambda *args, **kwargs: types.SimpleNamespace(status_code=200)
    sys.modules["requests"] = requests_mod

    markdown_mod = types.ModuleType("markdown")
    markdown_mod.markdown = lambda text: (
        f"<p>{re.sub(r'\*\*(.*?)\*\*', lambda match: f'<strong>{match.group(1)}</strong>', text)}</p>"
    )
    sys.modules["markdown"] = markdown_mod

    bs4_mod = types.ModuleType("bs4")
    bs4_mod.BeautifulSoup = DummySoup
    sys.modules["bs4"] = bs4_mod


_install_stubs()

import datacleaning as dc

for _name, _module in _ORIGINAL_MODULES.items():
    if _module is not None:
        sys.modules[_name] = _module
    else:
        sys.modules.pop(_name, None)


def _book_base():
    return {
        dc.id_key: "b123",
        dc.description_key: "Some description",
        dc.image_key: "https://img",
        dc.creator_key: "Author",
        dc.genres_key: ["fiction"],
    }


def _movie_base():
    return {
        dc.id_key: "m123",
        dc.description_key: "Some movie",
        dc.overall_rating_key: 4,
        dc.image_key: "https://img",
        dc.creator_key: "Director",
        dc.genres_key: ["drama"],
    }


def _tv_base():
    return {
        dc.id_key: "t123",
        dc.description_key: "Some tv",
        dc.overall_rating_key: 4,
        dc.image_key: "https://img",
        dc.genres_key: ["drama"],
    }


def test_basic_utility_functions():
    assert dc.cleanUserInput("HeLLo\nWorld") == "helloworld"
    assert dc.checkEmptyString(None) is True
    assert dc.checkEmptyString("   ") is True
    assert dc.checkEmptyString("x") is False
    assert dc.isValidID("12345") is True
    assert dc.isValidID("") is False
    assert dc.isValidID("12a") is False
    assert dc.roundOverallRating(4.24) == 4.0
    assert dc.roundOverallRating(4.26) == 4.5
    assert dc.validateUserInput("  Test\nValue  ") == "  testvalue  "
    assert dc.validateUserInput("   ") == ""
    assert dc.checkContainsSpoilers("This has a spoiler in it") is True
    assert dc.checkContainsSpoilers("spoiler-free discussion") is False
    assert dc.checkContainsSpoilers("No spoiler discussion") is True


def test_get_keys_and_genre_cleaning_and_markdown():
    keys = dc.getKeys()
    assert keys["title"] == dc.title_key
    assert keys["id"] == dc.id_key
    assert dc.cleanGenres(["Fiction", "Ballet", "Unknown"]) == [
        "fiction",
        "art",
        "sports",
        "unknown",
    ] or sorted(dc.cleanGenres(["Fiction", "Ballet", "Unknown"])) == [
        "art",
        "fiction",
        "sports",
        "unknown",
    ]
    assert dc.removeMarkdown("**Bold** text") == "Bold text"


def test_validators_cover_true_false_branches():
    valid_book = _book_base()
    assert dc.checkValidBook(valid_book) is True
    assert dc.checkValidBook({**valid_book, dc.id_key: "N/A"}) is False
    assert dc.checkValidBook({**valid_book, dc.description_key: ""}) is False
    assert (
        dc.checkValidBook({**valid_book, dc.image_key: dc.media_invalid_str_key})
        is False
    )
    assert (
        dc.checkValidBook({**valid_book, dc.creator_key: dc.media_invalid_str_key})
        is False
    )
    assert dc.checkValidBook({**valid_book, dc.genres_key: []}) is False

    valid_movie = _movie_base()
    assert dc.checkValidMovie(valid_movie) is True
    assert dc.checkValidMovie({**valid_movie, dc.id_key: "mabc"}) is False
    assert dc.checkValidMovie({**valid_movie, dc.description_key: ""}) is False
    assert dc.checkValidMovie({**valid_movie, dc.overall_rating_key: -1}) is False
    assert (
        dc.checkValidMovie({**valid_movie, dc.image_key: dc.media_invalid_str_key})
        is False
    )
    assert (
        dc.checkValidMovie({**valid_movie, dc.creator_key: dc.media_invalid_str_key})
        is False
    )
    assert dc.checkValidMovie({**valid_movie, dc.genres_key: []}) is False

    valid_tv = _tv_base()
    assert dc.checkValidTv(valid_tv) is True
    assert dc.checkValidTv({**valid_tv, dc.id_key: "tabc"}) is False
    assert dc.checkValidTv({**valid_tv, dc.description_key: ""}) is False
    assert dc.checkValidTv({**valid_tv, dc.overall_rating_key: -1}) is False
    assert (
        dc.checkValidTv({**valid_tv, dc.image_key: dc.media_invalid_str_key}) is False
    )
    assert dc.checkValidTv({**valid_tv, dc.genres_key: []}) is False


def test_clean_book_data_gp_branches():
    ebook = {
        "saleInfo": {"isEbook": True},
        "volumeInfo": {"industryIdentifiers": [{"type": "ISBN", "identifier": "1"}]},
    }
    assert dc.cleanBookDataGP(ebook) == dc.standardmedia.getStandardEmptyMedia()

    missing_identifiers = {"volumeInfo": {}}
    assert (
        dc.cleanBookDataGP(missing_identifiers)
        == dc.standardmedia.getStandardEmptyMedia()
    )

    invalid_type = {
        "volumeInfo": {"industryIdentifiers": [{"type": "OTHER", "identifier": "1"}]}
    }
    assert dc.cleanBookDataGP(invalid_type) == dc.standardmedia.getStandardEmptyMedia()

    valid = {
        "volumeInfo": {
            "industryIdentifiers": [{"type": "ISBN_13", "identifier": "9781234567890"}],
            "averageRating": 4.24,
            "ratingsCount": 7,
        }
    }
    cleaned = dc.cleanBookDataGP(valid)
    assert cleaned[dc.overall_rating_key] == 4.0
    assert cleaned[dc.api_review_count_key] == 7


def test_book_rating_helpers():
    book = dc.standardmedia.getStandardEmptyMedia()
    updated = dc.bookAddRatingFromGP(
        book.copy(), {"volumeInfo": {"averageRating": 4.6, "ratingsCount": 12}}
    )
    assert updated[dc.overall_rating_key] == 4.5
    assert updated[dc.api_review_count_key] == 12

    unchanged = {
        **book,
        dc.overall_rating_key: 3,
        dc.api_review_count_key: 2,
    }
    assert (
        dc.bookAddRatingFromGP(
            unchanged.copy(), {"volumeInfo": {"averageRating": 5, "ratingsCount": 9}}
        )[dc.overall_rating_key]
        == 3
    )

    sp_updated = dc.bookAddRatingFromSupabase(
        book.copy(), {"average_rating": 3.6, "review_count": 9}
    )
    assert sp_updated[dc.overall_rating_key] == 3.5
    assert sp_updated[dc.api_review_count_key] == 9


def test_clean_book_data_isbndb_branches():
    base = {
        "language": "en",
        "title": "Title",
        "overview": "**Desc**",
        "image": "https://covers.example/img.jpg",
        "isbn": "1234567890",
        "subjects": ["Fiction", "Unknown"],
        "date_published": "2024-01-02",
        "authors": ["Author A", "Author B"],
        "pages": 321,
    }
    cleaned = dc.cleanBookDataISBNdb(base)
    assert cleaned[dc.title_key] == "Title"
    assert cleaned[dc.description_key] == "Desc"
    assert cleaned[dc.id_key] == "b1234567890"
    assert cleaned[dc.image_key] == "https://covers.example/img.jpg"
    assert cleaned[dc.genres_key] == ["fiction", "unknown"] or sorted(
        cleaned[dc.genres_key]
    ) == ["fiction", "unknown"]
    assert cleaned[dc.release_date_key] == "2024"
    assert cleaned[dc.creator_key] == "Author A | Author B"
    assert cleaned[dc.media_length_key] == 321

    assert (
        dc.cleanBookDataISBNdb({"language": "fr"})
        == dc.standardmedia.getStandardEmptyMedia()
    )
    assert (
        dc.cleanBookDataISBNdb({"language": "en", "edition": "2nd edition"})
        == dc.standardmedia.getStandardEmptyMedia()
    )
    assert (
        dc.cleanBookDataISBNdb({"language": "en", "binding": "ebook"})
        == dc.standardmedia.getStandardEmptyMedia()
    )


def test_clean_book_data_isbndb_synopsis_and_zero_pages(capsys):
    book = {
        "language": "en",
        "synopsis": "**Synopsis**",
        "isbn": "999",
        "pages": 0,
    }
    cleaned = dc.cleanBookDataISBNdb(book)
    assert cleaned[dc.description_key] == "Synopsis"
    assert cleaned[dc.media_length_key] == 0
    assert (
        "ILESUVJKNVSJKNLVJKNVSDJKNVSDJKNVDSNJKDSVNJKDSVJKNDVSKNJDSV"
        in capsys.readouterr().out
    )


def test_clean_movie_data_branches():
    movie = {
        "mid": "123",
        "title": "Movie",
        "overview": "Overview",
        "vote_average": 8,
        "poster_path": "/path.jpg",
        "vote_count": 10,
        "genre_ids": [18, 35],
        "release_date": "2023-05-04",
    }
    credits = {"crew": [{"job": "Director", "name": "Dir"}]}
    runtime = {"total_runtime": 111}
    cleaned = dc.cleanMovieData(movie, credits, runtime)
    assert cleaned[dc.id_key] == "m123"
    assert cleaned[dc.title_key] == "Movie"
    assert cleaned[dc.description_key] == "Overview"
    assert cleaned[dc.overall_rating_key] == 4.0
    assert cleaned[dc.image_key].startswith(dc.tmdb_poster_base_url)
    assert cleaned[dc.api_review_count_key] == 10
    assert cleaned[dc.release_date_key] == "2023"
    assert cleaned[dc.creator_key] == "Dir"
    assert cleaned[dc.media_length_key] == 111

    movie_with_genres = {
        "id": "456",
        "title": "Movie 2",
        "overview": "Overview",
        "vote_average": 6,
        "poster_path": None,
        "vote_count": 1,
        "genres": [{"id": 18}, {"name": "Comedy"}],
        "release_date": "2022-01-01",
    }
    cleaned2 = dc.cleanMovieData(movie_with_genres, {"crew": []}, {"total_runtime": 50})
    assert cleaned2[dc.id_key] == "m456"
    assert cleaned2[dc.image_key] == dc.media_invalid_str_key
    assert cleaned2[dc.creator_key] == dc.media_invalid_str_key
    assert sorted(cleaned2[dc.genres_key]) == ["comedy", "drama"]

    assert (
        dc.cleanMovieData({"id": "abc"}, {"crew": []}, {"total_runtime": 0})
        == dc.standardmedia.getStandardEmptyMedia()
    )


def test_clean_tv_data_branches():
    tv = {
        "tid": "321",
        "name": "Show",
        "overview": "Overview",
        "vote_average": 8,
        "poster_path": "/path.jpg",
        "vote_count": 9,
        "genre_ids": [18, 35],
        "first_air_date": "2021-03-04",
        "number_of_seasons": 4,
    }
    credits = {
        "crew": [
            {"job": "Creator", "name": "Creator One"},
            {"job": "Created By", "name": "Creator Two"},
        ]
    }
    runtime = {"total_runtime": 88}
    cleaned = dc.cleanTvData(tv, credits, runtime)
    assert cleaned[dc.id_key] == "t321"
    assert cleaned[dc.title_key] == "Show"
    assert cleaned[dc.overall_rating_key] == 4.0
    assert cleaned[dc.season_count_key] == 4
    assert cleaned[dc.media_length_key] == 88
    assert cleaned[dc.creator_key] == "Creator One, Creator Two"

    tv2 = {
        "id": "654",
        "name": "Show 2",
        "overview": "Overview",
        "vote_average": 6,
        "poster_path": None,
        "vote_count": 1,
        "genres": [{"id": 18}, {"name": "Comedy"}],
        "first_air_date": "2020-01-01",
    }
    cleaned2 = dc.cleanTvData(tv2, {"crew": []}, {"total_runtime": 10})
    assert cleaned2[dc.id_key] == "t654"
    assert cleaned2[dc.image_key] == dc.media_invalid_str_key
    assert cleaned2[dc.creator_key] == dc.media_invalid_str_key
    assert sorted(cleaned2[dc.genres_key]) == ["comedy", "drama"]

    assert (
        dc.cleanTvData({"id": "abc"}, {"crew": []}, {"total_runtime": 0})
        == dc.standardmedia.getStandardEmptyMedia()
    )


def test_review_cleaners():
    tmdb_review = {
        "author_details": {"username": "alice", "rating": 8},
        "content": "This has a spoiler in it",
        "created_at": "2024-04-01T12:00:00Z",
    }
    cleaned = dc.cleanTMDBReview(tmdb_review)
    assert cleaned[dc.review_username_key] == "alice"
    assert cleaned[dc.review_uid_key] == "alice"
    assert cleaned[dc.review_rating_key] == 4.0
    assert cleaned[dc.review_text_key] == "This has a spoiler in it"
    assert cleaned[dc.review_finished_on_key] == "2024-04-01"
    assert cleaned[dc.review_spoiler_key] is True

    assert (
        dc.cleanTMDBReview({"author_details": {}})
        == dc.standardmedia.getStandardEmptyReview()
    )

    sp_review = {dc.review_text_key: "spoiler alert", dc.review_spoiler_key: False}
    cleaned_sp = dc.cleanSupabaseReview(sp_review)
    assert cleaned_sp[dc.review_spoiler_key] is True

    spoiler_true = {dc.review_spoiler_key: True, dc.review_text_key: "anything"}
    assert dc.cleanSupabaseReview(spoiler_true) == spoiler_true
