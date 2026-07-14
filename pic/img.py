"""
Demonstrate the use of layouts to control placement of multiple plots / views /
labels
"""
from PIL import Image
from pyqtgraph.Qt import QtGui, QtCore 
import pyqtgraph as pg
import numpy as np
import PIL.ImageOps

#~ USE=False
USE=True

#98:B6:E9:3C:48:D2 controller mac

COORDS ={}
###############
app = QtGui.QApplication([])
mw = QtGui.QMainWindow()
mw.resize(1200,700)
mw.setWindowTitle('system-00')
cw = QtGui.QWidget()
mw.setCentralWidget(cw)
layout = QtGui.QGridLayout()
cw.setLayout(layout)


image = pg.GraphicsView()
l = pg.GraphicsLayout()
image.setCentralItem(l)

########
tree = pg.TreeWidget()
tree.setColumnCount(1)
tree.setHeaderLabel("net")
#~ print(dir(tree))
b5 = QtGui.QPushButton("clear"if USE else 'save')

b1 = QtGui.QLineEdit("TP0(N)")

###########

## Add 3 plots into the first row (automatic position)
vb = l.addViewBox(lockAspect=True)

ap = None
bp = None
def add_line(a,b):
	r = pg.PolyLineROI([(a[0],a[1]), (b[0],b[1])],pen=pg.mkPen('c', width=4))
	vb.addItem(r)

def roi_click(a):
	print ("roi clic)",a)

seltg={}
ncol = 0

def toggle(sig):
	global seltg
	global ncol
	print (sig)
	if sig in seltg.keys() or not sig:
		#~ print("+",sig)
		ss=[]
		for k,v in seltg.items():
			if (sig and k==sig) or not sig:
				for i in v: 
					vb.removeItem(i)
				ss.append(k)
		for i in ss:
			del seltg[i]
			#~ ncol -= 2
		if not sig:
			ncol = 0
	else:
		#~ print("-")
		seltg[sig]=[]
		for p in COORDS[sig]["point"]:
			#~ print(p)
			seltg[sig].append( pg.TargetItem( pos=(p[0],p[1]), label=sig, pen=(ncol,9), movable=False) )
			vb.addItem(seltg[sig][-1])
		ncol+=2	

def look_near(xp,yp):
	global ncol
	dist = 10000**2
	sig = None
	for k,v in COORDS.items():
		for i in v["point"]:
			x= i[0]
			y= i[1]
			d = (xp-x)**2+(yp-y)**2
			if d<dist:
				dist = d
				sig = k
	if sig:
		toggle(sig)
	#~ if sig and not seltg.get(sig):
		#~ seltg[sig]=[]	
		#~ for i in COORDS[sig]["point"]:
			#~ seltg[sig].append( pg.TargetItem( pos=(i[0],i[1]), label=sig, pen=(ncol,9), movable=False) )
			#~ vb.addItem(seltg[sig][-1])
			#~ ncol+=2
		#~ clear(sig)	
	#~ elif sig:
		#~ clear(sig)
			
def pop_coord(sig,x,y,settarget=True):
	if COORDS.get(sig):
		COORDS[sig]["point"].append( (x,y) )
		#~ COORDS[sig]["roi"].append( pg.CircleROI([point.x()-(D>>1),point.y()-(D>>1)], [D, D], pen=(2,9)) )
		COORDS[sig]["roi"].append( pg.TargetItem( pos=(x,y), label=sig, pen=(6,9), movable=False) if settarget else None) 
		subitem = pg.TreeWidgetItem([str((x,y))])
	else:
		item  = QtGui.QTreeWidgetItem([sig])
		COORDS[sig]={
			"item":item,
			"point":[(x,y)], 
			#~ "roi":[ pg.CircleROI([point.x()-(D>>1),point.y()-(D>>1)], [D, D], pen=(2,9)) ]
			"roi":[ pg.TargetItem( pos=(x,y), label=sig, pen=(3,9), movable=False) if settarget else None]
		}
		#~ print( dir( COORDS[sig]["roi"][0] ) )
		
		#~ COORDS[sig]["roi"][-1].mouseClickEvent(roi_click)
		subitem = pg.TreeWidgetItem([str((x,y))])
		tree.addTopLevelItem(item)
		
	COORDS[sig]["item"].addChild(subitem)
	if settarget:
		vb.addItem(COORDS[sig]["roi"][-1])
	
def handle_click(event):
	D=30
	ppoint = vb.mapSceneToView(event.scenePos())
	x=int(ppoint.x())
	y=int(ppoint.y())
	sig = b1.text()
	
	if USE:
		look_near(x,y)
	else:	
		pop_coord(sig,x,y)
	#~ print("point",point.x(),point.y())

#~ a = np.array(Image.open("full_lr.png").rotate(270)).astype("float64")

def load():
	name = "points.base"
	sl = None
	x=0
	y=0
	with open(name) as f:
		while 1:
			line=f.readline()
			if not line:
				break
			line = line.strip()
			if line[0]==">":
				#~ print(line[1:])
				sl = line[1:]
			elif line[0]==".":
				xy=line[2:-1].split(",")
				x= int(xy[0].strip())
				y= int(xy[1].strip())
				#~ print(x,y)
				pop_coord(sl,x,y,not USE)
		if sl:
			b1.setText(sl)			

def save():
	name = "points.base"
	with open(name,"wt") as f:
		for k,v in COORDS.items():
			#~ print (k)
			f.write(">"+k+"\n")
			for i in v["point"]:
				#~ print(i)
				f.write("."+str(i)+"\n")

def save_hnd(btn):
	save()

def clear_hnd(btn):
	toggle(None)
	
b5.clicked.connect(clear_hnd if USE else save_hnd)

def treeclick():
	#~ print("i'm tree")
	#~ print(dir(tree.selectedItems()[0]))
	#~ print(tree.selectedItems()[0].text(0))
	tval = tree.selectedItems()[0].text(0)
	if USE:
		toggle(tval)
	else:	
		b1.setText( tval )
	
tree.clicked.connect(treeclick)

a = np.array(Image.open("full_vert.png")).astype("float64")
#~ d1 = len(a)
#~ d2 = len(a[0])
#bpc=(0,0x14,0x84)
#~ bpc=(55,99,124)
#~ for j in range(d1):
	#~ for k in range(d2):
		#~ r=bpc[0]+a[j,k][0]
		#~ g=bpc[1]+a[j,k][1]
		#~ b=bpc[2]+a[j,k][2]
		#~ if r>255 or g>255 or b>255:
			#~ a[j,k] = [ 255,255,255,255]
		#~ else:
			#~ a[j,k] = [ (r)%255,(g)%255,(b)%255,255]

img = pg.ImageItem(a)
vb.addItem(img)
vb.autoRange()

vb.scene().sigMouseClicked.connect(handle_click)

layout.addWidget(image, 0, 0, 3,1)
layout.addWidget(tree, 0, 1)
layout.addWidget(b1, 1, 1)
layout.addWidget(b5, 2, 1)

layout.setColumnStretch(0, 7)
layout.setColumnStretch(1, 1)

mw.show()

load()	

## Start Qt event loop unless running in interactive mode.
if __name__ == '__main__':
    import sys
    if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
        QtGui.QApplication.instance().exec_()
