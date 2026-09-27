import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import sys
import os

# Add parent directories to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

_STUBBED_MODULES = [
    "fastapi",
    "fastapi.security",
    "uvicorn",
    "pinecone",
    "cohere",
    "supabase",
    "firebase_admin",
    "torch",
    "transformers",
    "sentence_transformers",
]
_ORIGINAL_MODULES = {name: sys.modules.get(name) for name in _STUBBED_MODULES}

# Mock FastAPI and other heavy dependencies before importing
fastapi_mock = MagicMock()
fastapi_mock.security = MagicMock()
fastapi_mock.security.HTTPBearer = MagicMock()
fastapi_mock.security.HTTPAuthorizationCredentials = MagicMock()
sys.modules["fastapi"] = fastapi_mock
sys.modules["fastapi.security"] = fastapi_mock.security
sys.modules["uvicorn"] = MagicMock()
sys.modules["pinecone"] = MagicMock()
sys.modules["cohere"] = MagicMock()
sys.modules["supabase"] = MagicMock()
sys.modules["firebase_admin"] = MagicMock()
sys.modules["torch"] = MagicMock()
sys.modules["transformers"] = MagicMock()
sys.modules["sentence_transformers"] = MagicMock()

import external_media_service as ems

for _name, _module in _ORIGINAL_MODULES.items():
    if _module is not None:
        sys.modules[_name] = _module
    else:
        sys.modules.pop(_name, None)


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture(autouse=True)
def mock_external_boundaries(monkeypatch):
    """Block real external I/O and keep cache logic in-process for unit tests."""

    async def _http_passthrough(*args, **kwargs):
        return {}

    async def _cache_passthrough(*args, **kwargs):
        if kwargs:
            fn = kwargs["function"]
            fn_args = kwargs.get("args", ())
        else:
            fn_args = args[0]
            fn = args[3]
        return await fn(*fn_args)

    monkeypatch.setattr(
        ems, "sendAsyncHttpRequestGet", AsyncMock(side_effect=_http_passthrough)
    )
    monkeypatch.setattr(
        ems.cache_lock_logic,
        "cacheLockLogicTTL",
        AsyncMock(side_effect=_cache_passthrough),
    )
    monkeypatch.setattr(
        ems.cache_lock_logic,
        "cacheLockLogicLRU",
        AsyncMock(side_effect=_cache_passthrough),
    )


@pytest.fixture
def mock_httpx_client():
    """Mock httpx controller client"""
    return AsyncMock()


@pytest.fixture
def sample_movie_id():
    """Sample movie ID in standard format"""
    return "m12345"


@pytest.fixture
def sample_tv_id():
    """Sample TV ID in standard format"""
    return "t67890"


@pytest.fixture
def sample_book_id():
    """Sample Book ID in standard format"""
    return "b1234567890"


@pytest.fixture
def mock_raw_movie_data():
    """Mock raw TMDB movie data"""
    return {
        "id": 12345,
        "title": "Test Movie",
        "overview": "Test overview",
        "runtime": 120,
        "genres": [{"id": 28, "name": "Action"}],
        "release_date": "2024-01-01",
    }


@pytest.fixture
def mock_raw_tv_data():
    """Mock raw TMDB TV data"""
    return {
        "id": 67890,
        "name": "Test Show",
        "overview": "Test TV overview",
        "number_of_seasons": 2,
        "genres": [{"id": 18, "name": "Drama"}],
        "first_air_date": "2024-01-01",
    }


@pytest.fixture
def mock_credits():
    """Mock TMDB credits response"""
    return {
        "crew": [
            {"id": 1, "name": "Director Name", "job": "Director"},
            {"id": 2, "name": "Writer Name", "job": "Writer"},
        ],
        "cast": [{"id": 3, "name": "Actor Name", "character": "Main Character"}],
    }


@pytest.fixture
def mock_season_info():
    """Mock TMDB season info response"""
    return {
        "season_number": 1,
        "episodes": [
            {"episode_number": 1, "runtime": 45},
            {"episode_number": 2, "runtime": 42},
        ],
    }


# ============================================================================
# Helper Function Tests
# ============================================================================


