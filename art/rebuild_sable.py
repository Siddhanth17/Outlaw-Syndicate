import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from build_assets import car
car()
