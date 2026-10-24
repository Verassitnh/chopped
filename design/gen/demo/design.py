import random
N=82
def run(p0,p1,seed):
    random.seed(seed); out=[]
    for i in range(N):
        p=p0+(p1-p0)*(i/(N-1)); out.append(1 if random.random()<p else 0)
    return out
ex=run(0.45,0.95,3); ex[-6:]=[1]*6; ex[-7]=0
for i in range(48,62): ex[i]=1
ex[62]=0
em=run(0.75,0.98,5)
def streaks(a):
    s=[];st=None
    for i,v in enumerate(a+[0]):
        if v and st is None: st=i
        if not v and st is not None: s.append((st,i-st)); st=None
    return s
if __name__=="__main__":
    import datetime as dt
    d0=dt.date(2026,8,3)
    print("ex",''.join(map(str,ex)), streaks(ex))
    print("em",''.join(map(str,em)), streaks(em))