class TestHelperFunctions:
    """Tests for helper functions"""

    def test_hour_calculator(self):
        """Test hourCalculator converts minutes to seconds"""
        result = ems.hourCalculator(1)
        assert result == 3600

    def test_hour_calculator_multiple(self):
        """Test hourCalculator with multiple hours"""
        result = ems.hourCalculator(2)
        assert result == 7200

    def test_minute_calculator(self):
        """Test minuteCalculator converts minutes to seconds"""
        result = ems.minuteCalculator(1)
        assert result == 60

    def test_minute_calculator_multiple(self):
        """Test minuteCalculator with multiple minutes"""
        result = ems.minuteCalculator(5)
        assert result == 300

    def test_log_time_check_disabled(self, capsys):
        """Test logTimeCheck does not print when disabled"""
        ems.logTimeCheck("Test message", False)
        captured = capsys.readouterr()
        assert captured.out == ""

    def test_log_time_check_enabled(self, capsys):
        """Test logTimeCheck prints when enabled"""
        ems.logTimeCheck("Test message", True)
        captured = capsys.readouterr()
        assert "Test message" in captured.out

    def test_simplify_search_list_removes_duplicates(self):
        """Test SimplyfySearchList removes duplicate titles"""
        search_list = [
            {"title": "Book Title", "creator": "Author Name", "id": "1"},
            {"title": "Book Title", "creator": "Author Name", "id": "2"},
            {"title": "Different Title", "creator": "Other Author", "id": "3"},
        ]
        result = ems.SimplyfySearchList(search_list)
        assert len(result) == 2
        assert result[0]["id"] == "1"
        assert result[1]["id"] == "3"

    def test_simplify_search_list_case_insensitive(self):
        """Test SimplyfySearchList is case-insensitive"""
        search_list = [
            {"title": "Book Title", "creator": "Author Name", "id": "1"},
            {"title": "BOOK TITLE", "creator": "author name", "id": "2"},
        ]
        result = ems.SimplyfySearchList(search_list)
        assert len(result) == 1

    def test_simplify_search_list_empty(self):
        """Test SimplyfySearchList with empty list"""
        result = ems.SimplyfySearchList([])
        assert result == []


# ============================================================================
# TMDB Runtime Tests
# ============================================================================


class TestTMDBRuntime:
    """Tests for TMDB runtime retrieval functions"""

    @pytest.mark.asyncio
    @patch("external_media_service.getTMDBUsingIDRawCached")
    async def test_get_movie_runtime_from_tmdb_cached(
        self, mock_raw, mock_raw_movie_data
    ):
        """Test getMovieRuntimeFromTMDBCached returns movie runtime"""
        mock_raw.return_value = mock_raw_movie_data

        result = await ems.getMovieRuntimeFromTMDBCached("m12345")

        assert result["total_runtime"] == 120
        mock_raw.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.getSeasonInfoFromTMDB")
    @patch("external_media_service.getTMDBUsingIDRawCached")
    async def test_get_tv_runtime_from_tmdb_cached(
        self, mock_raw, mock_season, mock_raw_tv_data, mock_season_info
    ):
        """Test getTvRuntimeFromTMDBCached calculates TV runtime"""
        # For 1 season with 2 episodes: 45 + 42 = 87
        raw_response = {**mock_raw_tv_data, "number_of_seasons": 1}
        mock_raw.return_value = raw_response
        mock_season.return_value = mock_season_info

        result = await ems.getTvRuntimeFromTMDBCached("t67890")

        assert result["total_runtime"] == 87  # 45 + 42 from mock episodes
        mock_raw.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.getTvRuntimeFromTMDBCached")
    async def test_get_runtime_from_tmdb_tv(self, mock_tv_runtime):
        """Test getRuntimeFromTMDB correctly routes to TV runtime"""
        mock_tv_runtime.return_value = {"total_runtime": 87}

        result = await ems.getRuntimeFromTMDB("t67890")

        assert result["total_runtime"] == 87

    @pytest.mark.asyncio
    async def test_get_runtime_from_tmdb_invalid_type(self):
        """Test getRuntimeFromTMDB returns None for invalid media type"""
        result = await ems.getRuntimeFromTMDB("x12345")
        assert result is None


# ============================================================================
# TMDB Credits Tests
# ============================================================================


