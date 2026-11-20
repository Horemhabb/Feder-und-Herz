# Zeichen der Fähigkeiten (Fassung 4.0.5) als farbige SVG-Bilder im Stil ägyptischer Wandmalerei; relief.py macht daraus
# die Symbole. Dazu eine flache Fassung (ohne Relief): ägyptische Farben mit schwarzer Kontur auf Putz, Abrieb, Risse, Doppelrand in der Klassenfarbe.
import math, sys, io, numpy as np, cairosvg
from PIL import Image, ImageFilter
N=512; rng=np.random.default_rng(11)
K="#1d1712"; B="#2c64a0"; BD="#1c3c6c"; G="#3c8a58"; T="#3f9f98"; R="#b23e26"; Y="#dca545"; W="#efe5cc"; H="#a8552e"; BR="#7a4a26"; O="#c8622a"
def F(d,c,w=1.3): return f'<path d="{d}" fill="{c}" stroke="{K}" stroke-width="{w}" stroke-linejoin="round"/>'
def L(d,c,w=2.2,cap="round"): return (f'<path d="{d}" fill="none" stroke="{K}" stroke-width="{w+1.5}" stroke-linecap="{cap}" stroke-linejoin="round"/>'
                                      f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="{cap}" stroke-linejoin="round"/>')
def KL(d,w=1.1): return f'<path d="{d}" fill="none" stroke="{K}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
def C(x,y,r,c,w=1.2): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}" stroke="{K}" stroke-width="{w}"/>'
def D(x,y,r,c): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'
def E_(x,y,rx,ry,c,w=1.2): return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{c}" stroke="{K}" stroke-width="{w}"/>'
def spiegel(d): # x → 56−x für Pfade aus absoluten M/L/C/Q/Z-Befehlen mit Zahlenpaaren
    import re
    t=re.findall(r'[A-Za-z]|-?\d*\.?\d+',d); out=[]; i=0; xs=True
    for s in t:
        if s.isalpha(): out.append(s); xs=True
        else:
            v=float(s); out.append(f"{56-v:g}" if xs else s); xs=not xs
    return " ".join(out)
def stern(cx,cy,r1,r2,n=5,rot=-90):
    p=[]
    for i in range(2*n):
        r=r1 if i%2==0 else r2; a=math.radians(rot+i*180/n); p.append(f"{cx+r*math.cos(a):.2f} {cy+r*math.sin(a):.2f}")
    return "M"+" L".join(p)+"Z"
def pfeil(x0,y0,x1,y1,schaft=Y,spitze=B,feder=R,w=1.4):
    dx,dy=x1-x0,y1-y0; l=math.hypot(dx,dy); ux,uy=dx/l,dy/l; nx,ny=-uy,ux
    s=L(f"M{x0:.2f} {y0:.2f} L{x1-ux*3:.2f} {y1-uy*3:.2f}",schaft,w)
    s+=F(f"M{x1+ux*1.5:.2f} {y1+uy*1.5:.2f} L{x1-ux*4+nx*2.4:.2f} {y1-uy*4+ny*2.4:.2f} L{x1-ux*4-nx*2.4:.2f} {y1-uy*4-ny*2.4:.2f}Z",spitze,1.0)
    for sg in (1,-1):
        s+=F(f"M{x0+ux*1:.2f} {y0+uy*1:.2f} L{x0-ux*1.5+nx*2.6*sg:.2f} {y0-uy*1.5+ny*2.6*sg:.2f} L{x0+ux*4+nx*1.8*sg:.2f} {y0+uy*4+ny*1.8*sg:.2f} L{x0+ux*4:.2f} {y0+uy*4:.2f}Z",feder,0.9)
    return s

