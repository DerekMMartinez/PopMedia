import asyncio
import sys
from unittest.mock import AsyncMock
import pytest

_STUBBED_MODULES = [
    "dotenv",
    "os",
    "firebase_admin",
    "firebase_admin.credentials",
    "firebase_admin.auth",
    "fastapi",
    "fastapi.security",
    "standardmedia",
    "supabase",
    "supabase_user_logic",
    "external_media_service",
    "supabase_connection_logic",
]
_ORIGINAL_MODULES = {name: sys.modules.get(name) for name in _STUBBED_MODULES}


# ============================================================================
# Stub Module Installation
# ============================================================================
def _install_stubs():
    """Install stub modules for all external dependencies before importing the target module."""

    # Stub: dotenv
    class dotenv_mod:
        def load_dotenv(self):
            pass

    sys.modules["dotenv"] = dotenv_mod()

    # Stub: os
    class os_path_mod:
        @staticmethod
        def join(*args):
            return "/".join(args)

        @staticmethod
        def dirname(path):
            parts = path.split("/")
            return "/".join(parts[:-1]) if len(parts) > 1 else "."

        @staticmethod
        def exists(path):
            return True

        @staticmethod
        def isfile(path):
            return True

        @staticmethod
        def isdir(path):
            return True

    class os_mod:
        path = os_path_mod

        @staticmethod
        def getenv(key):
            return "test_api_key"

        @staticmethod
        def environ():
            return {}

    sys.modules["os"] = os_mod

    # Stub: firebase_admin
    class firebase_admin_mod:
        def initialize_app(self, *args, **kwargs):
            pass

    class credentials_mod:
        @staticmethod
        def Certificate(*args, **kwargs):
            return {}

    class auth_mod:
        @staticmethod
        def verify_id_token(token):
            return {"uid": "test_user_id"}

    firebase_admin_mod.credentials = credentials_mod
    firebase_admin_mod.auth = auth_mod

    sys.modules["firebase_admin"] = firebase_admin_mod
    sys.modules["firebase_admin.credentials"] = credentials_mod
    sys.modules["firebase_admin.auth"] = auth_mod

    # Stub: fastapi
    class HTTPException(Exception):
        def __init__(self, status_code, detail):
            self.status_code = status_code
            self.detail = detail

    class HTTPBearer:
        pass

    class HTTPAuthorizationCredentials:
        def __init__(self, scheme, credentials):
            self.scheme = scheme
            self.credentials = credentials

    class Depends:
        def __init__(self, dependency):
            self.dependency = dependency

    class FastAPI:
        def __init__(self):
            self.routes = []

        def post(self, path):
            def decorator(func):
                self.routes.append({"path": path, "method": "POST", "func": func})
                return func

            return decorator

        def get(self, path):
            def decorator(func):
                self.routes.append({"path": path, "method": "GET", "func": func})
                return func

            return decorator

    class fastapi_mod:
        pass

    fastapi_mod.FastAPI = FastAPI
    fastapi_mod.HTTPException = HTTPException
    fastapi_mod.Depends = Depends

    class fastapi_security_mod:
        pass

    fastapi_security_mod.HTTPBearer = HTTPBearer
    fastapi_security_mod.HTTPAuthorizationCredentials = HTTPAuthorizationCredentials

    sys.modules["fastapi"] = fastapi_mod
    sys.modules["fastapi.security"] = fastapi_security_mod

    # Stub: standardmedia
    class standardmedia_mod:
        @staticmethod
        def getStandardMediaKeys():
            return (
                "title",
                "description",
                "overall_rating",
                "id",
                "image",
                "api_review_count",
                "genres",
                "release_date",
                "creator",
                "media_length",
                "season_count",
            )

        @staticmethod
        def getStandardMediaIdentifiers():
            return ("book", "movie", "tv")

        @staticmethod
        def getInvalidMediaValues():
            return ("INVALID_STR", -1)

    sys.modules["standardmedia"] = standardmedia_mod

    # Stub: supabase
    class QueryBuilder:
        def __init__(self, table_name=None):
            self.table_name = table_name
            self._select_query = None
            self._where_conditions = {}
            self._data = None
            self._insert_data = None

        def select(self, *args, **kwargs):
            self._select_query = args
            return self

        def eq(self, key, value):
            self._where_conditions[key] = value
            return self

        def execute(self):
            # Mock response
            class Response:
                def __init__(self):
                    self.data = []
                    self.count = 0

            return Response()

        def insert(self, data):
            self._insert_data = data
            return self

    class SupabaseClient:
        def __init__(self):
            self.tables = {}

        def table(self, name):
            return QueryBuilder(name)

    class supabase_mod:
        pass

    supabase_mod.create_client = lambda url, key: SupabaseClient()
    supabase_mod.Client = SupabaseClient

    sys.modules["supabase"] = supabase_mod

    # Stub: supabase_user_logic
    class supabase_user_logic_mod:
        pass

    sys.modules["supabase_user_logic"] = supabase_user_logic_mod

    # Stub: external_media_service
    class external_media_service_mod:
        @staticmethod
        def getMediaFromExternalAPIs(*args, **kwargs):
            return []

        @staticmethod
        def determineMediaType(*args, **kwargs):
            return "movie"

        @staticmethod
        def getMediaFromAllAPIs(*args, **kwargs):
            return []

    sys.modules["external_media_service"] = external_media_service_mod

    # Stub: supabase_connection_logic
    class supabase_connection_logic_mod:
        pass

    supabase_connection_logic_mod.supabase = SupabaseClient()

    sys.modules["supabase_connection_logic"] = supabase_connection_logic_mod