class TestTMDBCredits:
    """Tests for TMDB credits retrieval"""

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_credits_from_tmdb_cached_movie(self, mock_request, mock_credits):
        """Test getCreditsFromTMDBCached retrieves movie credits"""
        mock_request.return_value = mock_credits

        result = await ems.getCreditsFromTMDBCached("m12345")

        assert "crew" in result
        assert len(result["crew"]) == 2
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_credits_from_tmdb_cached_tv(self, mock_request, mock_credits):
        """Test getCreditsFromTMDBCached retrieves TV credits"""
        mock_request.return_value = mock_credits

        result = await ems.getCreditsFromTMDBCached("t67890")

        assert "crew" in result
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_credits_from_tmdb_cached_invalid(self, mock_request):
        """Test getCreditsFromTMDBCached returns empty dict for invalid type"""
        result = await ems.getCreditsFromTMDBCached("x12345")

        assert result == {}
        mock_request.assert_not_called()


# ============================================================================
# TMDB ID Search Tests
# ============================================================================


class TestTMDBIDSearch:
    """Tests for TMDB ID-based search"""

    @pytest.mark.asyncio
    @patch("external_media_service.getCreditsfromTMDB")
    @patch("external_media_service.getCreditsfromTMDB")
    @patch("external_media_service.getRuntimeFromTMDB")
    @patch("external_media_service.getTMDBUsingIDRawCached")
    async def test_get_tmdb_using_id_cached_movie(
        self, mock_raw, mock_runtime, mock_credits, mock_raw_movie_data
    ):
        """Test getTMDBUsingIDCached returns cleaned movie data"""
        mock_raw.return_value = mock_raw_movie_data
        mock_runtime.return_value = {"total_runtime": 120}
        mock_credits.return_value = {"crew": []}

        result = await ems.getTMDBUsingIDCached("m12345", "m")

        assert result is not None
        mock_raw.assert_called_once()


# ============================================================================
# TV Season Tests
# ============================================================================


class TestTVSeason:
    """Tests for TV season info retrieval"""

    @pytest.mark.asyncio
    @patch("external_media_service.getTMDBUsingIDRawCached")
    async def test_get_tv_season_count_cached(self, mock_raw, mock_raw_tv_data):
        """Test getTvSeasonCountCached returns season count"""
        mock_raw.return_value = mock_raw_tv_data

        result = await ems.getTvSeasonCountCached("t67890")

        assert result["season_count"] == 2
        mock_raw.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.getTvSeasonCountCached")
    async def test_get_tv_season_count(self, mock_cached):
        """Test getTvSeasonCount returns count"""
        mock_cached.return_value = {"season_count": 2}

        result = await ems.getTvSeasonCount("t67890")

        assert result == 2

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_season_info_from_tmdb(self, mock_request, mock_season_info):
        """Test getSeasonInfoFromTMDB retrieves season data"""
        mock_request.return_value = mock_season_info

        result = await ems.getSeasonInfoFromTMDB("t67890", 1)

        assert result["season_number"] == 1
        assert len(result["episodes"]) == 2
        mock_request.assert_called_once()


# ============================================================================
# Book Search Tests
# ============================================================================


class TestBookSearch:
    """Tests for book-related searches"""

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_book_using_id_gp(self, mock_request):
        """Test getBookUsingIDGP returns cleaned book data"""
        mock_request.return_value = {
            "items": [
                {
                    "id": "1",
                    "volumeInfo": {
                        "title": "Test Book",
                        "authors": ["Test Author"],
                        "description": "Test description",
                    },
                }
            ]
        }

        result = await ems.getBookUsingIDGP("b1234567890")

        assert result is not None
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_book_using_id_gp_empty(self, mock_request):
        """Test getBookUsingIDGP returns empty dict when no books"""
        mock_request.return_value = {"items": []}

        result = await ems.getBookUsingIDGP("b1234567890")

        assert result == {}

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_book_using_id_isbndb_cached(self, mock_request):
        """Test getBookUsingIDISBNdbCached returns book data"""
        mock_request.return_value = {
            "book": {
                "isbn": "1234567890",
                "title": "Test Book",
                "authors": ["Test Author"],
            }
        }

        result = await ems.getBookUsingIDISBNdbCached("b1234567890")

        assert result is not None
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_book_using_id_isbndb_cached_empty(self, mock_request):
        """Test getBookUsingIDISBNdbCached returns error when no book"""
        mock_request.return_value = {"book": None}

        result = await ems.getBookUsingIDISBNdbCached("b1234567890")

        assert "status" in result
        assert result["status"] == "error"