I={}
# ---------- Eidträger ----------
fl_o="M25 25 C17 14 9 12 3 15 C7 21 14 27 24 31 Z"; fl_m="M25 25 C19 18 13 16 8 17 C12 22 17 27 24 30 Z"; fl_i="M25 25 C21 21 17 20 14 20 C16 24 20 27 24 29 Z"
I["whirl"]=(L("M9 40 A20 7.5 0 1 0 46 37",R,2.0)+L("M46 37 L45 31.5 M46 37 L40.5 38",R,2.0)
  +"".join(F(p,c) for p,c in ((fl_o,G),(fl_m,B),(fl_i,R),(spiegel(fl_o),G),(spiegel(fl_m),B),(spiegel(fl_i),R)))
  +F("M25 40 L28 47 L31 40 Z",B)+F("M23 24 C23 31 24 37 28 42 C32 37 33 31 33 24 Z",Y)+KL("M25.5 30 h5 M26 34 h4",0.8)
  +C(28,19.5,5.2,W)+F("M22.8 19.5 A5.2 5.2 0 0 1 33.2 19.5 C31 18 29 18.5 28 20 C27 18.5 25 18 22.8 19.5Z",BD,1.0)
  +D(29.6,20.3,1.2,K)+KL("M29.2 21.5 l-0.8 2.6",0.9)+F("M31.8 20.5 L34.5 22.5 L31.5 23.5Z",Y,0.9))
I["dash"]=(L("M18 4 v9 M28 2 v8 M38 4 v9",R,1.3)
  +F("M27 27 L5 8 C12 11 18 15 23 19 Z",B)+F("M29 27 L51 8 C44 11 38 15 33 19 Z",B)
  +F("M5 8 C8 9.5 10 11 12 12.5 L9 13.5 Z",G,0.9)+F("M51 8 C48 9.5 46 11 44 12.5 L47 13.5 Z",G,0.9)
  +KL("M14 13 l4 6 M19 16 l3 5 M42 13 l-4 6 M37 16 l-3 5",0.8)
  +F("M22 18 C21 28 25 36 28 41 C31 36 35 28 34 18 C32 15 24 15 22 18Z",Y)+KL("M25 24 h6 M25.5 29 h5",0.8)
  +C(28,42,4.3,W)+F("M23.8 41 A4.3 4.3 0 0 1 32.2 41 C30.5 40 29 40.5 28 42 C27 40.5 25.5 40 23.8 41Z",BD,0.9)
  +D(29.3,43,1.0,K)+F("M27 45.5 L28.3 50 L29.8 45.5Z",Y,0.9)+L("M14 51 Q28 46 42 51",O,1.4))
fe="M28 50 C18 40 16 20 26 7 C30 4 35 6 35 11 C38 24 36 38 28 50 Z"
I["oath"]=(f'<clipPath id="fe"><path d="{fe}"/></clipPath>'+F(fe,W)
  +f'<g clip-path="url(#fe)"><rect x="10" y="13" width="40" height="4" fill="{B}"/><rect x="10" y="22" width="40" height="3" fill="{G}"/><rect x="10" y="31" width="40" height="4" fill="{B}"/><rect x="10" y="40" width="40" height="3" fill="{G}"/></g>'
  +F(fe,"none")+KL("M28 48 C27 34 27 22 30 10",1.2)+KL("M22 22l5 3M21 29l6 3M22 36l5 2M34 20l-5 4M35 28l-6 3M33 36l-5 2",0.6)
  +L("M22 46 L34 46",R,2.0)+L("M27 46 l-3 5 M29 46 l3 5",R,1.3))
I["udjat"]=(F("M6 19 Q24 6 48 16 L47.5 19.5 Q24 10.5 7 22.5Z",B)
  +F("M6.5 27 Q27 11 47 25.5 Q26 37.5 6.5 27Z",K,0.8)+F("M11 27 Q27 15.5 43 25.8 Q26 34 11 27Z",W,0.6)
  +C(27,25.8,5.2,"#9a6a2c",0.9)+D(27,25.8,2.3,K)+D(28.2,24.6,0.8,W)+L("M46 25.5 Q50 30 51.5 26.5",K,1.0)
  +L("M20 33 Q21 41 27 44.5 C33 47 37 43.5 35.5 39.5 C34.5 37 31 37.5 31.5 40",B,2.0)+L("M37 32.5 Q39 41 36 48",R,2.2)+F("M36 47 L38.5 50 L36 53 L33.5 50Z",R,1.0))
