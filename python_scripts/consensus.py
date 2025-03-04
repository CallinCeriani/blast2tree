#!/usr/bin/env python3
print('start')
names = ['empty']
f3 = open('reference.fa', 'r')
for line in f3:
    ln = line.strip()
    l = len(ln)
    if ln[0:1:1] == '>':
        names.append(ln[1:l:1])
f3.close()
nfrc = []

sgr = []  
res = []  
for i in names:
    res.append('>' + i + '\n')
    nfrc.append('')


def consensus():
    rst: int = 0  
    rgr: int = 0  
    m = []
    lsgr = len(sgr)
    lnames = len(names)
    for i in range(lsgr):
        mm = sgr[i]
        for j in range(lnames):
            nn = names[j]
            if mm.find(nn) > -1:
                rgr = j
                rst = i
                nfrc[rgr] = mm[len(names[j]):len(names[j])+1]
    del sgr[rst]
    for i in sgr:
        m.append(i[22:])
    if m:
        gl = [] 
        cons = ""  
        n = ""  
        j = 0
        while j < len(m):
            gl.append(len(m[j]))
            j = j + 1
        j = 0
        ml = max(gl)
        while j < len(m):
            m[j] = m[j] + " " * (ml - len(m[j]))
            j = j + 1
        i = 0
        while i < len(m[0]):
            a = 0
            t = 0
            g = 0
            c = 0
            j = 0
            while j < len(m):
                ts2 = m[j]
                if ts2[i] == "A":
                    a = a + 1
                if ts2[i] == "T":
                    t = t + 1
                if ts2[i] == "G":
                    g = g + 1
                if ts2[i] == "C":
                    c = c + 1
                j = j + 1
            if a == max(a, t, g, c):
                n = "A"
            if t == max(a, t, g, c):
                n = "T"
            if g == max(a, t, g, c):
                n = "G"
            if c == max(a, t, g, c):
                n = "C"
            if a == c == max(a, t, g, c):
                n = "M"
            if a == g == max(a, t, g, c):
                n = "R"
            if a == t == max(a, t, g, c):
                n = "W"
            if c == g == max(a, t, g, c):
                n = "S"
            if c == t == max(a, t, g, c):
                n = "Y"
            if g == t == max(a, t, g, c):
                n = "K"
            if a == c == g == max(a, t, g, c):
                n = "V"
            if a == c == t == max(a, t, g, c):
                n = "H"
            if a == g == t == max(a, t, g, c):
                n = "D"
            if c == g == t == max(a, t, g, c):
                n = "B"
            if a == t == g == c == max(a, t, g, c):
                n = "N"
            if max(a, t, g, c) == 0:
                n = ""
            cons = cons + n
            i = i + 1
        res[rgr] = res[rgr] + cons + '\n'


def revcomp(q):
    u = q.find('\n')
    capt = q[:u]  
    body = q[u + 1:]  
    body = body.replace('\n', '')  
    rev = body[len(body):0:-1] + body[0]
    trt = rev.maketrans('ACGTMRWSYKVHDBN', 'TGCANNNNNNNNNNN')
    comp = rev.translate(trt)
    comps = ''
    ll = len(comp)
    if ll > 60:
        nos = round(ll / 60)
        if round(ll / 60) < ll / 60:
            nos = round(ll / 60) + 1
        for k in range(nos):
            if k < nos:
                comps = comps + comp[k * 60: k * 60 + 60] + '\n'
            if k == nos:
                comps = comps + comp[k * 60:]
    out = capt + '\n' + comps
    return out


beg: int = 0
f1 = open('out.txt', 'r') 
f4 = open('res.txt', 'w') 
f4.write('')
f4.close()
f2 = open('res.txt', 'a+') 
for line in f1:
    l = line.strip()
    if l[0:5] == '_____':
        beg = 0
        consensus()
        sgr = []
    if beg == 1:
        sgr.append(l)
    if l.find(':') > 0:
        beg = 1
i = 0
for i in range(len(res)):
    if nfrc[i] == '-':
        res[i] = revcomp(res[i])
    if nfrc[i] == '+':
        res[i] = revcomp(res[i])
        res[i] = revcomp(res[i])
for i in range(len(res)-1):
    e = res[i]
    if e[0:6] == '>empty':
        del res[i]
for i in res:
    f2.write(i)
print('completed')
f1.close()
f2.close()