# Install stubs before importing the target module
def _ensure_stubs_installed():
    """Ensure stubs are installed exactly once per test session."""
    if not hasattr(sys.modules.get("supabase_badge_logic"), "__stubs_installed"):
        _install_stubs()


# Use a module-level fixture to install stubs
@pytest.fixture(scope="module", autouse=True)
def setup_badge_logic_stubs():
    """Setup stubs for badge logic tests."""
    _ensure_stubs_installed()
    yield


_ensure_stubs_installed()
import supabase_badge_logic as sbl

for _name, _module in _ORIGINAL_MODULES.items():
    if _module is not None:
        sys.modules[_name] = _module
    else:
        sys.modules.pop(_name, None)


# ============================================================================
# Mock Supabase Response
# ============================================================================
class MockResponse:
    def __init__(self, data=None, count=None):
        self.data = data if data is not None else []
        self.count = count


class MockQueryBuilder:
    def __init__(self, table_name):
        self.table_name = table_name
        self._where_conditions = {}
        self._gte_conditions = {}
        self._lte_conditions = {}
        self._count = False
        self._mock_data = None

    def select(self, *args, **kwargs):
        self._count = kwargs.get("count") == "exact"
        return self

    def eq(self, key, value):
        self._where_conditions[key] = value
        return self

    def gte(self, key, value):
        self._gte_conditions[key] = value
        return self

    def lte(self, key, value):
        self._lte_conditions[key] = value
        return self

    def insert(self, data):
        self._insert_data = data
        return self

    def execute(self):
        # Filter mock data based on conditions
        if self._mock_data is None:
            return MockResponse([], 0 if self._count else None)

        # Filter data based on where conditions
        filtered_data = self._mock_data
        for key, value in self._where_conditions.items():
            filtered_data = [item for item in filtered_data if item.get(key) == value]

        for key, value in self._gte_conditions.items():
            filtered_data = [item for item in filtered_data if item.get(key) >= value]

        for key, value in self._lte_conditions.items():
            filtered_data = [item for item in filtered_data if item.get(key) <= value]

        return MockResponse(filtered_data, len(filtered_data) if self._count else None)


class MockSupabase:
    def __init__(self):
        self._table_data = {"badges_earned": [], "badges": []}

    def table(self, name):
        builder = MockQueryBuilder(name)
        # Set mock data
        builder._mock_data = self._table_data.get(name, [])
        return builder


