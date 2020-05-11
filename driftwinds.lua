-- title:		drift winds
-- author:	mngyuan
-- desc:		top down battle racer
-- script:	lua

DEV=true

Ship = {}
Ship.__index = Ship

function Ship:new(pnum)
	local pnum=pnum or 0
	local ship={
		x=96+pnum*24,
		y=24,
		spd=0,dir=0,
		rspd=0.06,
		MAXSPD=1.4,ACCAMT=0.05,DECAMT=1.02,
		pstate='free',
		pstates={'free','drift','boost','hitstun'},
		driftdir=0,driftside='m',lastdrift=0,
		DRIFTACCWIN=30,
		BOOSTSPDS={8,8,6,5,3,3,3,2.5,1.25,0.9},
		lastboost=-80,BOOSTCD=80,
		boostx=0,boosty=0,
		hitboxr=8,

		pnum=pnum,
	} 
	setmetatable(ship, self)
	return ship
end

function Ship:TIC()
	local accel=false
	local turnl,turnr=false,false
	local debugtxt=''

	if btn(self.pnum*8+0) then accel=true end
	if btn(self.pnum*8+1) then accel=false end
	if btn(self.pnum*8+2) then turnl=true end
	if btn(self.pnum*8+3) then turnr=true end
	if btn(self.pnum*8+4) then
		if self.pstate=='free' and t-self.BOOSTCD > self.lastboost then
			self.driftdir=self.dir
			self.pstate='drift'
			if turnl then self.driftside='l'
			elseif turnr then self.driftside='r'
			end
			self.lastdrift=t
		end
	else
		if self.pstate=='drift' then
			if t-self.BOOSTCD > self.lastboost then
				self.lastboost=t
				self.pstate='boost'
				self.boostx=self.x
				self.boosty=self.y
			else
				self.pstate='free'
				self.driftside='m'
			end
		end
	end
	
	if self.pstate=='free' then
		if accel then
			self.spd=math.min(self.spd+self.ACCAMT,self.MAXSPD)
		else
			self.spd=self.spd/self.DECAMT
		end
		if turnl then
			self.dir=self.dir+self.rspd
		elseif turnr then
			self.dir=self.dir-self.rspd
		end
	elseif self.pstate=='drift' then
		-- during drifting, self.driftdir refers to the direction of movement
		-- self.dir refers to the direction the ship points
		-- and the direction the player will move when ending drift
		-- these are only different during DRIFFACCWIN
		if accel then
			self.spd=math.min(self.spd+self.ACCAMT,self.MAXSPD)
		else
			self.spd=self.spd/((1+self.DECAMT)/2)
		end
		if self.driftside=='l' then
			local scale=1
			if t-self.lastdrift < self.DRIFTACCWIN then
				scale=(t-self.lastdrift)^2/self.DRIFTACCWIN^2
			end
			if turnl then
				self.driftdir=self.driftdir+scale*self.rspd*1.2
				debugtxt=debugtxt..'rspd '..(scale*self.rspd/1.2)..'\n'
			elseif turnr then
				self.driftdir=self.driftdir-scale*self.rspd/2.5
				debugtxt=debugtxt..'rspd '..(-scale*self.rspd/2.5)..'\n'
			else
				self.driftdir=self.driftdir+scale*self.rspd/2
				debugtxt=debugtxt..'rspd '..(scale*self.rspd/2)..'\n'
			end
		elseif self.driftside=='r' then
			local scale=1
			if t-self.lastdrift < self.DRIFTACCWIN then
				scale=(t-self.lastdrift)^2/self.DRIFTACCWIN^2
			end
			if turnl then
				self.driftdir=self.driftdir+scale*self.rspd/2.5
				debugtxt=debugtxt..'rspd '..(scale*self.rspd/2.5)..'\n'
			elseif turnr then
				self.driftdir=self.driftdir-scale*self.rspd*1.2
				debugtxt=debugtxt..'rspd '..(-scale*self.rspd/1.2)..'\n'
			else
				self.driftdir=self.driftdir-scale*self.rspd/2
				debugtxt=debugtxt..'rspd '..(-scale*self.rspd/2)..'\n'
			end
		end
		if self.driftside=='l' then
			if t-self.lastdrift < 3*self.DRIFTACCWIN then
				self.dir=math.min(self.dir+self.rspd,self.driftdir+10*self.rspd)
			else
				self.dir=self.driftdir
			end
		elseif self.driftside=='r' then
			if t-self.lastdrift < 3*self.DRIFTACCWIN then
				self.dir=math.max(self.dir-self.rspd,self.driftdir-10*self.rspd)
			else
				self.dir=self.driftdir
			end
		end
	end
	self.dir=self.dir%(math.pi*2)
	self.driftdir=self.driftdir%(math.pi*2)
	debugtxt=debugtxt..'dir: '..(self.dir)..'\n'
	debugtxt=debugtxt..'ddir: '..(self.driftdir)..'\n'
	
	-- drifting suspends normal movement
	if self.pstate=='drift' then
		self.x=self.x+self.spd*math.cos(self.driftdir)
		self.y=self.y-self.spd*math.sin(self.driftdir)
	elseif self.pstate=='boost' then
		self.spd=self.BOOSTSPDS[t-self.lastboost+1]
		if self.spd==nil then
			self.spd=self.MAXSPD
			self.pstate='free'
			self.driftside='m'
		end
		self.x=self.x+self.spd*math.cos(self.dir)
		self.y=self.y-self.spd*math.sin(self.dir)
	else
		self.x=self.x+self.spd*math.cos(self.dir)
		self.y=self.y-self.spd*math.sin(self.dir)
	end

	-- draw
	local indx=self.x+15*math.cos(self.dir)
	local indy=self.y-15*math.sin(self.dir)
	local curspr=272
	
	if self.dir<math.pi*2 then curspr=276 end -- E
	if self.dir<math.pi*(7/4+1/8) then curspr=286 end -- SE
	if self.dir<math.pi*(6/4+1/8) then curspr=272 end -- S
	if self.dir<math.pi*(5/4+1/8) then curspr=284 end -- SW
	if self.dir<math.pi*(1+1/8) then curspr=278 end -- W
	if self.dir<math.pi*(3/4+1/8) then curspr=280 end -- NW
	if self.dir<math.pi*(2/4+1/8) then curspr=274 end -- N
	if self.dir<math.pi*(1/4+1/8) then curspr=282 end -- NE
	if self.dir<math.pi*1/8 then curspr=276 end -- E

	--spr(1+t%60//30*2,x,y,14,1,0,0,1,1)
	spr(curspr,self.x-4,self.y-4,0,1,0,0,1,1)
	spr(curspr+1,self.x+4,self.y-4,0,1,0,0,1,1)
	spr(curspr+16,self.x-4,self.y+4,0,1,0,0,1,1)
	spr(curspr+17,self.x+4,self.y+4,0,1,0,0,1,1)
	spr(256,indx,indy,0,1,0,0,1,1) -- indicator
	if DEV then
		print(debugtxt,self.x+8,self.y+8,15,false,1,true)
	end
	-- fx
	local driftt=t-self.lastdrift
	if self.pstate=='drift' then
		circb(self.x+4,self.y+4,7+(driftt/7)%8,14+(driftt/7)%2)
	elseif self.pstate=='boost' then
		if self.lastboost==t then sfx(0,'C-4') end
		if self.lastboost + 12 > t then
			local boostdestx=self.boostx+30*math.cos(self.dir)
			local boostdesty=self.boosty-30*math.sin(self.dir)
			line(self.boostx+4,self.boosty+4,boostdestx+4,boostdesty+4,14+(driftt/3)%2)
		end
	end
end

function dist(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

t=0
ships={Ship:new(0), Ship:new(1)}

function TIC()
	map(0,0,30,17,0,0)
	for i,ship in ipairs(ships) do
		ship:TIC()
		for j=i+1,#ships do
			local d=math.abs(dist(ship.x,ship.y,ships[j].x,ships[j].y))
			if d<=2*math.max(ship.hitboxr,ships[j].hitboxr) then
				if DEV then
					circ(ship.x+4,ship.y+4,ship.hitboxr,8)
					circ(ships[j].x+4,ships[j].y+4,ships[j].hitboxr,8)
				end
			end
		end
	end
	t=t+1
end

-- <TILES>
-- 000:9991199999999119999999911119999999911199999999111999999991199999
-- 001:9991199999999119999999911119999999911199999999111999999991199999
-- 016:9991199999999119999999911119999999911199999999111999999991199999
-- 017:9991199999999119999999911119999999911199999999111999999991199999
-- </TILES>

-- <SPRITES>
-- 000:0000000000000000000000000006e000000e6000000000000000000000000000
-- 001:00000040004000f000f00f4f0fff07ff0f4ff3347fff74400433440000440000
-- 002:00fff00000fff00000f770000fffff000ffff700037ff4000443440000444000
-- 003:040000000f000400f4f00f00ff70fff0433ff4f00447fff70044334000004400
-- 004:00000040040000f70ff00ffff4ff0f4fff77ff77444344440044444000000000
-- 005:00000040000000f700400fff00f7ff4700ff07ff0f47f334f7ff344400444400
-- 006:000fff00000fff00000fff0000fffff000777f70000333000004340000004000
-- 007:040000007f000000fff0040074ff7f00ff70ff00433f74f04443ff7f00444400
-- 008:040000007f000040fff00ff0f4f0ff4f77ff77ff444434440444440000000000
-- 016:0000000a00000aa90000a1110000a1990000a19a0000aaa90000a1110000a199
-- 017:a00000009aa00000111a0000999a0000a99a00009aaa0000111a0000999a0000
-- 018:0000000a00000aa90000a1110000a1990000a1990000a1990000a1990000a199
-- 019:a00000009aa00000111a0000999a0000999a0000999a0000999a0000999a0000
-- 020:0000aa00000a11a0000a99a000a199a000a199a000a199a000a199a000a199a0
-- 021:0000000000000000000aa00000a11a0000a99a000a199a000a199a000a199a00
-- 022:0000000000000000000aa00000a11a0000a19a0000a199a000a199a000a199a0
-- 023:00aa00000a11a0000a19a0000a199a000a199a000a199a000a199a000a199a00
-- 024:0000000000000000000000a00000aa9a000a199a000a199a000a199a000a199a
-- 025:0000000000aa0000aa99a0001999a0001999a0001999a0001999a0001999a000
-- 026:000000000000aa00000a11aa000a1911000a1999000a1999000a1999000a1999
-- 027:00000000000000000a000000a1aa0000a111a000a199a000a199a000a199a000
-- 028:00000000000000000000000a0000aa0a000a11aa000a191a000a199a000a199a
-- 029:00000000aa00000011aa00001911a0001999a0001999a0001999a0001999a000
-- 030:00000000000000aa0000aa11000a1199000a1999000a1999000a1999000a1999
-- 031:0000000000000000a0000000a0aa0000aa11a000a199a000a199a000a199a000
-- 032:0000a1990000a19900000a190000a9220000a92200000a92000000a20000000a
-- 033:999a0000999a000099a00000222a0000222a000022a000002a000000a0000000
-- 034:0000a1990000a19900000a190000a9220000a92200000a92000000aa00000000
-- 035:999a0000999a000099a00000222a0000222a000022a00000aa00000000000000
-- 036:00a199a00a1999a00aaa2aaaa9992222a92222220a92222200aaaaaa00000000
-- 037:0a999a00a9999a00aaa2aaa09222229a222222a02222aa00aaaaa00000000000
-- 038:00a199a000a1999a0aaa2aaaa99922220a22222200aa2222000aaaaa00000000
-- 039:0a199a000a1999a0aaa2aaa09222222a2222222a222222a0aaaaaa0000000000
-- 040:00aa199a0a9a199a0a9a19aa00a2aa2a000a222a0000aa22000000aa00000000
-- 041:1999a0001999a0001999a00019aaaa00aa2222a0222222a0aa222a0000aaa000
-- 042:000a1999000a1999000a199900aaaa990a9222aa0a92222200a222aa000aaa00
-- 043:a199aa00a199a2a0aa99a2a0a2aa2a00a222a00022aa0000aa00000000000000
-- 044:000a199a000a199a000a199a00aaa99a0a922aa200a92222000a222a0000aaa0
-- 045:1999a0001999aa00aa99a2a022aa22a022222a0022aaa000aa00000000000000
-- 046:000a199900aa19990a9a19aa0a92aa2200a22222000aaa22000000aa00000000
-- 047:a199a000a199a000a199a000a19aaa002aa222a022222a00a222a0000aaa0000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 003:0368abccba7420000258bdefffec9520
-- </WAVES>

-- <SFX>
-- 000:0fd50fc41fc42fc43fb33f605fa26f907f018f809f90af70bf00ef50ef5fef40ef40ef3dff30ef30ef2bef10ff0affb9ff78ff38ff00ff00ff00ff00407000000000
-- </SFX>

-- <PALETTE>
-- 000:505050dadea13c7d24815d30593c28346524d04648d6d6b6597dce99c2440110186daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

