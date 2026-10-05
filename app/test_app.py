import unittest
from unittest.mock import MagicMock

from app import Handler


class TestApplication(unittest.TestCase):

    def test_health_endpoint(self):
        handler = Handler.__new__(Handler)
        handler.path = "/health"
        handler.send_response = MagicMock()
        handler.end_headers = MagicMock()
        handler.wfile = MagicMock()

        handler.do_GET()

        handler.send_response.assert_called_once_with(200)
        handler.wfile.write.assert_called_once_with(b"OK")


if __name__ == "__main__":
    unittest.main()