# ============================================================================
# Test Classes
# ============================================================================
class TestPostNewBadgeEarned:
    """Test the postNewBadgeEarned function."""

    def setup_method(self):
        """Reset mock supabase before each test."""
        sbl.supabase = MockSupabase()

    def test_post_new_badge_success(self, monkeypatch):
        """Test successfully posting a new badge."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badge_data = {
            "uid": "user123",
            "bid": "badge_001",
            "earned_at": "2024-01-01T00:00:00",
        }

        result = sbl.postNewBadgeEarned(badge_data)

        assert result["status"] == "success"
        assert result["table"] == "badges_earned"

    def test_post_new_badge_duplicate(self, monkeypatch):
        """Test posting a badge that already exists."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        # Set up existing badge
        existing_badge = {
            "uid": "user123",
            "bid": "badge_001",
            "earned_at": "2024-01-01T00:00:00",
        }
        mock_supabase._table_data["badges_earned"] = [existing_badge]

        badge_data = {
            "uid": "user123",
            "bid": "badge_001",
            "earned_at": "2024-01-01T00:00:00",
        }

        result = sbl.postNewBadgeEarned(badge_data)

        assert result["status"] == "success"
        assert result["message"] == "Badge already earned"

    def test_post_new_badge_different_user_same_badge(self, monkeypatch):
        """Test posting same badge for different user."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        # First badge for user1
        existing_badge = {
            "uid": "user1",
            "bid": "badge_001",
            "earned_at": "2024-01-01T00:00:00",
        }
        mock_supabase._table_data["badges_earned"] = [existing_badge]

        # Try to post same badge for user2
        badge_data = {
            "uid": "user2",
            "bid": "badge_001",
            "earned_at": "2024-01-01T00:00:00",
        }

        result = sbl.postNewBadgeEarned(badge_data)

        assert result["status"] == "success"
        assert result["table"] == "badges_earned"

    def test_post_new_badge_error_handling(self, monkeypatch, capsys):
        """Test error handling in postNewBadgeEarned."""
        mock_supabase = MockSupabase()

        # Make select raise an exception
        def raise_error(*args, **kwargs):
            raise Exception("Database connection error")

        class ErrorQueryBuilder(MockQueryBuilder):
            def select(self, *args, **kwargs):
                raise Exception("Database connection error")

        class ErrorSupabase(MockSupabase):
            def table(self, name):
                builder = ErrorQueryBuilder(name)
                builder._mock_data = self._table_data.get(name, [])
                return builder

        sbl.supabase = ErrorSupabase()

        badge_data = {
            "uid": "user123",
            "bid": "badge_001",
            "earned_at": "2024-01-01T00:00:00",
        }

        result = sbl.postNewBadgeEarned(badge_data)

        assert result["status"] == "error"
        assert "message" in result
        captured = capsys.readouterr()
        assert "CHECKPOINT FAILURE postNewBadgeEarned" in captured.out


class TestGetBadgeCount:
    """Test the getBadgeCount function."""

    def setup_method(self):
        """Reset mock supabase before each test."""
        sbl.supabase = MockSupabase()

    def test_get_badge_count_multiple_badges(self, capsys):
        """Test getting badge count for user with multiple badges."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        # Set up multiple badges
        badges = [
            {"uid": "user123", "bid": "badge_001", "earned_at": "2024-01-01"},
            {"uid": "user123", "bid": "badge_002", "earned_at": "2024-01-02"},
            {"uid": "user123", "bid": "badge_003", "earned_at": "2024-01-03"},
        ]
        mock_supabase._table_data["badges_earned"] = badges

        count = sbl.getBadgeCount("user123")

        assert count == 3
        captured = capsys.readouterr()
        assert "badge count for uid user123: 3" in captured.out

    def test_get_badge_count_no_badges(self, capsys):
        """Test getting badge count for user with no badges."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges_earned"] = []

        count = sbl.getBadgeCount("user456")

        assert count == 0
        captured = capsys.readouterr()
        assert "badge count for uid user456: 0" in captured.out

    def test_get_badge_count_other_users_badges_not_counted(self, capsys):
        """Test that only the specified user's badges are counted."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badges = [
            {"uid": "user1", "bid": "badge_001", "earned_at": "2024-01-01"},
            {"uid": "user2", "bid": "badge_002", "earned_at": "2024-01-02"},
            {"uid": "user1", "bid": "badge_003", "earned_at": "2024-01-03"},
        ]
        mock_supabase._table_data["badges_earned"] = badges

        count = sbl.getBadgeCount("user1")

        # Mock correctly filters by uid now
        assert count == 2
        captured = capsys.readouterr()
        assert "badge count for uid user1: 2" in captured.out


