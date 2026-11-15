"""Package the exact validated P0/P1 snapshot; unrelated primary-checkout WIP is allowed.
No export, Git mutation, asset generation or network access is performed here.
"""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
from zipfile import ZipFile,ZIP_DEFLATED
ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'builds/living-world-foundation-final'
SOURCE=ROOT/'builds/source-snapshot-6506321'
PROFILE=ROOT/'tools/qa-data/living2-final-living-world/Godot/app_userdata/OUTLAW SYNDICATE/living-world-verification'

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def checked(path,marker):
    text=path.read_text(encoding='utf-8-sig',errors='replace')
    if marker not in text or re.search(r'^(FAIL |SCRIPT ERROR:|ERROR:)',text,re.M):raise RuntimeError('Incomplete/failing validation: '+str(path))
    return len(re.findall(r'^PASS ',text,re.M))
def main():
    source_commit=(SOURCE/'SOURCE_COMMIT.txt').read_text().strip()
    source_passes=checked(ROOT/'tools/living2-final-source.log','LIVING_WORLD_VALIDATION')
    results={}
    for route,marker in {'urban':'URBAN_VALIDATION','living-world':'LIVING_WORLD_VALIDATION','mission':'physical mission route completes and rewards once','mobility':'MOBILITY_VALIDATION','ragdoll':'RAGDOLL_VALIDATION','metropolis':'METROPOLIS RESULTS'}.items():
        results[route]=checked(ROOT/f'tools/living2-final-{route}.log',marker)
    for name in ['evidence','validation','licenses']:(BUILD/name).mkdir(parents=True,exist_ok=True)
    from PIL import Image
    for path in PROFILE.glob('*.png'):
        with Image.open(path) as image:
            if image.size!=(1920,1080):raise RuntimeError('Capture is not native 1080p: '+str(path))
        shutil.copy2(path,BUILD/'evidence'/path.name)
    performance=json.loads((PROFILE/'performance.json').read_text())
    if any(row['render_size']!=[1920,1080] for row in performance.values()):raise RuntimeError('Unverified render dimensions')
    shutil.copy2(PROFILE/'performance.json',BUILD/'evidence/performance.json')
    for path in (ROOT/'assets/licenses').iterdir():
        if path.is_file():shutil.copy2(path,BUILD/'licenses'/path.name)
    for path in (ROOT/'tools').glob('living2-final-*.log'):shutil.copy2(path,BUILD/'validation'/path.name)
    for name in ['OPERATION_VEYRA_LIVING_WORLD_PROGRESS.md','asset-licenses.md']:shutil.copy2(ROOT/'docs'/name,BUILD/name)
    manifest={'source_commit':source_commit,'metadata_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'engine':'Godot 4.6 / Jolt','source_passes':source_passes,'windows_passes':results,'performance':performance,'pck_sha256':sha(BUILD/'OutlawSyndicate.pck'),'exe_sha256':sha(BUILD/'OutlawSyndicate.exe'),'scope':'P0/P1 persistent 36-citizen foundation, voiced contacts and staffed cafe; two traffic cars','traffic_experiment':'NOT INCLUDED in committed snapshot or this executable','human_playtest':'NOT RUN','limitations':'Seven texture RID shutdown warnings. Further law, home, ownership, jobs, factions and Mission 02 remain unfinished.'}
    (BUILD/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    archive=ROOT/'builds/OutlawSyndicate-Living-World-Foundation-Windows-x64.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=6) as output:
        for path in BUILD.rglob('*'):
            if path.is_file():output.write(path,Path(BUILD.name)/path.relative_to(BUILD))
    with ZipFile(archive) as check:
        if check.testzip() is not None:raise RuntimeError('Archive CRC failed')
    print(json.dumps({'source':source_commit,'source_passes':source_passes,'windows_passes':results,'archive':str(archive),'bytes':archive.stat().st_size},indent=2))
if __name__=='__main__':main()