I["beam"]=("".join(L(f"M{28+6*math.cos(math.radians(a)):.2f} {15+6*math.sin(math.radians(a)):.2f} L{28+34*math.cos(math.radians(a)):.2f} {15+34*math.sin(math.radians(a)):.2f}",Y,1.5) for a in (55,70,90,110,125))
  +"".join(C(28+35.5*math.cos(math.radians(a)),15+35.5*math.sin(math.radians(a)),2.0,G,1.0) for a in (55,70,90,110,125))
  +C(28,15,9.5,Y,1.3)+C(28,15,7,R,1.0)+F("M24 6 C22 3 25 1 26.5 3 C27 5 25 6 26 8",G,1.0)+D(25.5,12.5,1.6,"#d9704a"))
# ---------- Jägerin ----------
s=L("M10 47 Q28 39 46 47",BR,2.0)
for a in (-52,-26,0,26,52):
    r=math.radians(a-90); s+=pfeil(28+4*math.cos(r),46+4*math.sin(r),28+38*math.cos(r),46+38*math.sin(r))
I["salve"]=s+C(28,46,3.4,W,1.1)+KL("M28 43 v6",0.8)
I["roll"]=(L("M6 50 Q20 45 30 49 Q40 52 50 47",O,1.3)
  +L("M17 32 L6 37",Y,1.6)+L("M19 34 L9 43",Y,1.6)+L("M40 31 L50 36",Y,1.6)+L("M38 33 L46 42",Y,1.6)
  +F("M13 30 C17 23 31 21 40 24 C44 26 43 31 39 33 C30 36 20 35 13 30Z",Y)+F("M18 31 C25 33.5 32 33 37 31 C32 34.5 23 34.5 18 31Z",W,0.8)
  +KL("M18 28.5 C25 27 32 27 38 28.5",0.8)
  +F("M37 26 C40 20 43 16 46.5 14.5 C50 14 51.5 16.5 49.5 18.5 C46.5 21 44.5 25 42.5 29Z",Y)
  +L("M45.5 15 C44.5 9 42.5 6 39.5 4.5",K,0.9)+L("M47.5 14.5 C47 9 46 6 44 3.5",K,0.9)+D(47.6,16.5,0.9,K)+KL("M13 29.5 l-3.5 -2.5",1.2)
  +D(6,37,1.2,K)+D(9,43,1.2,K)+D(50,36,1.2,K)+D(46,42,1.2,K))
fu="M28 47 L16 31 L12 11 L22 19.5 L28 18 L34 19.5 L44 11 L40 31 Z"
I["hetz"]=(F(fu,O)+F("M28 47 L18 33 L24 33.5 L28 39 L32 33.5 L38 33 Z",W)
  +F("M14.5 14.5 L20.5 20.5 L16.5 26Z",K,0.8)+F(spiegel("M14.5 14.5 L20.5 20.5 L16.5 26Z"),K,0.8)
  +F("M18.5 27 Q22.5 23.5 26 27.5 Q22.5 29.5 18.5 27Z",Y,0.9)+F(spiegel("M18.5 27 Q22.5 23.5 26 27.5 Q22.5 29.5 18.5 27Z"),Y,0.9)
  +D(22.6,27,1.2,K)+D(33.4,27,1.2,K)+F("M25.5 42 L30.5 42 L28 45.5Z",K,0.8)
  +L("M8 46 L4 52 M48 46 L52 52",R,1.6)+L("M10 40 L5 42 M46 40 L51 42",R,1.6))
