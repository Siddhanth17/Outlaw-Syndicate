"""Package only validated Veyra III gameplay with native evidence and exact provenance."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess
from zipfile import ZipFile,ZIP_DEFLATED
ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'builds/operation-veyra-iii-release'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def gate(name,marker):
    p=ROOT/'tools'/name
    data=p.read_text(encoding='utf-8-sig',errors='replace')
    if marker not in data or re.search(r'^(FAIL |SCRIPT ERROR:|ERROR:)',data,re.M):raise RuntimeError('Failed or incomplete gate: '+name)
    return len(re.findall(r'^PASS ',data,re.M))
def copy_profile(folder,target):
    source=ROOT/'tools/qa-data'/folder/'Godot/app_userdata/OUTLAW SYNDICATE'
    for path in source.rglob('*'):
        if path.is_file() and path.suffix in ['.png','.json','.wav'] and 'verification' in str(path.parent):
            dest=BUILD/target/path.relative_to(source);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
def main():
    subprocess.run(['python','tools/veyra3_source_manifest.py','verify',str((BUILD/'source-hashes.json').relative_to(ROOT))],cwd=ROOT,check=True)
    results={}
    for route,marker in [('home','physical mission route completes and rewards once'),('veyra3','VEYRA3_VALIDATION'),('living-world','LIVING_WORLD_VALIDATION'),('urban','URBAN_VALIDATION')]:
        results[route]=gate('veyra3-final-exe-'+route+'.log',marker)
        copy_profile('veyra3-final-'+route,'evidence')
    for route,marker in [('physics','PHYSICS_VALIDATION'),('ragdoll','RAGDOLL_VALIDATION'),('mobility','MOBILITY_VALIDATION'),('metropolis','METROPOLIS RESULTS'),('network','NETWORK_VALIDATION')]:
        results[route]=gate('veyra3-accepted-'+route+'.log',marker)
    performance={}
    for period in ['day','night']:
        gate('veyra3-clean-'+period+'.log','EXPANSION_VALIDATION')
        copy_profile('veyra3-clean-'+period,'evidence/'+period)
        p=ROOT/f'tools/qa-data/veyra3-clean-{period}/Godot/app_userdata/OUTLAW SYNDICATE/expansion-verification/performance.json'
        performance[period]=json.loads(p.read_text(encoding='utf-8'))
        if performance[period]['seconds']<60:raise RuntimeError('Sustained route was too short')
    for folder in ['licenses','validation']:(BUILD/folder).mkdir(exist_ok=True)
    for path in (ROOT/'assets/licenses').iterdir():
        if path.is_file():shutil.copy2(path,BUILD/'licenses'/path.name)
    for pattern in ['veyra3-final-exe-*.log','veyra3-accepted-*.log','navigation-final-*.log','veyra3-sustained-*.log','veyra3-clean-*.log']:
        for path in (ROOT/'tools').glob(pattern):shutil.copy2(path,BUILD/'validation'/path.name)
    for name in ['OPERATION_VEYRA_III_PROGRESS.md','asset-licenses.md']:
        shutil.copy2(ROOT/'docs'/name,BUILD/name)
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    manifest={'source_commit':commit,'engine':'Godot 4.6 / Jolt','windows_checks':results,'performance':performance,'exe_sha256':sha(BUILD/'OutlawSyndicate.exe'),'pck_sha256':sha(BUILD/'OutlawSyndicate.pck'),'human_listening_review':'NOT RUN','human_extended_playtest':'NOT RUN','status':'PARTIAL overall; validated home, movement, connected roads and six-car core','limitations':['Prototype home/character/environment art','General traffic incident recovery incomplete','Seven texture RID shutdown warnings','Audio DSP CPU not measured','Police/ownership/economy/factions/Mission 02 unfinished']}
    (BUILD/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (BUILD/'START-HERE.txt').write_text('OUTLAW SYNDICATE / VEYRA III\n\nRun OutlawSyndicate.exe beside its .pck. Choose New game to start in Adrian\'s home at 08:00; Continue preserves your checkpoint.\n\nWASD move/drive, mouse look, E interact, Tab phone, Esc pause/controls, F5 save, F9 load.\nHome: desk saves, bed rests, wardrobe changes jacket, chest stores food. Exit through the working front door. Story activation is optional in Phone > Messages. Sable and Harrier are at Cross Motor Works in Iron Harbor. Phone > Map shows connected west/east areas and home.\n\nSee build-manifest.json, evidence, validation and the progress report for measured results and limitations. Art/audio remain prototype/partial.\n',encoding='utf-8')
    archive=ROOT/'builds/OutlawSyndicate-Operation-Veyra-III-Windows-x64.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=6) as output:
        for p in BUILD.rglob('*'):
            if p.is_file() and p.suffix!='.avi':output.write(p,Path(BUILD.name)/p.relative_to(BUILD))
    with ZipFile(archive) as check:
        if check.testzip():raise RuntimeError('ZIP CRC failed')
    print(json.dumps({'commit':commit,'archive':str(archive),'bytes':archive.stat().st_size,'windows_checks':results,'performance':performance},indent=2))
if __name__=='__main__':main()
