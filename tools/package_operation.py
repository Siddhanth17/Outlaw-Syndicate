"""Package verified local Operation Veyra build/evidence. Does not export or publish.
Run after tests, five exported routes, review and commit. Requires Pillow and
imageio-ffmpeg only for encoding the unaltered sampled viewport sequence.
"""
from pathlib import Path
import hashlib, json, re, shutil, subprocess
from zipfile import ZipFile, ZIP_DEFLATED

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'builds/operation-veyra-architecture'
QA=ROOT/'tools/qa-data/operation-verified-urban/Godot/app_userdata/OUTLAW SYNDICATE/urban-verification'
BEFORE=ROOT/'tools/qa-data/operation-before-pack/Godot/app_userdata/OUTLAW SYNDICATE/urban-before'

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    dirty=subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True)
    if dirty.strip(): raise RuntimeError('Commit/review current changes before stamping source provenance.')
    results={}
    for route in ['urban','mission','mobility','ragdoll','metropolis']:
        path=ROOT/f'tools/operation-verified-{route}.log'
        content=path.read_text(encoding='utf-8-sig',errors='replace')
        if re.search(r'^(FAIL |SCRIPT ERROR:|ERROR:)',content,re.M): raise RuntimeError(f'{route}: inspect failures')
        completion={'urban':'URBAN_VALIDATION','mission':'physical mission route completes and rewards once','mobility':'MOBILITY_VALIDATION','ragdoll':'RAGDOLL_VALIDATION','metropolis':'METROPOLIS RESULTS'}[route]
        if completion not in content: raise RuntimeError(f'{route}: incomplete log')
        results[route]=len(re.findall(r'^PASS ',content,re.M))
    source=(ROOT/'tools/operation-verified-source.log').read_text(encoding='utf-8-sig',errors='replace')
    if re.search(r'^(FAIL |SCRIPT ERROR:|ERROR:)',source,re.M):raise RuntimeError('Inspect source failures')
    for directory in ['evidence','validation','licenses']:(BUILD/directory).mkdir(parents=True,exist_ok=True)
    for image in QA.glob('*.png'):
        if not image.name.startswith('traffic-sequence-'):shutil.copy2(image,BUILD/'evidence'/image.name)
    for image in BEFORE.glob('*.png'):shutil.copy2(image,BUILD/'evidence'/image.name)
    shutil.copy2(QA/'performance.json',BUILD/'evidence/performance.json')
    for path in (ROOT/'assets/licenses').iterdir():
        if path.is_file():shutil.copy2(path,BUILD/'licenses'/path.name)
    for name in ['OPERATION_VEYRA_PROGRESS.md','operation-veyra-acceptance.md','asset-licenses.md']:
        shutil.copy2(ROOT/'docs'/name,BUILD/name)
    for path in (ROOT/'tools').glob('operation-verified-*.log'):
        shutil.copy2(path,BUILD/'validation'/path.name)
    # Each frame is a real unaltered viewport capture. 12 physics ticks apart -> 5fps.
    frames=sorted(QA.glob('traffic-sequence-*.png'))
    if not frames:raise RuntimeError('Missing actual recorded gameplay frames')
    from PIL import Image
    import imageio_ffmpeg
    with Image.open(frames[0]) as first:size=first.size
    if size!=(1920,1080):raise RuntimeError(f'Actual captures are {size}, not verified 1080p')
    performance=json.loads((QA/'performance.json').read_text())
    if (performance.get('render_width'),performance.get('render_height'))!=(1920,1080):raise RuntimeError('Unverified benchmark render dimensions')
    video=BUILD/'evidence/automated-traffic-sampled-silent.mp4'
    writer=imageio_ffmpeg.write_frames(str(video),size,fps=5,codec='libx264',pix_fmt_in='rgb24',pix_fmt_out='yuv420p',quality=7,macro_block_size=1,ffmpeg_log_level='error')
    writer.send(None)
    for path in frames:
        with Image.open(path) as image:
            if image.size!=size:raise RuntimeError(f'Mixed capture dimensions: {path.name} {image.size}')
            writer.send(image.convert('RGB').tobytes())
    writer.close()
    manifest={
        'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'engine':'Godot 4.6 stable / Jolt',
        'status':'PARTIAL Operation Veyra; bounded four-block architecture and city-system increment',
        'pck_sha256':digest(BUILD/'OutlawSyndicate.pck'),
        'exe_sha256':digest(BUILD/'OutlawSyndicate.exe'),
        'preserved_metropolis_pck_sha256':digest(ROOT/'builds/metropolis-foundation/OutlawSyndicate.pck'),
        'source_passes':len(re.findall(r'^PASS ',source,re.M)),
        'windows_passes':results,
        'performance':performance,
        'video':{'file':video.name,'frames':len(frames),'fps':5,'description':'sampled automated actual viewport, silent; test obstruction visible; not a human playthrough'},
        'human_20_30_minute_route':'NOT RUN',
        'limitations':'See progress report; seven texture RID warnings on Vulkan shutdown remain; no complete city/campaign claim'
    }
    (BUILD/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    archive=ROOT/'builds/OutlawSyndicate-Operation-Veyra-Architecture-Windows-x64.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=6) as output:
        for path in BUILD.rglob('*'):
            if path.is_file():output.write(path,Path(BUILD.name)/path.relative_to(BUILD))
    with ZipFile(archive) as check:
        if check.testzip() is not None:raise RuntimeError('Archive CRC failure')
    print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,'source':manifest['source_commit'],'source_passes':manifest['source_passes'],'windows_passes':results,'video_frames':len(frames)},indent=2))

if __name__=='__main__':main()