s=F("M5 7 H51 L48 13 H8 Z",B)+"".join(D(x,10,0.9,Y) for x in (12,19,26,33,40,46))
for i,(x,ln) in enumerate(((10,16),(16,24),(22,30),(28,36),(34,30),(40,24),(46,16))):
    s+=pfeil(x,15,x,15+ln,Y,R,B,1.2)
I["rain"]=s+L("M5 50 H51",O,1.4)
I["pierce"]=(E_(17,28,4.5,10,Y)+E_(28,28,4.5,10,G)+E_(39,28,4.5,10,R)+KL("M17 19 v18 M28 19 v18 M39 19 v18",0.6)
  +pfeil(4,28,50,28,W,B,R,1.6)+KL("M14 22 l-3 -3 M25 22 l-3 -3 M36 22 l-3 -3",0.9))
# ---------- Sternleserin ----------
se="M5 37 C6 31 13 28 21 27 C25 26 27.5 23 28 19 L26.5 6 L31.5 6 L32.5 17 L36 17 L37.5 6 L42.5 6 L41 19.5 C44 23.5 45 29 44 35 L44 45 H31 C27 41 20 40 13 40.5 C9 41 6 40 5 37Z"
I["chain"]=(F(se,R)+C(30,28,2.2,W,0.9)+D(29.4,28,1.0,K)+KL("M8 38.5 C13 37 18 37 22 37.5",0.8)+F("M30 45 H45 V48.5 H30Z",B,1.0)
  +F("M14 2 L6 14 L11.5 14 L5 26 L18 11 L12.5 11 L19 2 Z",Y,1.0)+F("M50 30 L46 37 L49 37 L45 45 L53 35 L50 35 L53 30Z",Y,0.9))
I["blink"]=(C(28,28,20,BD,1.4)+f'<circle cx="28" cy="28" r="17.5" fill="none" stroke="{R}" stroke-width="1.2" stroke-dasharray="2 2.6"/>'
  +F(stern(28,28,13,5.3),Y,1.2)+"".join(D(28+15.5*math.cos(math.radians(a)),28+15.5*math.sin(math.radians(a)),0.9,W) for a in range(0,360,40))
  +D(28,28,2,R))