class TestGetBadgesEarned:
    """Test the getBadgesEarned function."""

    def setup_method(self):
        """Reset mock supabase before each test."""
        sbl.supabase = MockSupabase()

    def test_get_badges_earned_multiple_badges(self):
        """Test getting multiple badges earned by a user."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        # Set up badges earned
        badges_earned = [
            {"uid": "user123", "bid": "badge_001", "earned_at": "2024-01-01"},
            {"uid": "user123", "bid": "badge_002", "earned_at": "2024-01-02"},
        ]
        mock_supabase._table_data["badges_earned"] = badges_earned

        # Set up badge definitions
        badges_def = [
            {"bid": "badge_001", "name": "First Badge"},
            {"bid": "badge_002", "name": "Second Badge"},
        ]
        mock_supabase._table_data["badges"] = badges_def

        result = sbl.getBadgesEarned("user123")

        assert isinstance(result, list)
        assert len(result) == 2
        assert result[0][0] == badges_earned[0]
        assert result[1][0] == badges_earned[1]

    def test_get_badges_earned_no_badges(self):
        """Test getting badges for user with no earned badges."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges_earned"] = []

        result = sbl.getBadgesEarned("user456")

        assert isinstance(result, list)
        assert len(result) == 0

    def test_get_badges_earned_single_badge(self):
        """Test getting single badge earned by user."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badges_earned = [
            {"uid": "user789", "bid": "special_badge", "earned_at": "2024-03-15"}
        ]
        mock_supabase._table_data["badges_earned"] = badges_earned
        badges_def = [
            {
                "bid": "special_badge",
                "name": "Special Badge",
                "description": "A special achievement",
            }
        ]
        mock_supabase._table_data["badges"] = badges_def

        result = sbl.getBadgesEarned("user789")

        assert len(result) == 1
        assert result[0][0]["uid"] == "user789"
        assert result[0][0]["bid"] == "special_badge"

    def test_get_badges_earned_error_handling(self, capsys):
        """Test error handling in getBadgesEarned."""

        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("Database error")

        sbl.supabase = ErrorSupabase()

        result = sbl.getBadgesEarned("user123")

        assert isinstance(result, dict)
        assert result["status"] == "error"
        captured = capsys.readouterr()
        assert "CHECKPOINT FAILURE getBadgesEarned" in captured.out


class TestGetBadgeFromId:
    """Test the getBadgeFromId function."""

    def setup_method(self):
        """Reset mock supabase before each test."""
        sbl.supabase = MockSupabase()

    def test_get_badge_from_id_existing_badge(self):
        """Test getting an existing badge by ID."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badge_def = {
            "bid": "badge_achievement_001",
            "name": "Achievement Badge",
            "description": "Earned for achieving something",
            "icon": "achievement.png",
        }
        mock_supabase._table_data["badges"] = [badge_def]

        result = sbl.getBadgeFromId("badge_achievement_001")

        assert isinstance(result, list)
        assert len(result) == 1
        assert result[0]["bid"] == "badge_achievement_001"

    def test_get_badge_from_id_nonexistent_badge(self):
        """Test getting a badge that doesn't exist."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = []

        result = sbl.getBadgeFromId("nonexistent_badge")

        assert isinstance(result, list)
        assert len(result) == 0

    def test_get_badge_from_id_multiple_badges_returns_specific(self):
        """Test getting specific badge when multiple exist."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badges = [
            {"bid": "badge_001", "name": "Badge 1"},
            {"bid": "badge_002", "name": "Badge 2"},
            {"bid": "badge_003", "name": "Badge 3"},
        ]
        mock_supabase._table_data["badges"] = badges

        result = sbl.getBadgeFromId("badge_002")

        assert isinstance(result, list)
        # Mock correctly filters by bid now
        assert len(result) == 1
        assert result[0]["bid"] == "badge_002"

    def test_get_badge_from_id_error_handling(self, capsys):
        """Test error handling in getBadgeFromId."""

        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("Database connection failed")

        sbl.supabase = ErrorSupabase()

        result = sbl.getBadgeFromId("badge_001")

        assert isinstance(result, dict)
        assert result["status"] == "error"
        captured = capsys.readouterr()
        assert "CHECKPOINT FAILURE getBadge" in captured.out