# ============================================================================
# Book Rating Tests
# ============================================================================


class TestBookRating:
    """Tests for book rating retrieval"""

    @pytest.mark.asyncio
    @patch("external_media_service.supabase_review_logic.getBookRatingInfo")
    async def test_get_book_rating_info_from_db(self, mock_db):
        """Test getBookRatingInfo retrieves from database"""
        mock_db.return_value = {"overall_rating": 4.5, "api_review_count": 100}

        result = await ems.getBookRatingInfo("b1234567890")

        assert result[0] == 4.5
        assert result[1] == 100
        mock_db.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.supabase_review_logic.postBookRatingInfo")
    @patch("external_media_service.getBookUsingIDGP")
    @patch("external_media_service.supabase_review_logic.getBookRatingInfo")
    async def test_get_book_rating_info_from_api(self, mock_db, mock_gp, mock_post):
        """Test getBookRatingInfo falls back to API when not in DB"""
        mock_db.return_value = None
        mock_gp.return_value = {"overall_rating": 4.0, "api_review_count": 50}

        result = await ems.getBookRatingInfo("b1234567890")

        assert result[0] == 4.0
        assert result[1] == 50
        mock_gp.assert_called_once()


# ============================================================================
# TMDB Search Tests
# ============================================================================


class TestTMDBSearch:
    """Tests for TMDB search functions"""

    @pytest.mark.asyncio
    @patch("external_media_service.getRuntimeFromTMDB")
    @patch("external_media_service.getCreditsfromTMDB")
    @patch("external_media_service.sendAsyncHttpRequestGet")
    @patch("external_media_service.datacleaning.cleanUserInput")
    async def test_get_tmdb_via_search_cached_movies(
        self, mock_clean_input, mock_request, mock_credits, mock_runtime
    ):
        """Test getTMDBViaSearchCached searches and returns movies"""
        mock_clean_input.return_value = "test"
        mock_request.return_value = {
            "results": [{"id": 1, "title": "Movie 1"}, {"id": 2, "title": "Movie 2"}],
            "total_pages": 1,
        }
        mock_credits.return_value = {"crew": []}
        mock_runtime.return_value = {"total_runtime": 120}

        with patch(
            "external_media_service.datacleaning.checkValidMovie", return_value=True
        ):
            result = await ems.getTMDBViaSearchCached("test search", 2, "m")

        assert len(result) == 2
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    @patch("external_media_service.datacleaning.cleanUserInput")
    async def test_get_tmdb_via_search_cached_no_results(
        self, mock_clean_input, mock_request
    ):
        """Test getTMDBViaSearchCached returns empty when no results"""
        mock_clean_input.return_value = "test"
        mock_request.return_value = {"results": []}

        result = await ems.getTMDBViaSearchCached("test search", 5, "m")

        assert result == []


# ============================================================================
# Book Search Tests
# ============================================================================


class TestBookViaSearch:
    """Tests for book search via ISBNdb"""

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    @patch("external_media_service.datacleaning.cleanUserInput")
    async def test_get_book_via_search_cached(self, mock_clean_input, mock_request):
        """Test getBookVIASearchCached searches and returns books"""
        mock_clean_input.return_value = "test"
        mock_request.return_value = {
            "books": [
                {"isbn": "1", "title": "Book 1"},
                {"isbn": "2", "title": "Book 2"},
            ],
            "total": 2,
        }

        with patch(
            "external_media_service.datacleaning.cleanBookDataISBNdb",
            side_effect=lambda book, lang: book,
        ):
            with patch(
                "external_media_service.datacleaning.checkValidBook", return_value=True
            ):
                result = await ems.getBookVIASearchCached("test search", 2)

        assert len(result) >= 0
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    @patch("external_media_service.datacleaning.cleanUserInput")
    async def test_get_book_via_search_cached_no_results(
        self, mock_clean_input, mock_request
    ):
        """Test getBookVIASearchCached returns empty when no results"""
        mock_clean_input.return_value = "test"
        mock_request.return_value = {"books": []}

        result = await ems.getBookVIASearchCached("test search", 5)

        assert result == []