ro="".join(E_(28+6*math.cos(math.radians(a)),22+6*math.sin(math.radians(a)),2.6,1.6,G,0.8).replace("<ellipse",f'<ellipse transform="rotate({a} {28+6*math.cos(math.radians(a)):.2f} {22+6*math.sin(math.radians(a)):.2f})"') for a in range(-90,270,360//7))
I["glass"]=(L("M12 50 Q28 55 44 50",B,1.4)+L("M28 30 V48",BR,2.2)+L("M21 48.5 H35",BR,2.2)
  +L("M12 19 C12 4 44 4 44 19",K,2.0)+L("M12 19 v3 M44 19 v3",K,2.0)+ro+C(28,22,3.2,Y,1.0)+D(28,22,1.2,R))
I["nova"]=(L("M7 12C19 3 37 3 49 12M7 44c12 9 30 9 42 0",T,1.6)+L("M10 18c10-9 26-9 36 0M10 38c10 9 26 9 36 0",B,2.0)
  +F("M13 28c7-9 23-9 30 0-7 9-23 9-30 0z",R)+F("M17 28c5-3 17-3 22 0-5 2.5-17 2.5-22 0z",K,0.6)+KL("M13 28 h-6 M43 28 h6",1.2))
I["meteor"]=(L("M8 47 V22 C8 6 48 6 48 22 V47",B,3.2)+"".join(D(x,y,0.9,Y) for x,y in ((10,30),(10,40),(14,12),(28,7),(42,12),(46,30),(46,40),(20,8.5),(36,8.5)))
  +L("M27 28 L15 15",R,2.0)+L("M30 25 L24 12",O,1.6)+L("M24 31 L12 26",O,1.6)+F(stern(31,34,8.5,3.6),Y,1.2)+D(31,34,1.4,W))
# ---------- Priester ----------
fa="M14 {y}h17c2-3 6-4 10-3 3 1 5 4 4 7-1 3-4 5-8 5H14z"
s=""
for y in (17,31):
    s+=F(fa.format(y=y),H)+F(f"M20 {y}h4v9h-4z",B,1.0)+KL(f"M37 {y+1}v8M41 {y+1.5}v6",0.8)+L(f"M3 {y+2.5}h7 M5 {y+6.5}h6",R,1.2)
I["flurry"]=s+L("M50 22 l4 -2 M50 38 l4 2",Y,1.2)
I["step"]=(L("M4 20h8 M2 28h8 M4 36h7",B,1.4)
  +L("M23 22 L16 42",H,3.0)+L("M33 22 L41 42",H,3.0)+L("M16 42 L10 44",H,2.4)+L("M41 42 L48 43",H,2.4)
  +F("M20 8 H36 L39.5 23 H16.5 Z",W)+KL("M28 11 L29.5 23",0.8)+F("M20 8 H36 V11.5 H20 Z",R,1.0)+F("M24 3 H32 V8 H24Z",H,1.0)
  +F(stern(50,30,4.5,1.8,6),Y,0.9))
I["mantra"]=(f'<circle cx="28" cy="28" r="22" fill="none" stroke="{K}" stroke-width="3.2"/><circle cx="28" cy="28" r="22" fill="none" stroke="{G}" stroke-width="1.8" stroke-dasharray="5 2.5"/>'
  +L("M15 15 V33 H41 V15",H,3.4)+F("M12.5 16 L15 10 L17.5 16Z",H,1.0)+F("M38.5 16 L41 10 L43.5 16Z",H,1.0)
  +F("M13.3 21 h3.4 v2.8 h-3.4z",B,0.8)+F("M39.3 21 h3.4 v2.8 h-3.4z",B,0.8)+L("M28 33 v10",BR,2.2)
  +F("M28 29 C21 24 23 18 28 21.5 C33 18 35 24 28 29Z",R,1.0))
I["palm"]=(L("M28 13 L25 19 L29 23.5 L26.5 28",K,1.4)+L("M14 22 l-4 -6 M42 22 l4 -6 M20 19 l-2 -7 M36 19 l2 -7",O,1.4)
  +F("M8 8 l3 -2 l2 3 l-3 2Z",BR,0.9)+F("M45 7 l3 1 l-1 3 l-3 -1Z",BR,0.9)
  +F("M6 26 H50 V34 H6 Z",G)+KL("M6 29.5 H22 M34 29.5 H50",0.7)+L("M25 26 L27 30 L24.5 34",K,1.2)
  +C(17,42,2.8,Y,1.0)+C(28,42,2.8,Y,1.0)+C(39,42,2.8,Y,1.0))
I["wave"]=(L("M15 7v42",BR,2.4)+L("M8 49h14",BR,2.4)+F("M15 10c22 1 29 15 25 30l-25-3z",W)
  +L("M15 19c12 1 20 5 25 10M15 28c9 1 17 3 24 6",B,1.3)
  +L("M27 45 q6 -3 12 0 q4 2 9 -1 M34 50 q5 -2 10 0",T,1.5)+L("M44 18 q4 -3 8 0 M46 26 q3 -2 6 0",T,1.3))
# ---------- Rotbier ----------
kr="M22 9h12v8c8 4 10 17 4 28H18c-6-11-4-24 4-28z"
I["potion"]=(f'<clipPath id="kr"><path d="{kr}"/></clipPath>'+F(kr,Y)
  +f'<g clip-path="url(#kr)"><rect x="10" y="27" width="40" height="22" fill="{R}"/><rect x="10" y="26" width="40" height="1.4" fill="{K}"/><rect x="10" y="17" width="40" height="3" fill="{B}"/></g>'
  +F(kr,"none")+F("M21 6 H35 V9.5 H21Z",B,1.0)+F("M36 7 C40 9 41 14 39 18 C40 14 38 11 35 10Z",R,0.9)
  +F("M41 21 C43 24 42.5 26 41 26 C39.5 26 39 24 41 21Z",R,0.8)+KL("M24 23 h8",0.8))
# ---------- Dauerhafte Stärken ----------
I["p_zaeh"]=(L("M12 10 V26 C12 32 16 35 21 35 H35 C40 35 44 32 44 26 V10",H,3.2)+F("M9.5 11 L12 5 L14.5 11Z",H,1.0)+F("M41.5 11 L44 5 L46.5 11Z",H,1.0)
  +F("M10.3 17 h3.4 v2.8 h-3.4z",B,0.8)+F("M42.3 17 h3.4 v2.8 h-3.4z",B,0.8)+L("M28 35v11",BR,2.2)+L("M19 47h18",BR,2.2)
  +L("M28 18 V31 M23 22 H33",Y,2.2)+f'<ellipse cx="28" cy="13.5" rx="3.6" ry="4.5" fill="none" stroke="{K}" stroke-width="3.7"/><ellipse cx="28" cy="13.5" rx="3.6" ry="4.5" fill="none" stroke="{Y}" stroke-width="2.2"/>')
I["p_scharf"]=(L("M28 3 v7 M16 6 l3.5 5.5 M40 6 l-3.5 5.5",Y,1.6)+F("M7 25 C15 15 41 15 49 25 C41 35 15 35 7 25Z",K,0.8)
  +F("M11 25 C18 18.5 38 18.5 45 25 C38 31.5 18 31.5 11 25Z",W,0.6)+C(28,25,5.4,B,0.9)+D(28,25,2.4,K)+D(29.3,23.7,0.8,W)
  +L("M23 33 L19 46",K,1.4)+L("M31 33 C35 39 41 39 43 35",R,1.8))
I["p_flink"]=(L("M26 34 l-2 10 M33 34 l2 10",Y,1.4)+L("M22 44 h4 M33 44 h5",Y,1.2)
  +F("M14 30 C16 22 24 18 32 20 C40 22 46 25 51 25 C45 30 37 34 27 34 C21 34 16 33 14 30Z",G)
  +F("M22 24 C28 16 38 13 49 15 C43 22 35 27 24 30Z",B)+KL("M28 22 l4 4 M34 19 l3.5 4.5 M40 17 l3 4",0.8)
  +C(16,16,5.2,H)+F("M10.8 17.5 C10 10 21 9 21.2 15 C18 14 15 15 14.5 19 L13 22 Z",K,0.8)+D(18.5,16,0.9,K)+F("M21 16.5 L23 17.5 L21 18.5Z",H,0.7))
zz=lambda y:"M6 %d"%y+"".join(" l3.5 -4 l3.5 4" for _ in range(6))
I["p_kraft"]=L(zz(16),B,2.2)+L(zz(29),T,2.2)+L(zz(42),B,2.2)+F("M24 49 C26 45 30 45 32 49Z",G,0.9)
I["p_hieb"]=(F("M23 26 C22 15 29 7 38 7 C47 7 51 14 48 23 C47 18 44 14.5 38.5 14.5 C32 14.5 28.5 19 28 27Z",Y)+KL("M25.5 24 C25.5 15 31 10 38 10",0.8)
  +L("M24 32 L25.5 25",BR,2.6)+L("M15 45 L6 53",H,5.5)+L("M14.5 45.5 L11.5 48.5",B,6.0,"butt")
  +F("M12 37 C12 32 16 30 20 30 L28 30 C31 30 32 33 31 35.5 L31 40 C31 43.5 28 45.5 25 45.5 L18 45.5 C14.5 45.5 12 42 12 37Z",H)
  +KL("M18.5 30.5 v6.5 M22.5 30.5 v6.5 M26.5 30.5 v6",0.8)+KL("M13 38 C17 38 19 40 19 43",0.8))
I["p_jaeger"]=(L("M4 37 c6-6 10 2 16-4 s10 2 16-4",G,2.8)+F("M36 29 c2-2 5-2 6 0 c-1 2 -4 3 -6 0Z",G,0.9)+"".join(D(x,y,0.7,Y) for x,y in ((10,35),(17,33),(24,31),(31,30)))
  +L("M9 49 L42 15",BR,2.2)+F("M47 9 L34 12.5 L43.5 22Z",B))
# ---------- Schlüsselsteine ----------
I["k_ermittler"]=(L("M28 10 V46",BR,2.2)+L("M17 47 H39",BR,2.4)+L("M8 17 H48",Y,2.4)+C(28,9,3.2,Y,1.1)
  +KL("M9 18 L5 31 M9 18 L13 31 M47 18 L43 31 M47 18 L51 31",0.8)
  +F("M3.5 31 C5 36 13 36 14.5 31Z",Y,1.0)+F("M41.5 31 C43 36 51 36 52.5 31Z",Y,1.0)
  +F("M9 30 C5 26 6 22 9 24 C12 22 13 26 9 30Z",R,0.9)+F("M47 30.5 C44 27 44 22 46.5 20 C48 20 49 22 48.5 24 C48.5 26 48 28 47 30.5Z",W,0.8))
fk="M20 49 C12 37 14 17 24 6 C28 16 28 31 20 49 Z"
I["k_moench"]=(f'<clipPath id="fk"><path d="{fk}"/></clipPath>'+F(fk,W)
  +f'<g clip-path="url(#fk)"><rect x="5" y="15" width="30" height="3.5" fill="{B}"/><rect x="5" y="25" width="30" height="3" fill="{G}"/><rect x="5" y="35" width="30" height="3.5" fill="{B}"/></g>'
  +F(fk,"none")+KL("M20 47 C20 33 22 20 24 8",1.0)
  +L("M30 18c8-2 14 2 14 8s-6 8-10 4M30 31c10-2 18 2 18 8s-8 9-12 4",T,1.8)+L("M32 11 c4 -2 8 -1 9 1",T,1.4))
I["k_jaegerin"]=(L("M28 31 V47",BR,2.4)+L("M18 48 H38",BR,2.4)+F("M9 26 H45 V31 H9Z",Y)+KL("M15 26 v5 M21 26 v5 M27 26 v5 M33 26 v5 M39 26 v5",0.7)
  +F("M13 26 C13 22 19 20.5 28 21 L35.5 21 C36.5 16 38 12.5 40 10 L40.5 5 L43 10 L45.5 6 L45.5 12.5 C47.5 14.5 49 17 49 19.5 L44.5 20.5 L42.5 23 L41 26Z",K,0.8)
  +F("M13 24 C8 25 6 28 8 33",K,1.6).replace('fill="'+K+'"','fill="none"')+D(44,15,0.9,Y)+F("M38 18.5 L42.5 20 L41.5 22.5 L37 21Z",R,0.8))
I["k_forensiker"]=(L("M26 32 L24 40 M30 32 L32 40",K,0.6)
  +F("M18 24 C18 18 30 16 36 20 C38.5 24 36 30 28 32 C22 33 18 30 18 24Z",W)+F("M18 24 L10 29 L18.5 29.5Z",K,0.8)+KL("M22 25 C26 27 30 27 33 25",0.8)
  +L("M34.5 20 C38 14 38 10 41 9",K,1.0)+C(42,9,2.3,K,0.6)+L("M43.5 10 C46 13 47 17 47 21",K,0.6)+D(42.6,8.4,0.6,W)
  +F("M11 41 H45 V48 H11Z",BR)+C(18,44.5,1.9,R,0.8)+C(24,44.5,1.9,K,0.8)+L("M31 44.5 H42",Y,1.2))

KLASSE={"ermittler":"#2c64a0","moench":"#2f8a7c","jaegerin":"#a8402a","forensiker":"#6a4a90","basalt":"#3b2f25","":"#b07a28"}
ZU={}
for c,ids in {"ermittler":["whirl","dash","oath","udjat","beam","k_ermittler"],"moench":["flurry","step","mantra","palm","wave","k_moench"],
              "jaegerin":["salve","roll","hetz","rain","pierce","k_jaegerin"],"forensiker":["chain","blink","glass","nova","meteor","k_forensiker"],"":["potion"]}.items():
    for i in ids: ZU[i]=c
for i in I:
    if i.startswith("p_"): ZU[i]="basalt"

# ---------- Putz und Nachbearbeitung ----------
def weich(a,r):
    lo,hi=float(a.min()),float(a.max())
    if hi-lo<1e-6: return a
    im=Image.fromarray(((a-lo)/(hi-lo)*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
    return np.asarray(im).astype(np.float32)/255*(hi-lo)+lo
def rauschen(r,s=1.0):
    a=weich(rng.random((N,N)).astype(np.float32),r); return (a-a.mean())/(a.std()+1e-6)*s
y,x=np.mgrid[0:N,0:N].astype(np.float32)/N
def hexf(h): return np.array([int(h[i:i+2],16) for i in (1,3,5)],np.float32)
def tafel(rad=0.12,rand=0.015):
    dx=np.maximum(np.maximum(rand+rad-x,x-(1-rand-rad)),0); dy=np.maximum(np.maximum(rand+rad-y,y-(1-rand-rad)),0)
    d=np.sqrt(dx*dx+dy*dy)-rad; return np.clip(-d*N/2,0,1), np.minimum(np.minimum(x-rand,1-rand-x),np.minimum(y-rand,1-rand-y))
alpha,inner=tafel()
def bild(id_):
    global rng
    import zlib; rng=np.random.default_rng(zlib.crc32(id_.encode()))
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56" width="{N}" height="{N}"><g transform="translate(28 28) scale(0.79) translate(-28 -28)">{I[id_]}</g></svg>'
    g=np.asarray(Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")).astype(np.float32)
    rgb,a=g[...,:3],g[...,3]/255
    putz=hexf("#d6ba8c")*(0.92+0.06*rauschen(8)[...,None]+0.05*rauschen(1.5)[...,None])
    putz*=(1-np.clip(rauschen(30),0,None)*0.08)[...,None]
    grund=putz*(1-0.35*np.clip(np.sqrt((x-0.5)**2+(y-0.5)**2)/0.7,0,1)**2)[...,None]
    farbe=rgb*(1+0.05*rauschen(3)[...,None])*(0.96+0.04*rauschen(0.8)[...,None])
    abrieb=np.clip(rauschen(5)-1.5,0,1)*0.85
    a2=a*(1-abrieb)
    b=grund*(1-a2[...,None])+farbe*a2[...,None]
    risse=np.clip(1-np.abs(rauschen(16))/0.012,0,1)*0.22*np.clip(rauschen(40)+0.3,0,1); b*=(1-risse[...,None])
    kc=hexf(KLASSE[ZU.get(id_,"")])
    rand=np.exp(-((inner-0.05)/0.012)**2)+np.exp(-((inner-0.075)/0.006)**2)*0.8
    b=b*(1-np.clip(rand,0,1)[...,None])+kc*np.clip(rand,0,1)[...,None]
    b*=(1-0.18*np.clip(np.sqrt((x-0.5)**2+(y-0.5)**2)/0.72,0,1)**3)[...,None]
    return Image.fromarray(np.dstack([np.clip(b,0,255),alpha*255]).astype(np.uint8),"RGBA")
if __name__=="__main__":
    ziel=sys.argv[1]; nur=sys.argv[2:] or list(I)
    for i in nur:
        bild(i).resize((256,256),Image.LANCZOS).save(f"{ziel}/{i}.png"); print(i,end=" ")
    print()
