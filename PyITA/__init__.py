# PyITA/__init__.py

try:
    from ITA import generateTestVectors, util_main
    from run_reference_model import run_reference_model   # ← Add this line
except ImportError as e:
    print(f"Warning: Some ITA modules could not be imported: {e}")
    # Fallback for old NumPy
    import warnings
    warnings.warn("numpy.typing not available - using compatibility mode")
