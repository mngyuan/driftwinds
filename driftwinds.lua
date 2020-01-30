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
		maxspd=1.4,accamt=0.05,decamt=1.02,
		pstate="free",
		pstates={"free","drift","boost","hitstun"},
		driftvec=0,driftside="m",lastdrift=0,
		driftaccwin=30,
		boostspds={8,8,6,5,3,3,3,2.5,1.25,0.9},
		lastboost=-80,boostcd=80,
		boostx=0,boosty=0,
		hitboxr=4,

		pnum=pnum,
	} 
	setmetatable(ship, self)
	return ship
end

function Ship:TIC()
	local accel=false
	local turnl,turnr=false,false
	local debugtxt=""

	if btn(self.pnum*8+0) then accel=true end
	if btn(self.pnum*8+1) then accel=false end
	if btn(self.pnum*8+2) then turnl=true end
	if btn(self.pnum*8+3) then turnr=true end
	if btn(self.pnum*8+4) then
		if self.pstate=="free" and t-self.boostcd > self.lastboost then
			self.driftvec=self.dir
			self.pstate="drift"
			if turnl then self.driftside="l"
			elseif turnr then self.driftside="r"
			end
			self.lastdrift=t
		end
	else
		if self.pstate=="drift" then
			if t-self.boostcd > self.lastboost then
				self.lastboost=t
				self.pstate="boost"
				self.boostx=self.x
				self.boosty=self.y
			else
				self.pstate="free"
				self.driftside="m"
			end
		end
	end
	
	if accel then
		self.spd=math.min(self.spd+self.accamt,self.maxspd)
	elseif self.pstate=="free" then
		self.spd=self.spd/self.decamt
	elseif self.pstate=="drift" then
		self.spd=self.spd/((1+self.decamt)/2)
	end
	if turnl then
		if self.pstate=="free" then
			self.dir=self.dir+self.rspd
		elseif self.pstate=="drift" then
			local scale=1
			if t-self.lastdrift < self.driftaccwin then
				scale=(t-self.lastdrift)^2/self.driftaccwin^2
			end
			if self.driftside=="l" then
				self.driftvec=self.driftvec+scale*self.rspd*1.2
				debugtxt=debugtxt..'rspd '..(scale*self.rspd/1.2)..'\n'
			elseif self.driftside=="r" then
				self.driftvec=self.driftvec-scale*self.rspd/2.5
				debugtxt=debugtxt..'rspd '..(-scale*self.rspd/2.5)..'\n'
			else
				self.driftvec=self.driftvec+scale*self.rspd/2
				debugtxt=debugtxt..'rspd '..(scale*self.rspd/2)..'\n'
			end
			--TODO: refactor this into a pstate=drift driftside=l check instead of 
			--top level turnl check; this should happen on driftside=l regardless?
			--of turn state
			if t-self.lastdrift < 3*self.driftaccwin then
				self.dir=math.min(self.dir+self.rspd,self.driftvec+10*self.rspd)
			else
				self.dir=self.driftvec
			end
		end
	elseif turnr then
		if self.pstate=="free" then
			self.dir=self.dir-self.rspd
		elseif self.pstate=="drift" then
			local scale=1
			if t-self.lastdrift < self.driftaccwin then
				scale=(t-self.lastdrift)^2/self.driftaccwin^2
			end
			if self.driftside=="r" then
				self.driftvec=self.driftvec-scale*self.rspd*1.2
				debugtxt=debugtxt..'rspd '..(-scale*self.rspd/1.2)..'\n'
			elseif self.driftside=="l" then
				self.driftvec=self.driftvec+scale*self.rspd/2.5
				debugtxt=debugtxt..'rspd '..(scale*self.rspd/2.5)..'\n'
			else
				self.driftvec=self.driftvec-scale*self.rspd/2
				debugtxt=debugtxt..'rspd '..(-scale*self.rspd/2)..'\n'
			end
			--TODO: refactor this into a pstate=drift driftside=l check instead of 
			--top level turnl check; this should happen on driftside=l regardless?
			--of turn state
			if t-self.lastdrift < 3*self.driftaccwin then
				self.dir=math.max(self.dir-self.rspd,self.driftvec-10*self.rspd)
			else
				self.dir=self.driftvec
			end
		end
	elseif self.pstate=="drift" then
		if self.driftside=="r" then
			self.driftvec=self.driftvec-self.rspd
		elseif self.driftside=="l" then
			self.driftvec=self.driftvec+self.rspd
		end
	end
	self.dir=self.dir%(math.pi*2)
	self.driftvec=self.driftvec%(math.pi*2)
	
	-- drifting suspends normal movement
	if self.pstate=="drift" then
		self.x=self.x+self.spd*math.cos(self.driftvec)
		self.y=self.y-self.spd*math.sin(self.driftvec)
	elseif self.pstate=="boost" then
		self.spd=self.boostspds[t-self.lastboost+1]
		if self.spd==nil then
			self.spd=self.maxspd
			self.pstate="free"
			self.driftside="m"
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
	local curspr=1
	
	if self.dir<math.pi*2 then curspr=8 end
	if self.dir<math.pi*(7/4+1/8) then curspr=7 end
	if self.dir<math.pi*(6/4+1/8) then curspr=6 end
	if self.dir<math.pi*(5/4+1/8) then curspr=5 end
	if self.dir<math.pi*(1+1/8) then curspr=4 end
	if self.dir<math.pi*(3/4+1/8) then curspr=3 end
	if self.dir<math.pi*(2/4+1/8) then curspr=2 end
	if self.dir<math.pi*(1/4+1/8) then curspr=1 end
	if self.dir<math.pi*1/8 then curspr=8 end

	--spr(1+t%60//30*2,x,y,14,1,0,0,1,1)
	spr(curspr,self.x,self.y,0,1,0,0,1,1)
	spr(0,indx,indy,0,1,0,0,1,1)
	if DEV then
		print(debugtxt,self.x+8,self.y+8,15,false,1,true)
	end
	-- fx
	local driftt=t-self.lastdrift
	if self.pstate=="drift" then
		circb(self.x+4,self.y+4,7+(driftt/7)%8,14+(driftt/7)%2)
	elseif self.pstate=="boost" then
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
	cls(13)
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
-- 000:0000000000000000000000000006e000000e6000000000000000000000000000
-- 001:00000040004000f000f00f4f0fff07ff0f4ff3347fff74400433440000440000
-- 002:00fff00000fff00000f770000fffff000ffff700037ff4000443440000444000
-- 003:040000000f000400f4f00f00ff70fff0433ff4f00447fff70044334000004400
-- 004:00000040040000f70ff00ffff4ff0f4fff77ff77444344440044444000000000
-- 005:00000040000000f700400fff00f7ff4700ff07ff0f47f334f7ff344400444400
-- 006:000fff00000fff00000fff0000fffff000777f70000333000004340000004000
-- 007:040000007f000000fff0040074ff7f00ff70ff00433f74f04443ff7f00444400
-- 008:040000007f000040fff00ff0f4f0ff4f77ff77ff444434440444440000000000
-- </TILES>

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
-- 000:140c1c44243430346d815d30593c28346524d04648d6d6b6597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

