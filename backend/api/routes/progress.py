from fastapi import APIRouter

from models.schemas import (
    SaveProgressRequest,
    SaveProgressResponse,
    PlayerProgressResponse,
    PlayerInfo,
    PlayerStats,
    VocabularyInfo,
)

router = APIRouter()


@router.get("/player/{player_id}/progress", response_model=PlayerProgressResponse)
async def get_progress(player_id: str):
    # TODO: Fetch from database when connected
    return PlayerProgressResponse(
        player=PlayerInfo(
            id=player_id,
            display_name="Player",
            cefr_level="B1",
            insight_points=0,
            runs_completed=0,
            stats=PlayerStats(),
        ),
        vocabulary=VocabularyInfo(),
        runs=[],
    )


@router.post("/player/{player_id}/progress", response_model=SaveProgressResponse)
async def save_progress(player_id: str, req: SaveProgressRequest):
    # TODO: Save to database when connected
    return SaveProgressResponse(saved=True, player_updated=True)