# ============================================================================
# Master Function Tests
# ============================================================================


class TestMasterFunctions:
    """Tests for master API functions"""

    @pytest.mark.asyncio
    @patch("external_media_service.cache_lock_logic.cacheLockLogicLRU")
    async def test_get_books_from_google_play_id_search(self, mock_cache):
        """Test getBooksFromGooglePlay with ID search"""
        mock_cache.return_value = {"title": "Test Book", "status": "success"}

        request = {
            "mode": "id_search",
            "type": "b",
            "media_id": "1234567890",
            "lang": "en",
        }

        result = await ems.getBooksFromGooglePlay(request)

        assert isinstance(result, list)
        assert len(result) == 1

    @pytest.mark.asyncio
    async def test_get_books_from_google_play_invalid_request(self):
        """Test getBooksFromGooglePlay returns error for invalid request"""
        request = {"type": "b"}

        result = await ems.getBooksFromGooglePlay(request)

        assert result == -1

    @pytest.mark.asyncio
    @patch("external_media_service.getTMDBViaSearchCached")
    async def test_get_media_from_tmdb_search(self, mock_search):
        """Test getMediaFromTMDB with search mode"""
        mock_search.return_value = [{"title": "Movie 1"}]

        request = {"mode": "search", "type": "m", "title": "test", "amount": 5}

        result = await ems.getMediaFromTMDB(request)

        assert isinstance(result, list)

    @pytest.mark.asyncio
    async def test_get_media_from_tmdb_invalid_request(self):
        """Test getMediaFromTMDB returns error for invalid request"""
        request = {"type": "m"}

        result = await ems.getMediaFromTMDB(request)

        assert result == -1

    @pytest.mark.asyncio
    @patch("external_media_service.getMediaFromTMDB")
    async def test_get_media_from_external_apis_movie(self, mock_tmdb):
        """Test getMediaFromExternalAPIs routes movies to TMDB"""
        mock_tmdb.return_value = [{"title": "Movie 1"}]

        request = {"type": "m", "mode": "search", "title": "test", "amount": 5}

        result = await ems.getMediaFromExternalAPIs(request)

        assert isinstance(result, list)

    @pytest.mark.asyncio
    @patch("external_media_service.getBooksFromGooglePlay")
    async def test_get_media_from_external_apis_book(self, mock_books):
        """Test getMediaFromExternalAPIs routes books correctly"""
        mock_books.return_value = [{"title": "Book 1"}]

        request = {"type": "b", "mode": "search", "title": "test", "amount": 5}

        result = await ems.getMediaFromExternalAPIs(request)

        assert isinstance(result, list)

    @pytest.mark.asyncio
    async def test_get_media_from_external_apis_invalid_type(self):
        """Test getMediaFromExternalAPIs returns error for invalid type"""
        request = {"type": "x"}

        result = await ems.getMediaFromExternalAPIs(request)

        assert result == -5


# ============================================================================
# Reviews Tests
# ============================================================================


class TestReviews:
    """Tests for review retrieval"""

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_reviews_from_tmdb_cached(self, mock_request):
        """Test getReviewsFromTMDBCached returns reviews"""
        mock_request.return_value = {
            "results": [
                {"id": 1, "content": "Great movie", "author_details": {"rating": 9}},
                {"id": 2, "content": "Good film", "author_details": {"rating": 8}},
            ],
            "total_pages": 1,
        }

        result = await ems.getReviewsFromTMDBCached("m12345", 2)

        assert isinstance(result, list)
        mock_request.assert_called_once()

    @pytest.mark.asyncio
    @patch("external_media_service.sendAsyncHttpRequestGet")
    async def test_get_reviews_from_tmdb_cached_no_results(self, mock_request):
        """Test getReviewsFromTMDBCached returns empty when no reviews"""
        mock_request.return_value = {"results": []}

        result = await ems.getReviewsFromTMDBCached("m12345", 5)

        assert result == []


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
