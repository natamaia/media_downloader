import json
from src.backend.mobile_bridge import extract_metadata_json, mobile_manager

def test_extract_metadata_invalid_url():
    res_str = extract_metadata_json("not-a-valid-url")
    data = json.loads(res_str)
    assert "success" in data
    # Should report failure gracefully rather than crash
    assert data["success"] is False
    assert "error" in data

def test_mobile_manager_instantiation():
    assert mobile_manager is not None
    assert isinstance(mobile_manager._workers, dict)
