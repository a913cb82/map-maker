import random
from time import sleep

GREEN = '#00ff00'
BLUE = '#0000ff'

SEA = -1
LAND = 0
MAP_RENDER = {SEA: ' ',
			  LAND: '#',
			  1: '1',
			  2: ':',
			  3: '/',
			  4: '%',
			  5: '5',
			  6: '~',
			  7: '+',
			  8: '<',
			  9: 'H',}
			  
def round(n, dp):
	return int(n*10**dp)/10.**dp

SQRT = {}
for r in range(101):
	r2=r/100.
	SQRT[r2]=round(r2**0.5, 2)

class Map():
	def __init__(self, mapx=75, mapy=37,startpts=5,landfraction=.4,numciv=9,win_chance=.2):
		self.mapx = mapx
		self.mapy = mapy
		self.startpts = startpts
		self.landfraction = landfraction
		self.map = []
		self.history = []
		
		self.numciv = numciv
		self.win_chance = win_chance
	def neighbours(self, pos):
		x, y = pos
		neigh = []
		for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dy or dx:
						neigh.append(((x + dx) % self.mapx, (y + dy) % self.mapy))
		return neigh
	def rndneigh(self, pos):
		return random.choice(self.neighbours(pos))
	def makemap(self):
		self.map = [[SEA for x in range(self.mapx)]
					for y in range(self.mapy)]
					
		landlist = []
		for land in range(self.startpts):
			x = random.randint(0, self.mapx - 1)
			y = random.randint(0, self.mapy - 1)
			self.map[y][x] = LAND
			landlist.append((x,y))
			
		maxland = self.mapx * self.mapy * self.landfraction
		numland = 0
		activeland = []
		while numland < maxland:
			for pos in activeland:
				targ = self.rndneigh(pos)
				x, y = targ
				if self.map[y][x] == SEA:
					landlist.append(targ)
					activeland.append(targ)
					self.map[y][x] = LAND
					numland+=1
				else:
					activeland.remove(pos)
				if numland > maxland:
					break
			if not activeland:
				activeland = landlist
		return self.map
	def play(self, map):
		land = []
		for x in range(self.mapx):
			for y in range(self.mapy):
				if map[y][x] != SEA:
					land.append((x,y))
		#place players
		for n in range(1, self.numciv + 1):
			x = random.randint(0, self.mapx - 1)
			y = random.randint(0, self.mapy - 1)
			while self.map[y][x] != LAND:
				x = random.randint(0, self.mapx - 1)
				y = random.randint(0, self.mapy - 1)
			self.map[y][x] = n
		turn = 0
		newmap = map
		history = []
		while 1:
			owned = {}
			for n in range(1, self.numciv + 1):
				owned[n] = 0
			for pos in land:
				x, y = pos
				if map[y][x] != SEA and map[y][x] != LAND:
					owned[map[y][x]]+=1
					targ = self.rndneigh((x,y))
					x2, y2 = targ
					if map[y2][x2] != SEA:
							
						if map[y2][x2] == LAND:
							newmap[y2][x2] = map[y][x]
						elif map[y2][x2] != map[y][x]:
							#calc real win_chance
							real_win_chance = self.win_chance
							targ = self.rndneigh(targ)
							for n in range(5):
								x3, y3 = targ
								if map[y3][x3] != map[y][x]:
									break
								real_win_chance = SQRT[real_win_chance]
								targ = self.rndneigh(targ)
							if random.random() < real_win_chance:
								newmap[y2][x2] = map[y][x]
			if turn % 75 == 0:
				print turn
				for p in owned: 
					if owned[p] > 0: print MAP_RENDER[p],':',owned[p]
				#print owned
				self.render(map)
				self.rendergame2()
				history.append(owned)
				for p in owned:
					if owned[p]==0:
						pos = random.choice(land)
						x, y = pos
						map[y][x] = p
				if self.history[len(self.history) - 1] == self.history[len(self.history) - 2]:
					break
					
			turn+=1
			map = newmap
			
	def render(self, map):
		rendered = '|'
		for n in range(self.mapx):
			rendered+='-'
		rendered+='|\n'
		for y in map:
			rendered+='|'
			for x in y:
				rendered+=MAP_RENDER[x]
			rendered+='|\n'
		rendered+='|'
		for n in range(self.mapx):
			rendered+='-'
		rendered+='|'
		self.history.append(rendered)
	
	def rendergame(self):
		n = 0
		for rendered in self.history:
			n += 1
			print n,'/',len(self.history)
			print rendered
			raw_input("Press Enter to continue...")
	def rendergame2(self):
		print self.history[len(self.history)-1]

def run():
	try: 
		m=Map()
		b=m.makemap();m.render(b)
		m.play(b)
	except Exception, err:
		print 'ERROR: %s\n' % str(err)
		run()
#run()
m=Map()
b=m.makemap();m.render(b)
m.play(b)
raw_input("Press Enter to continue...")
m.rendergame()
while 1:
	raw_input("GAME OVER")