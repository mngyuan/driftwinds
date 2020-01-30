-- title:		drift winds
-- author:	mngyuan
-- desc:		top down battle racer
-- script:	lua

t=0
x=96
y=24
spd,dir=0,0
rspd=0.04
maxspd,accamt,decamt=0.8,0.05,1.02
pstate="free"
pstates={"free", "drift", "boost"}
driftvec,driftside,lastdrift=0,"m",0
boostspds={8,8,6,5,3,3,3,2.5,1.25,0.9}
boost,lastboost,boostcd=false,-80,80
boostx,boosty=0,0

function TIC()
	local accel=false
	local turnl,turnr=false,false

	if btn(0) then accel=true end
	if btn(1) then accel=false end
	if btn(2) then turnl=true end
	if btn(3) then turnr=true end
	if btn(4) then
		if pstate=="free" and t-boostcd > lastboost then
			driftvec=dir
			pstate="drift"
			if turnl then driftside="l"
			elseif turnr then driftside="r"
			end
			lastdrift=t
		end
	else
		if pstate=="drift" then
			if t-boostcd > lastboost then
				lastboost=t
				pstate="boost"
				boostx=x
				boosty=y
			else
				pstate="free"
				driftside="m"
			end
		end
	end
	
	if accel then
		spd=math.min(spd+accamt,maxspd)
	elseif pstate=="free" then
		spd=spd/decamt
	elseif pstate=="drift" then
		spd=spd/(1+(decamt)/2)
	end
	if turnl then
		if pstate=="free" then
			dir=dir+rspd
		elseif pstate=="drift" then
			dir=dir+2*rspd
			if driftside=="l" then
				driftvec=driftvec+rspd/0.8
			elseif driftside=="r" then
				driftvec=driftvec-rspd/2.5
			else
				driftvec=driftvec+rspd/2
			end
		end
	elseif turnr then
		if pstate=="free" then
			dir=dir-rspd
		elseif pstate=="drift" then
			dir=dir-2*rspd
			if driftside=="r" then
				driftvec=driftvec-rspd/0.8
			elseif driftside=="l" then
				driftvec=driftvec+rspd/2.5
			else
				driftvec=driftvec-rspd/2
			end
		end
	elseif pstate=="drift" then
		if driftside=="r" then
			driftvec=driftvec-rspd
		elseif driftside=="l" then
			driftvec=driftvec+rspd
		end
	end
	dir=dir%(math.pi*2)
	driftvec=driftvec%(math.pi*2)
	
	-- drifting suspends normal movement
	if pstate=="drift" then
		x=x+spd*math.cos(driftvec)
		y=y-spd*math.sin(driftvec)
	elseif pstate=="boost" then
		spd=boostspds[t-lastboost+1]
		if spd==nil then
			spd=maxspd
			pstate="free"
			driftside="m"
		end
		x=x+spd*math.cos(dir)
		y=y-spd*math.sin(dir)
	else
		x=x+spd*math.cos(dir)
		y=y-spd*math.sin(dir)
	end
	indx=x+15*math.cos(dir)
	indy=y-15*math.sin(dir)
	driftindx=x+10*math.cos(driftvec)
	driftindy=y-10*math.sin(driftvec)
	
	if dir<math.pi*2 then curspr=8 end
	if dir<math.pi*(7/4+1/8) then curspr=7 end
	if dir<math.pi*(6/4+1/8) then curspr=6 end
	if dir<math.pi*(5/4+1/8) then curspr=5 end
	if dir<math.pi*(1+1/8) then curspr=4 end
	if dir<math.pi*(3/4+1/8) then curspr=3 end
	if dir<math.pi*(2/4+1/8) then curspr=2 end
	if dir<math.pi*(1/4+1/8) then curspr=1 end
	if dir<math.pi*1/8 then curspr=8 end

	cls(13)
	--spr(1+t%60//30*2,x,y,14,1,0,0,1,1)
	spr(curspr,x,y,0,1,0,0,1,1)
	spr(0,indx,indy,0,1,0,0,1,1)
	-- fx
	driftt=t-lastdrift
	if pstate=="drift" then
		circb(x+4,y+4,7+(driftt/7)%8,14+(driftt/7)%2)
		circb(driftindx+4,driftindy+4,2,14+(driftt/3)%2)
	elseif pstate=="boost" then
		if lastboost==t then sfx(0,'C-4') end
		if lastboost + 12 > t then
			boostdestx=boostx+30*math.cos(dir)
			boostdesty=boosty-30*math.sin(dir)
			line(boostx+4,boosty+4,boostdestx+4,boostdesty+4,14+(driftt/3)%2)
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

