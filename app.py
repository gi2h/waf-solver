from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict
import logging
import uuid
import asyncio
from contextlib import asynccontextmanager

from turnstile_solver1 import process_turnstile_and_cf

logging.basicConfig(level=logging.INFO, format="[api] %(message)s")
logger = logging.getLogger(__name__)

# --- QUEUE MANAGER (MAX 6 ANTREAN, MAX 2 BROWSER) ---
MAX_QUEUE_SIZE = 6
MAX_ACTIVE_BROWSERS = 2
queue = asyncio.Queue(maxsize=MAX_QUEUE_SIZE)
browser_semaphore = asyncio.Semaphore(MAX_ACTIVE_BROWSERS)
TASKS: Dict[str, dict] = {}

async def _process_queue():
    while True:
        task_id, url, sitekey = await queue.get()
        try:
            async with browser_semaphore:
                TASKS[task_id]["status"] = "processing"
                result = await process_turnstile_and_cf(url=url, sitekey=sitekey)
                TASKS[task_id]["status"] = "done"
                TASKS[task_id]["result"] = result["turnstile_token"]
                TASKS[task_id]["data"] = result
        except Exception as e:
            logger.error(f"Task {task_id} Error: {e}")
            TASKS[task_id]["status"] = "failed"
            TASKS[task_id]["error"] = str(e)
        finally:
            queue.task_done()
            logger.info(f"Task selesai. Sisa antrean: {queue.qsize()}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    worker = asyncio.create_task(_process_queue())
    logger.info(f"Queue Worker berjalan. (Max Antrean: {MAX_QUEUE_SIZE}, Max Browser: {MAX_ACTIVE_BROWSERS})")
    yield
    worker.cancel()

app = FastAPI(title="Ultimate Patchright Solver", lifespan=lifespan)

class SolveRequest(BaseModel):
    sitekey: str
    pageurl: str

@app.post("/v1/solve/turnstile")
async def submit_turnstile(req: SolveRequest):
    try:
        task_id = str(uuid.uuid4())
        TASKS[task_id] = {"status": "pending", "result": None, "data": None, "error": None}
        await queue.put((task_id, req.pageurl, req.sitekey))
        return {"id": task_id}
    except Exception as e:
        raise HTTPException(status_code=429, detail=str(e))

@app.get("/v1/tasks/{task_id}/wait")
async def wait_task(task_id: str, timeout: int = 100):
    if task_id not in TASKS:
        raise HTTPException(status_code=404, detail="Task ID tidak ditemukan")
        
    start = asyncio.get_event_loop().time()
    while asyncio.get_event_loop().time() - start < timeout:
        status = TASKS[task_id]["status"]
        if status == "done":
            return {"status": "done", "result": TASKS[task_id]["result"], "data": TASKS[task_id]["data"]}
        if status == "failed":
            return {"status": "failed", "error": TASKS[task_id]["error"]}
        await asyncio.sleep(1)
        
    return {"status": "timeout", "error": "Waktu tunggu habis"}

@app.get("/health")
async def health():
    return {"status": "ok", "queue_size": queue.qsize()}
