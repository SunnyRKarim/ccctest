"""CCC tests and diagnostics. Importing performs no analysis or global mutation."""
from .core import CCCResult, ccc_test, holm_two, select_specification
from .trends import TrendResult, ccc_trends
__all__ = ['CCCResult', 'TrendResult', 'ccc_test', 'ccc_trends', 'holm_two', 'select_specification']
