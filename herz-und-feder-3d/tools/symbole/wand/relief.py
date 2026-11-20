# Symbole der Fähigkeiten als bemaltes Relief (Fassung 4.0.5): die Zeichen aus zeichen.py erhaben aus dem Stein, Licht und Schatten, Blattgold, Schein, erhabener Rahmen.
import sys, io, zlib, numpy as np, cairosvg
from PIL import Image, ImageFilter
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zeichen as W_
from zeichen import I, ZU, KLASSE, hexf, N, x, y, alpha, inner
def weich(a,r): return W_.weich(a,r)
def licht(h,kraft,L=(-0.5,-0.65,0.58),ex=30):
    dx=(np.roll(h,-1,1)-np.roll(h,1,1))*kraft; dy=(np.roll(h,-1,0)-np.roll(h,1,0))*kraft
    n=np.dstack([-dx,-dy,np.ones_like(h)]); n/=np.linalg.norm(n,axis=2,keepdims=True)
    L=np.array(L); L/=np.linalg.norm(L); H=L+np.array([0,0,1.0]); H/=np.linalg.norm(H)
    return np.clip((n*L).sum(2),0,1), np.clip((n*H).sum(2),0,1)**ex, n
SKALA={"salve":0.8}
def relief(id_, skala=None):
    skala=skala or SKALA.get(id_,0.9)
    W_.rng=np.random.default_rng(zlib.crc32(id_.encode())); R=W_.rauschen
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56" width="{N}" height="{N}"><g transform="translate(28 28) scale({skala}) translate(-28 -28)">{I[id_]}</g></svg>'
    g=np.asarray(Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")).astype(np.float32)
    rgb,a=g[...,:3],g[...,3]/255
    kc=hexf(KLASSE[ZU.get(id_,"")])
    # Grund: Sandstein, zur Mitte hin vom Schein erhellt, außen tief und in die Klassenfarbe getaucht
    r=np.sqrt((x-0.5)**2+(y-0.47)**2)
    stein=hexf("#d2aa6c")*(0.9+0.07*R(8)[...,None]+0.06*R(1.4)[...,None])
    stein=stein*(1-0.62*np.clip(r/0.62,0,1)[...,None]**1.6)+kc*0.28*np.clip(r/0.62,0,1)[...,None]**2
    schein=weich(a,26)*1.4+np.clip(1-r/0.42,0,1)**2*0.5
    stein=stein+np.array([255,205,120])*np.clip(schein,0,1)[...,None]*0.32
    # Höhenfeld: Figur erhaben mit gerundeter Kante, Kontur leicht tiefer (eingeschnitten), Stein mit Korn
    form=a
    kontur=np.clip(1-(rgb.sum(2)/3)/70,0,1)*a           # schwarze Linien
    h=weich(form,3.5)*0.9+weich(form,1.2)*0.35-kontur*0.18+R(2)*0.01+R(10)*0.015
    rahmen=np.exp(-((inner-0.04)/0.016)**2)
    h=h+rahmen*0.7
    dif,sp,n=licht(h,16)
    # Schlagschatten von Figur und Rahmen auf den Stein
    erh=np.clip(weich(form,2)+rahmen,0,1)
    schatten=np.clip(np.roll(np.roll(weich(erh,7),12,0),9,1)-erh,0,1)
    ao=np.clip(weich(h,10)-h,0,None)
    hell=(0.42+0.75*dif)*(1-0.55*schatten)*(1-1.2*ao)
    grund=stein*hell[...,None]+255*0.05*sp[...,None]
    # Farbe der Figur, kräftiger gesättigt, mit Licht; Gelbocker wird Blattgold
    f=rgb.copy(); grau=f.mean(2,keepdims=True); f=np.clip(grau+(f-grau)*1.25,0,255)
    gold=np.clip(1-np.abs(rgb-hexf("#dca545")).sum(2)/60,0,1)*a
    farbe=f*(0.5+0.65*dif[...,None])*(1-0.6*ao[...,None])+255*sp[...,None]*0.18
    himmel=np.clip(-n[...,1]*0.9+0.3,0,1)[...,None]
    au=hexf("#d9a441")*(0.3+0.9*dif[...,None])+np.array([255,240,200])*(sp[...,None]**0.6)*0.85+np.array([255,225,160])*himmel*0.2
    au=au*(0.85+0.2*weich(W_.rng.random((N,N)).astype(np.float32),1.5)[...,None])
    farbe=farbe*(1-gold[...,None])+au*gold[...,None]
    # Abrieb: Farbe an Kanten und Stellen abgeplatzt, Stein darunter
    abrieb=np.clip(R(4)-1.7,0,1)*0.7*a
    farbe=farbe*(1-abrieb[...,None])+grund*abrieb[...,None]
    b=grund*(1-a[...,None])+farbe*a[...,None]
    # Rahmen: Gold, innen ein Band in der Klassenfarbe
    rd,rs,_=licht(weich(rahmen,1.0)*1.2,14)
    rg=hexf("#c99a3c")*(0.3+0.9*rd[...,None])+np.array([255,240,200])*rs[...,None]*0.9
    b=b*(1-np.clip(rahmen*1.4,0,1)[...,None])+rg*np.clip(rahmen*1.4,0,1)[...,None]
    band=np.exp(-((inner-0.072)/0.007)**2)
    b=b*(1-band[...,None]*0.85)+kc*1.05*band[...,None]*0.85
    risse=np.clip(1-np.abs(R(16))/0.012,0,1)*0.18*np.clip(R(40)+0.3,0,1); b*=(1-risse[...,None])
    b*=(1-0.35*np.clip((r-0.38)/0.35,0,1)**2)[...,None]
    return Image.fromarray(np.dstack([np.clip(b,0,255),alpha*255]).astype(np.uint8),"RGBA")
# Aufruf: python3 relief.py [Zielordner] [Zeichen …]   (Standard: ui/symbole, alle; braucht cairosvg)
if __name__=="__main__":
    ziel=sys.argv[1] if len(sys.argv)>1 else os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","..","..","ui","symbole")
    for i in (sys.argv[2:] or list(I)):
        relief(i).resize((256,256),Image.LANCZOS).save(os.path.join(ziel,i+".webp"),quality=92,method=6); print(i,end=" ")
    print()
