"""
Tests for WorkerOrchestrator and Worker Lifecycle
"""

import time
from src.backend.orchestrator import WorkerOrchestrator
from src.backend.models import FormatType, WorkerStatus

def test_orchestrator_initialization():
    orch = WorkerOrchestrator(max_concurrency=2)
    assert orch.get_active_count() == 0
    assert len(orch.list_downloads()) == 0

def test_callback_registration():
    orch = WorkerOrchestrator(max_concurrency=2)
    events = []

    def callback(worker):
        events.append(worker.download_id)

    orch.register_update_callback(callback)
    assert callback in orch._update_callbacks

    orch.unregister_update_callback(callback)
    assert callback not in orch._update_callbacks

def test_orchestrator_clear():
    orch = WorkerOrchestrator(max_concurrency=2)
    count = orch.clear_finished_downloads()
    assert count == 0

def test_clean_files_on_disk(tmp_path):
    from src.backend.orchestrator import clean_files_on_disk
    # Create test files
    out_dir = str(tmp_path)
    f1 = tmp_path / "My Song - Artist.mp3"
    f1.write_text("dummy audio")
    f2 = tmp_path / "My Song - Artist.webm.part"
    f2.write_text("dummy part")
    f3 = tmp_path / "Other File.txt"
    f3.write_text("unrelated")

    # Clean files by exact path
    deleted = clean_files_on_disk(file_path=str(f1), output_dir=out_dir, title="My Song - Artist")
    assert not f1.exists()
    assert not f2.exists()
    assert f3.exists()

def test_delete_download_with_hints(tmp_path):
    from src.backend.orchestrator import WorkerOrchestrator
    orch = WorkerOrchestrator(max_concurrency=2)
    
    # Create dummy video file
    video_file = tmp_path / "Test Video.mp4"
    video_file.write_text("dummy video")
    
    # Run delete_download with hints even if worker is not in memory
    res = orch.delete_download(
        download_id="dl_nonexistent",
        file_path_hint=str(video_file),
        output_dir_hint=str(tmp_path),
        title_hint="Test Video"
    )
    assert res is True
    assert not video_file.exists()

