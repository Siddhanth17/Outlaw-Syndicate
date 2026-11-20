"""Capture/verify the exact gameplay files used by a Windows export, independent of later report edits."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[1]
def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()
def current():
    files=[ROOT/'project.godot',ROOT/'export_presets.cfg']
    for directory in ['assets','data','scenes','scripts','shaders','tests']:
        files.extend(p for p in (ROOT/directory).rglob('*') if p.is_file())
    return {p.relative_to(ROOT).as_posix():digest(p) for p in sorted(files)}
target=ROOT/sys.argv[2]
if sys.argv[1]=='capture':
    target.write_text(json.dumps(current(),indent=2),encoding='utf-8')
    print('Captured gameplay source hashes:',target)
else:
    expected=json.loads(target.read_text(encoding='utf-8'))
    actual=current()
    changed=[p for p in expected.keys()|actual.keys() if expected.get(p)!=actual.get(p)]
    if changed:raise SystemExit('Gameplay files changed after export: '+', '.join(changed))
    print('All',len(actual),'gameplay source hashes match the validated export')