class TestCheckBadgeEarned:
    """Test the checkBadgeEarned async function."""

    def setup_method(self):
        """Reset mock supabase before each test."""
        sbl.supabase = MockSupabase()

    def test_check_badge_earned_true(self):
        """Test checking a badge that has been earned."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badge_earned = {"uid": "user123", "bid": "badge_001", "earned_at": "2024-01-01"}
        mock_supabase._table_data["badges_earned"] = [badge_earned]

        result = asyncio.run(sbl.checkBadgeEarned("user123", "badge_001"))

        assert result is True

    def test_check_badge_earned_false(self):
        """Test checking a badge that hasn't been earned."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges_earned"] = []

        result = asyncio.run(sbl.checkBadgeEarned("user123", "badge_001"))

        assert result is False

    def test_check_badge_earned_different_badge_no_match(self):
        """Test checking a badge when user has other badges but not this one."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badges_earned = [
            {"uid": "user123", "bid": "badge_001", "earned_at": "2024-01-01"},
            {"uid": "user123", "bid": "badge_002", "earned_at": "2024-01-02"},
        ]
        mock_supabase._table_data["badges_earned"] = badges_earned

        result = asyncio.run(sbl.checkBadgeEarned("user123", "badge_999"))

        assert result is False

    def test_check_badge_earned_different_user_no_match(self):
        """Test checking badge with different user."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        badges_earned = [
            {"uid": "user1", "bid": "badge_001", "earned_at": "2024-01-01"}
        ]
        mock_supabase._table_data["badges_earned"] = badges_earned

        result = asyncio.run(sbl.checkBadgeEarned("user2", "badge_001"))

        assert result is False

    def test_check_badge_earned_error_handling(self, capsys):
        """Test error handling in checkBadgeEarned."""

        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("Connection timeout")

        sbl.supabase = ErrorSupabase()

        result = asyncio.run(sbl.checkBadgeEarned("user123", "badge_001"))

        assert isinstance(result, dict)
        assert result["status"] == "error"
        captured = capsys.readouterr()
        assert "CHECKPOINT FAILURE checkBadgeEarned" in captured.out

    def test_check_badge_earned_multiple_matches_returns_true(self):
        """Test that multiple matching records return True."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        # Multiple records (shouldn't happen in practice)
        badges_earned = [
            {"uid": "user123", "bid": "badge_001", "earned_at": "2024-01-01"},
            {"uid": "user123", "bid": "badge_001", "earned_at": "2024-01-02"},
        ]
        mock_supabase._table_data["badges_earned"] = badges_earned

        result = asyncio.run(sbl.checkBadgeEarned("user123", "badge_001"))

        assert result is True

    def test_check_badge_earned_empty_data_list(self):
        """Test with explicitly empty data list."""
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        # Response has data=[] which is falsy
        result = asyncio.run(sbl.checkBadgeEarned("user123", "badge_001"))

        assert result is False


class TestCheckMediaBadgeFunctions:
    """Test media badge existence/earned helpers."""

    def setup_method(self):
        sbl.supabase = MockSupabase()

    def test_check_media_badge_exists_true(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = [{"bid": "b1", "media_id": "movie123"}]

        result = asyncio.run(sbl.checkMediaBadgeExists("movie123"))

        assert result is True

    def test_check_media_badge_exists_false(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        result = asyncio.run(sbl.checkMediaBadgeExists("movie404"))

        assert result is False

    def test_check_media_badge_exists_error(self, capsys):
        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("db failure")

        sbl.supabase = ErrorSupabase()

        result = asyncio.run(sbl.checkMediaBadgeExists("movie123"))

        assert result["status"] == "error"
        assert "db failure" in result["message"]
        assert "CHECKPOINT FAILURE checkMediaBadgeExists" in capsys.readouterr().out

    def test_check_media_badge_earned_true(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = [
            {"bid": "badge_10", "media_id": "movie123"}
        ]
        mock_supabase._table_data["badges_earned"] = [
            {"uid": "user1", "bid": "badge_10", "earned_at": "2024-01-01"}
        ]

        result = asyncio.run(sbl.checkMediaBadgeEarned("user1", "movie123"))

        assert result is True

    def test_check_media_badge_earned_false_when_not_earned(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = [
            {"bid": "badge_10", "media_id": "movie123"}
        ]
        mock_supabase._table_data["badges_earned"] = []

        result = asyncio.run(sbl.checkMediaBadgeEarned("user1", "movie123"))

        assert result is False

    def test_check_media_badge_earned_false_when_badge_missing(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase

        result = asyncio.run(sbl.checkMediaBadgeEarned("user1", "movie_missing"))

        assert result is False

    def test_check_media_badge_earned_error(self, capsys):
        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("query failed")

        sbl.supabase = ErrorSupabase()

        result = asyncio.run(sbl.checkMediaBadgeEarned("user1", "movie123"))

        assert result["status"] == "error"
        assert "query failed" in result["message"]
        assert "CHECKPOINT FAILURE checkMediaBadgeEarned" in capsys.readouterr().out


class TestCreateAndPostMediaBadges:
    """Test creation and posting flow for media badges."""

    def setup_method(self):
        sbl.supabase = MockSupabase()

    def test_create_badge_for_media_book_movie_show(self):
        inserted = []

        class CaptureBuilder(MockQueryBuilder):
            def insert(self, data):
                inserted.append(data)
                return self

            def execute(self):
                return MockResponse([{"ok": True}], None)

        class CaptureSupabase(MockSupabase):
            def table(self, name):
                return CaptureBuilder(name)

        sbl.supabase = CaptureSupabase()

        result_book = asyncio.run(
            sbl.createBadgeForMedia("book111", "Book Name", "img1")
        )
        result_movie = asyncio.run(
            sbl.createBadgeForMedia("movie111", "Movie Name", "img2")
        )
        result_tv = asyncio.run(sbl.createBadgeForMedia("tv111", "Show Name", "img3"))

        assert result_book["status"] == "success"
        assert result_movie["status"] == "success"
        assert result_tv["status"] == "success"
        assert inserted[0]["type"] == "book"
        assert inserted[1]["type"] == "movie"
        assert inserted[2]["type"] == "show"

    def test_create_badge_for_media_error(self, capsys):
        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("insert failed")

        sbl.supabase = ErrorSupabase()

        result = asyncio.run(sbl.createBadgeForMedia("movie222", "X", "Y"))

        assert result["status"] == "error"
        assert "insert failed" in result["message"]
        assert "CHECKPOINT FAILURE createBadgeForMedia" in capsys.readouterr().out

    def test_post_media_badge_earned_create_then_post(self, monkeypatch):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = [
            {"bid": "badge_1", "media_id": "movie123"}
        ]

        monkeypatch.setattr(sbl, "checkMediaBadgeExists", AsyncMock(return_value=False))
        monkeypatch.setattr(
            sbl, "createBadgeForMedia", AsyncMock(return_value={"status": "success"})
        )
        monkeypatch.setattr(
            sbl,
            "postNewBadgeEarned",
            lambda payload: {
                "status": "success",
                "table": "badges_earned",
                "payload": payload,
            },
        )

        result = asyncio.run(sbl.postMediaBadgeEarned("u1", "movie123", "M", "img"))

        assert result["status"] == "success"
        assert result["payload"]["uid"] == "u1"
        assert result["payload"]["bid"] == "badge_1"

    def test_post_media_badge_earned_existing_badge(self, monkeypatch):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = [
            {"bid": "badge_2", "media_id": "movie124"}
        ]

        monkeypatch.setattr(sbl, "checkMediaBadgeExists", AsyncMock(return_value=True))
        monkeypatch.setattr(
            sbl,
            "postNewBadgeEarned",
            lambda payload: {"status": "success", "payload": payload},
        )

        result = asyncio.run(sbl.postMediaBadgeEarned("u1", "movie124", "M", "img"))

        assert result["status"] == "success"
        assert result["payload"]["bid"] == "badge_2"

    def test_post_media_badge_earned_missing_bid_after_create(self, monkeypatch):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = []

        monkeypatch.setattr(sbl, "checkMediaBadgeExists", AsyncMock(return_value=False))
        monkeypatch.setattr(
            sbl, "createBadgeForMedia", AsyncMock(return_value={"status": "success"})
        )

        result = asyncio.run(sbl.postMediaBadgeEarned("u1", "movie404", "M", "img"))

        assert result["status"] == "error"
        assert "could not find badge for media_id movie404" in result["message"]

    def test_post_media_badge_earned_error(self, monkeypatch, capsys):
        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("post flow error")

        sbl.supabase = ErrorSupabase()
        monkeypatch.setattr(sbl, "checkMediaBadgeExists", AsyncMock(return_value=True))

        result = asyncio.run(sbl.postMediaBadgeEarned("u1", "movie123", "M", "img"))

        assert result["status"] == "error"
        assert "post flow error" in result["message"]
        assert "CHECKPOINT FAILURE postMediaBadgeEarned" in capsys.readouterr().out


class TestGetBadgeWithMediaIdAndYear:
    """Test media-id lookup and yearly badge retrieval."""

    def setup_method(self):
        sbl.supabase = MockSupabase()

    def test_get_badge_with_media_id_found(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges"] = [
            {"bid": "b1", "media_id": "movie1", "name": "Badge"}
        ]

        result = asyncio.run(sbl.getBadgeWithMediaId("movie1"))

        assert result["bid"] == "b1"
        assert result["media_id"] == "movie1"

    def test_get_badge_with_media_id_not_found(self):
        sbl.supabase = MockSupabase()

        result = asyncio.run(sbl.getBadgeWithMediaId("missing"))

        assert result["status"] == "error"
        assert "No badge found for media_id: missing" in result["message"]

    def test_get_badge_with_media_id_error(self, capsys):
        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("lookup failed")

        sbl.supabase = ErrorSupabase()

        result = asyncio.run(sbl.getBadgeWithMediaId("movie1"))

        assert result["status"] == "error"
        assert "lookup failed" in result["message"]
        assert "CHECKPOINT FAILURE getBadgeWithMediaId" in capsys.readouterr().out

    def test_get_badges_earned_in_year_filters_and_maps_badges(self):
        mock_supabase = MockSupabase()
        sbl.supabase = mock_supabase
        mock_supabase._table_data["badges_earned"] = [
            {"uid": "u1", "bid": "b1", "earned_at": "2025-01-15"},
            {"uid": "u1", "bid": "b2", "earned_at": "2025-12-31"},
            {"uid": "u1", "bid": "b3", "earned_at": "2024-12-31"},
            {"uid": "u2", "bid": "b4", "earned_at": "2025-02-01"},
        ]
        mock_supabase._table_data["badges"] = [
            {"bid": "b1", "name": "Badge 1"},
            {"bid": "b2", "name": "Badge 2"},
            {"bid": "b3", "name": "Badge 3"},
            {"bid": "b4", "name": "Badge 4"},
        ]

        result = asyncio.run(sbl.getBadgesEarnedInYear("u1", "2025"))

        assert isinstance(result, list)
        assert [badge["bid"] for badge in result] == ["b1", "b2"]

    def test_get_badges_earned_in_year_error(self, capsys):
        class ErrorSupabase(MockSupabase):
            def table(self, name):
                raise Exception("year query failed")

        sbl.supabase = ErrorSupabase()

        result = asyncio.run(sbl.getBadgesEarnedInYear("u1", "2025"))

        assert result["status"] == "error"
        assert "year query failed" in result["message"]
        assert "CHECKPOINT FAILURE getBadgesEarnedInYear" in capsys.readouterr().out
