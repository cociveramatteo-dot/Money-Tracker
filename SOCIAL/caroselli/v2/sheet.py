import sys
from PIL import Image
from pathlib import Path
d=Path(sys.argv[1]); out=sys.argv[2]
fs=sorted(d.glob('slide-*.png'))
cols=4; W,H=540,675
rows=(len(fs)+cols-1)//cols
sh=Image.new('RGB',(W*cols,H*rows),'white')
for i,f in enumerate(fs):
    sh.paste(Image.open(f).convert('RGB').resize((W,H)),((i%cols)*W,(i//cols)*H))
sh.save(out)
