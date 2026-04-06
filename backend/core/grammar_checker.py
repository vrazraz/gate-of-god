from loguru import logger

_tool = None


def _get_tool():
    global _tool
    if _tool is None:
        try:
            import language_tool_python
            _tool = language_tool_python.LanguageTool("en-US")
            logger.info("LanguageTool initialized successfully")
        except Exception as e:
            logger.warning(f"Could not initialize LanguageTool: {e}")
    return _tool


def check_grammar(text: str) -> list[dict]:
    """
    Check grammar of the given text using LanguageTool.

    Returns list of error dicts with keys: message, offset, length, replacements, rule_id.
    """
    tool = _get_tool()
    if tool is None:
        return []

    try:
        matches = tool.check(text)
        return [
            {
                "message": m.message,
                "offset": m.offset,
                "length": m.errorLength,
                "replacements": m.replacements[:3] if m.replacements else [],
                "rule_id": m.ruleId,
            }
            for m in matches
        ]
    except Exception as e:
        logger.error(f"Grammar check failed: {e}")
        return []


def is_grammatically_correct(text: str) -> bool:
    errors = check_grammar(text)
    return len(errors) == 0
