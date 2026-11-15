"""Materialize an exact committed game/test source tree without touching local WIP.
LFS pointers are expanded only when the working asset hash matches the commit.
The original ignored export templates are copied; engine/tool installs stay outside.
"""
from pathlib import Path
import hashlib,io,shutil,subprocess,tarfile
ROOT=Path(__file__).resolve().parents[1]
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
target=ROOT/'builds'/('source-snapshot-'+commit[:7])
target.mkdir(parents=True,exist_ok=True)
archive=subprocess.check_output(['git','archive','--format=tar',commit,'project.godot','export_presets.cfg','assets','data','scenes','scripts','shaders','tests'],cwd=ROOT)
with tarfile.open(fileobj=io.BytesIO(archive)) as source:
    source.extractall(target,filter='data')
for path in target.rglob('*'):
    if not path.is_file() or path.stat().st_size>1024:continue
    blob=path.read_bytes()
    if not blob.startswith(b'version https://git-lfs.github.com/spec/v1'):continue
    expected=next(line.split(b':',1)[1].decode() for line in blob.splitlines() if line.startswith(b'oid sha256:'))
    original=ROOT/path.relative_to(target)
    if hashlib.sha256(original.read_bytes()).hexdigest()!=expected:raise RuntimeError('Working asset differs from committed LFS pointer: '+str(original))
    shutil.copy2(original,path)
templates=target/'tools/templates';templates.mkdir(parents=True,exist_ok=True)
for name in ['windows_debug_x86_64.exe','windows_release_x86_64.exe']:shutil.copy2(ROOT/'tools/templates'/name,templates/name)
(target/'tools/.gdignore').touch()
(target/'SOURCE_COMMIT.txt').write_text(commit+'\n')
print(target)
