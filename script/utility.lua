Auxiliary={}
aux=Auxiliary

function Auxiliary.Stringid(code,id)
	return code*16+id
end
function Auxiliary.Next(g)
	local first=true
	return	function()
				if first then first=false return g:GetFirst()
				else return g:GetNext() end
			end
end
function Auxiliary.NULL()
end
function Auxiliary.TRUE()
	return true
end
function Auxiliary.FALSE()
	return false
end
function Auxiliary.AND(f1,f2)
	return	function(a,b,c)
				return f1(a,b,c) and f2(a,b,c)
			end
end
function Auxiliary.OR(f1,f2)
	return	function(a,b,c)
				return f1(a,b,c) or f2(a,b,c)
			end
end
function Auxiliary.NOT(f)
	return	function(a,b,c)
				return not f(a,b,c)
			end
end
function Auxiliary.IsDualState(effect)
	local c=effect:GetHandler()
	return not c:IsDisabled() and c:IsDualState()
end
function Auxiliary.IsNotDualState(effect)
	local c=effect:GetHandle()
	return c:IsDisabled() or not c:IsDualState()
end
function Auxiliary.DualNormalCondition(effect)
	local c=effect:GetHandler()
	return c:IsFaceup() and not c:IsDualState()
end
function Auxiliary.BeginPuzzle(effect)
	local e1=Effect.GlobalEffect()
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TURN_END)
	e1:SetCountLimit(1)
	e1:SetOperation(Auxiliary.PuzzleOp)
	Duel.RegisterEffect(e1,0)
	local e2=Effect.GlobalEffect()
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_SKIP_DP)
	e2:SetTargetRange(1,0)
	Duel.RegisterEffect(e2,0)
	local e3=Effect.GlobalEffect()
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_SKIP_SP)
	e3:SetTargetRange(1,0)
	Duel.RegisterEffect(e3,0)
end
function Auxiliary.PuzzleOp(e,tp)
	Duel.SetLP(0,0)
end
function Auxiliary.EnableDualAttribute(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DUAL_SUMMONABLE)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_ADD_TYPE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e2:SetCondition(aux.DualNormalCondition)
	e2:SetValue(TYPE_NORMAL)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_REMOVE_TYPE)
	e3:SetValue(TYPE_EFFECT)
	c:RegisterEffect(e3)
end
function Auxiliary.TargetEqualFunction(f,value,a,b,c)
	return	function(effect,target)
				return f(target,a,b,c)==value
			end
end
function Auxiliary.TargetBoolFunction(f,a,b,c)
	return	function(effect,target)
				return f(target,a,b,c)
			end
end
function Auxiliary.FilterEqualFunction(f,value,a,b,c)
	return	function(target)
				return f(target,a,b,c)==value
			end
end
function Auxiliary.FilterBoolFunction(f,a,b,c)
	return	function(target)
				return f(target,a,b,c)
			end
end
function Auxiliary.NonTuner(f,a,b,c)
	return	function(target)
				return target:IsNotTuner() and (not f or f(target,a,b,c))
			end
end
--Synchro monster, 1 tuner + n or more monsters
function Auxiliary.AddSynchroProcedure(c,f1,f2,ct)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(Auxiliary.SynCondition(f1,f2,ct,99))
	e1:SetTarget(Auxiliary.SynTarget(f1,f2,ct,99))
	e1:SetOperation(Auxiliary.SynOperation(f1,f2,ct,99))
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)
end
function Auxiliary.SynCondition(f1,f2,minct,maxc)
	return	function(e,c,smat,mg)
				if c==nil then return true end
				if c:IsType(TYPE_PENDULUM) and c:IsFaceup() then return false end
				local ft=Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)
				local ct=-ft
				local minc=minct
				if minc<ct then minc=ct end
				if maxc<minc then return false end
				if smat and smat:IsType(TYPE_TUNER) and (not f1 or f1(smat)) then
					return Duel.CheckTunerMaterial(c,smat,f1,f2,minc,maxc,mg) end
				return Duel.CheckSynchroMaterial(c,f1,f2,minc,maxc,smat,mg)
			end
end
function Auxiliary.SynTarget(f1,f2,minct,maxc)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
				local g=nil
				local ft=Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)
				local ct=-ft
				local minc=minct
				if minc<ct then minc=ct end
				if smat and smat:IsType(TYPE_TUNER) and (not f1 or f1(smat)) then
					g=Duel.SelectTunerMaterial(c:GetControler(),c,smat,f1,f2,minc,maxc,mg)
				else
					g=Duel.SelectSynchroMaterial(c:GetControler(),c,f1,f2,minc,maxc,smat,mg)
				end
				if g then
					g:KeepAlive()
					e:SetLabelObject(g)
					return true
				else return false end
			end
end
function Auxiliary.SynOperation(f1,f2,minct,maxc)
	return	function(e,tp,eg,ep,ev,re,r,rp,c,smat,mg)
				local g=e:GetLabelObject()
				c:SetMaterial(g)
				Duel.SendtoGrave(g,REASON_MATERIAL+REASON_SYNCHRO)
				g:DeleteGroup()
			end
end
--Synchro monster, 1 tuner + 1 monster
function Auxiliary.AddSynchroProcedure2(c,f1,f2)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(Auxiliary.SynCondition(f1,f2,1,1))
	e1:SetTarget(Auxiliary.SynTarget(f1,f2,1,1))
	e1:SetOperation(Auxiliary.SynOperation(f1,f2,1,1))
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)
end
function Auxiliary.XyzAlterFilter(c,alterf,xyzc)
	return alterf(c) and c:IsCanBeXyzMaterial(xyzc)
end
--Xyz monster, lv k*n
--set c.xyz_filter, c.xyz_count
function Auxiliary.AddXyzProcedure(c,f,lv,ct,alterf,desc,maxct,op)
	if c.xyz_filter==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		if f then
			mt.xyz_filter=function(mc) return f(mc) and mc:IsXyzLevel(c,lv) end
		else
			mt.xyz_filter=function(mc) return mc:IsXyzLevel(c,lv) end
		end
		mt.xyz_count=ct
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	if not maxct then maxct=ct end
	if alterf then
		e1:SetCondition(Auxiliary.XyzCondition2(f,lv,ct,maxct,alterf,desc,op))
		e1:SetTarget(Auxiliary.XyzTarget2(f,lv,ct,maxct,alterf,desc,op))
		e1:SetOperation(Auxiliary.XyzOperation2(f,lv,ct,maxct,alterf,desc,op))
	else
		e1:SetCondition(Auxiliary.XyzCondition(f,lv,ct,maxct))
		e1:SetTarget(Auxiliary.XyzTarget(f,lv,ct,maxct))
		e1:SetOperation(Auxiliary.XyzOperation(f,lv,ct,maxct))
	end
	e1:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e1)
end
--Xyz Summon(normnal)
function Auxiliary.XyzCondition(f,lv,minc,maxc)
	--og: use special material
	return	function(e,c,og)
				if c==nil then return true end
				if c:IsType(TYPE_PENDULUM) and c:IsFaceup() then return false end
				local ft=Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)
				local ct=-ft
				if minc<=ct then return false end
				return Duel.CheckXyzMaterial(c,f,lv,minc,maxc,og)
			end
end
function Auxiliary.XyzTarget(f,lv,minc,maxc)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk,c,og)
				if og then
					return true
				else
					local g=Duel.SelectXyzMaterial(tp,c,f,lv,minc,maxc)
					if g then
						g:KeepAlive()
						e:SetLabelObject(g)
						return true
					else return false end
				end
			end
end
function Auxiliary.XyzOperation(f,lv,minc,maxc)
	return	function(e,tp,eg,ep,ev,re,r,rp,c,og)
				if og then
					local sg=Group.CreateGroup()
					local tc=og:GetFirst()
					while tc do
						local sg1=tc:GetOverlayGroup()
						sg:Merge(sg1)
						tc=og:GetNext()
					end
					Duel.SendtoGrave(sg,REASON_RULE)
					c:SetMaterial(og)
					Duel.Overlay(c,og)
				else
					local mg=e:GetLabelObject()
					local sg=Group.CreateGroup()
					local tc=mg:GetFirst()
					while tc do
						local sg1=tc:GetOverlayGroup()
						sg:Merge(sg1)
						tc=mg:GetNext()
					end
					Duel.SendtoGrave(sg,REASON_RULE)
					c:SetMaterial(mg)
					Duel.Overlay(c,mg)
					mg:DeleteGroup()
				end
			end
end
--Xyz summon(alterf)
function Auxiliary.XyzCondition2(f,lv,minc,maxc,alterf,desc,op)
	return	function(e,c,og)
				if c==nil then return true end
				if c:IsType(TYPE_PENDULUM) and c:IsFaceup() then return false end
				local tp=c:GetControler()
				local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
				local ct=-ft
				if minc<=ct then return false end
				if ct<1 and not og and Duel.IsExistingMatchingCard(Auxiliary.XyzAlterFilter,tp,LOCATION_MZONE,0,1,nil,alterf,c)
					and (not op or op(e,tp,0)) then
					return true
				end
				return Duel.CheckXyzMaterial(c,f,lv,minc,maxc,og)
			end
end
function Auxiliary.XyzTarget2(f,lv,minc,maxc,alterf,desc,op)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk,c,og)
				if og then
					return true
				else
					local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
					local ct=-ft
					local b1=Duel.CheckXyzMaterial(c,f,lv,minc,maxc,og)
					local b2=ct<1 and Duel.IsExistingMatchingCard(Auxiliary.XyzAlterFilter,tp,LOCATION_MZONE,0,1,nil,alterf,c)
						and (not op or op(e,tp,0))
					if b2 and (not b1 or Duel.SelectYesNo(tp,desc)) then
						e:SetLabel(1)
						return true
					else
						e:SetLabel(0)
						local g=Duel.SelectXyzMaterial(tp,c,f,lv,minc,maxc)
						if g then
							g:KeepAlive()
							e:SetLabelObject(g)
							return true
						else return false end
					end
				end
			end
end
function Auxiliary.XyzOperation2(f,lv,minc,maxc,alterf,desc,op)
	return	function(e,tp,eg,ep,ev,re,r,rp,c,og)
				if og then
					local sg=Group.CreateGroup()
					local tc=og:GetFirst()
					while tc do
						local sg1=tc:GetOverlayGroup()
						sg:Merge(sg1)
						tc=og:GetNext()
					end
					Duel.SendtoGrave(sg,REASON_RULE)
					c:SetMaterial(og)
					Duel.Overlay(c,og)
				else
					if e:GetLabel()==1 then
						if op then op(e,tp,1) end
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
						local mg=Duel.SelectMatchingCard(tp,Auxiliary.XyzAlterFilter,tp,LOCATION_MZONE,0,1,1,nil,alterf,c)
						local mg2=mg:GetFirst():GetOverlayGroup()
						if mg2:GetCount()~=0 then
							Duel.Overlay(c,mg2)
						end
						c:SetMaterial(mg)
						Duel.Overlay(c,mg)
					else
						local mg=e:GetLabelObject()
						local sg=Group.CreateGroup()
						local tc=mg:GetFirst()
						while tc do
							local sg1=tc:GetOverlayGroup()
							sg:Merge(sg1)
							tc=mg:GetNext()
						end
						Duel.SendtoGrave(sg,REASON_RULE)
						c:SetMaterial(mg)
						Duel.Overlay(c,mg)
						mg:DeleteGroup()
					end
				end
			end
end
function Auxiliary.FConditionCheckF(c,chkf)
	return c:IsOnField() and c:IsControler(chkf)
end
--Fusion monster, name + name
--material_count: number of different names in material list
--material: names in material list
function Auxiliary.AddFusionProcCode2(c,code1,code2,sub,insf)
	if c.material_count==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.material_count=2
		mt.material={code1,code2}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionCode2(code1,code2,sub,insf))
	e1:SetOperation(Auxiliary.FOperationCode2(code1,code2,sub,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilter12(c,code,sub)
	return c:IsFusionCode(code) or (sub and c:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
end
function Auxiliary.FConditionFilter21(c,code1,code2)
	return c:IsFusionCode(code1) or c:IsFusionCode(code2)
end
function Auxiliary.FConditionFilter22(c,code1,code2,sub)
	return c:IsFusionCode(code1) or c:IsFusionCode(code2) or (sub and c:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
end
function Auxiliary.FConditionCode2(code1,code2,sub,insf)
	--g:Material group(nil for Instant Fusion)
	--gc:Material already used
	--chkf: check field, default:PLAYER_NONE
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,gc,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					local b1=0 local b2=0 local bw=0
					if gc:IsFusionCode(code1) then b1=1 end
					if gc:IsFusionCode(code2) then b2=1 end
					if sub and gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then bw=1 end
					if b1+b2+bw==0 then return false end
					if chkf~=PLAYER_NONE and not Auxiliary.FConditionCheckF(gc,chkf) then
						mg=mg:Filter(Auxiliary.FConditionCheckF,nil,chkf)
					end
					if b1+b2+bw>1 then
						return mg:IsExists(Auxiliary.FConditionFilter22,1,nil,code1,code2,sub)
					elseif b1==1 then
						return mg:IsExists(Auxiliary.FConditionFilter12,1,nil,code2,sub)
					elseif b2==1 then
						return mg:IsExists(Auxiliary.FConditionFilter12,1,nil,code1,sub)
					else
						return mg:IsExists(Auxiliary.FConditionFilter21,1,nil,code1,code2)
					end
				end
				local b1=0 local b2=0 local bw=0
				local ct=0
				local fs=chkf==PLAYER_NONE
				local tc=mg:GetFirst()
				while tc do
					local match=false
					if tc:IsFusionCode(code1) then b1=1 match=true end
					if tc:IsFusionCode(code2) then b2=1 match=true end
					if sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then bw=1 match=true end
					if match then
						if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
						ct=ct+1
					end
					tc=mg:GetNext()
				end
				return ct>1 and b1+b2+bw>1 and fs
			end
end
function Auxiliary.FOperationCode2(code1,code2,sub,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,gc,e:GetHandler())
				local tc=gc
				local g1=nil
				if gc then
					if chkf~=PLAYER_NONE and not Auxiliary.FConditionCheckF(gc,chkf) then
						g=g:Filter(Auxiliary.FConditionCheckF,nil,chkf)
					end
				else
					local sg=g:Filter(Auxiliary.FConditionFilter22,nil,code1,code2,sub)
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					if chkf~=PLAYER_NONE then g1=sg:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf)
					else g1=sg:Select(tp,1,1,nil) end
					tc=g1:GetFirst()
					g:RemoveCard(tc)
				end
				local b1=0 local b2=0 local bw=0
				if tc:IsFusionCode(code1) then b1=1 end
				if tc:IsFusionCode(code2) then b2=1 end
				if sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then bw=1 end
				local g2=nil
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				if b1+b2+bw>1 then
					g2=g:FilterSelect(tp,Auxiliary.FConditionFilter22,1,1,nil,code1,code2,sub)
				elseif b1==1 then
					g2=g:FilterSelect(tp,Auxiliary.FConditionFilter12,1,1,nil,code2,sub)
				elseif b2==1 then
					g2=g:FilterSelect(tp,Auxiliary.FConditionFilter12,1,1,nil,code1,sub)
				else
					g2=g:FilterSelect(tp,Auxiliary.FConditionFilter21,1,1,nil,code1,code2)
				end
				if g1 then g2:Merge(g1) end
				Duel.SetFusionMaterial(g2)
			end
end
--Fusion monster, name + name + name
function Auxiliary.AddFusionProcCode3(c,code1,code2,code3,sub,insf)
	if c.material_count==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.material_count=3
		mt.material={code1,code2,code3}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionCode3(code1,code2,code3,sub,insf))
	e1:SetOperation(Auxiliary.FOperationCode3(code1,code2,code3,sub,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilter31(c,code1,code2,code3)
	return c:IsFusionCode(code1) or c:IsFusionCode(code2) or c:IsFusionCode(code3)
end
function Auxiliary.FConditionFilter32(c,code1,code2,code3,sub)
	return c:IsFusionCode(code1) or c:IsFusionCode(code2) or c:IsFusionCode(code3) or (sub and c:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
end
function Auxiliary.FConditionCode3(code1,code2,code3,sub,insf)
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					local b1=0 local b2=0 local b3=0
					local tc=mg:GetFirst()
					while tc do
						if tc:IsFusionCode(code1) then b1=1
						elseif tc:IsFusionCode(code2) then b2=1
						elseif tc:IsFusionCode(code3) then b3=1
						end
						tc=mg:GetNext()
					end
					if gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
						return b1+b2+b3>1
					else
						if gc:IsFusionCode(code1) then b1=1
						elseif gc:IsFusionCode(code2) then b2=1
						elseif gc:IsFusionCode(code3) then b3=1
						else return false
						end
						return b1+b2+b3>2
					end
				end
				local b1=0 local b2=0 local b3=0 local bs=0
				local fs=false
				local tc=mg:GetFirst()
				while tc do
					if tc:IsFusionCode(code1) then b1=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif tc:IsFusionCode(code2) then b2=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif tc:IsFusionCode(code3) then b3=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then bs=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					end
					tc=mg:GetNext()
				end
				return b1+b2+b3+bs>=3 and (fs or chkf==PLAYER_NONE)
			end
end
function Auxiliary.FOperationCode3(code1,code2,code3,sub,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					local sg=g:Filter(Auxiliary.FConditionFilter31,gc,code1,code2,code3)
					if not gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
						sg:Remove(Card.IsFusionCode,nil,gc:GetCode())
					end
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=sg:Select(tp,1,1,nil)
					sg:Remove(Card.IsFusionCode,nil,g1:GetFirst():GetCode())
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g2=sg:Select(tp,1,1,nil)
					g1:Merge(g2)
					Duel.SetFusionMaterial(g1)
					return
				end
				local sg=g:Filter(Auxiliary.FConditionFilter32,nil,code1,code2,code3,sub)
				local g1=nil
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				if chkf~=PLAYER_NONE then g1=sg:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf)
				else g1=sg:Select(tp,1,1,nil) end
				if g1:GetFirst():IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
					sg:Remove(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
				else sg:Remove(Card.IsFusionCode,nil,g1:GetFirst():GetCode()) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g2=sg:Select(tp,1,1,nil)
				if g2:GetFirst():IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
					sg:Remove(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
				else sg:Remove(Card.IsFusionCode,nil,g2:GetFirst():GetCode()) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g3=sg:Select(tp,1,1,nil)
				g1:Merge(g2)
				g1:Merge(g3)
				Duel.SetFusionMaterial(g1)
			end
end
--Fusion monster, name + name + name + name
function Auxiliary.AddFusionProcCode4(c,code1,code2,code3,code4,sub,insf)
	if c.material_count==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.material_count=4
		mt.material={code1,code2,code3,code4}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionCode4(code1,code2,code3,code4,sub,insf))
	e1:SetOperation(Auxiliary.FOperationCode4(code1,code2,code3,code4,sub,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilter41(c,code1,code2,code3,code4)
	return c:IsFusionCode(code1) or c:IsFusionCode(code2) or c:IsFusionCode(code3) or c:IsFusionCode(code4)
end
function Auxiliary.FConditionFilter42(c,code1,code2,code3,code4,sub)
	return c:IsFusionCode(code1) or c:IsFusionCode(code2) or c:IsFusionCode(code3) or c:IsFusionCode(code4) or (sub and c:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
end
function Auxiliary.FConditionCode4(code1,code2,code3,code4,sub,insf)
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					local b1=0 local b2=0 local b3=0 local b4=0
					local tc=mg:GetFirst()
					while tc do
						if tc:IsFusionCode(code1) then b1=1
						elseif tc:IsFusionCode(code2) then b2=1
						elseif tc:IsFusionCode(code3) then b3=1
						elseif tc:IsFusionCode(code4) then b4=1
						else return false
						end
						tc=mg:GetNext()
					end
					if gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
						return b1+b2+b3+b4>2
					else
						if gc:IsFusionCode(code1) then b1=1
						elseif gc:IsFusionCode(code2) then b2=1
						elseif gc:IsFusionCode(code3) then b3=1
						elseif gc:IsFusionCode(code4) then b4=1
						end
						return b1+b2+b3+b4>3
					end
				end
				local b1=0 local b2=0 local b3=0 local b4=0 local bs=0
				local fs=false
				local tc=mg:GetFirst()
				while tc do
					if tc:IsFusionCode(code1) then b1=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif tc:IsFusionCode(code2) then b2=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif tc:IsFusionCode(code3) then b3=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif tc:IsFusionCode(code4) then b4=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					elseif sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then bs=1 if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
					end
					tc=mg:GetNext()
				end
				return b1+b2+b3+b4+bs>=4 and (fs or chkf==PLAYER_NONE)
			end
end
function Auxiliary.FOperationCode4(code1,code2,code3,code4,sub,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					local sg=g:Filter(Auxiliary.FConditionFilter41,gc,code1,code2,code3,code4)
					if not gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
						sg:Remove(Card.IsFusionCode,nil,gc:GetCode())
					end
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=sg:Select(tp,1,1,nil)
					sg:Remove(Card.IsFusionCode,nil,g1:GetFirst():GetCode())
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g2=sg:Select(tp,1,1,nil)
					sg:Remove(Card.IsFusionCode,nil,g2:GetFirst():GetCode())
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g3=sg:Select(tp,1,1,nil)
					g1:Merge(g2)
					g1:Merge(g3)
					Duel.SetFusionMaterial(g1)
					return
				end
				local sg=g:Filter(Auxiliary.FConditionFilter42,nil,code1,code2,code3,code4,sub)
				local g1=nil
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				if chkf~=PLAYER_NONE then g1=sg:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf)
				else g1=sg:Select(tp,1,1,nil) end
				if g1:GetFirst():IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
					sg:Remove(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
				else sg:Remove(Card.IsFusionCode,nil,g1:GetFirst():GetCode()) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g2=sg:Select(tp,1,1,nil)
				if g2:GetFirst():IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
					sg:Remove(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
				else sg:Remove(Card.IsFusionCode,nil,g2:GetFirst():GetCode()) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g3=sg:Select(tp,1,1,nil)
				if g3:GetFirst():IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then
					sg:Remove(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
				else sg:Remove(Card.IsFusionCode,nil,g3:GetFirst():GetCode()) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g4=sg:Select(tp,1,1,nil)
				g1:Merge(g2)
				g1:Merge(g3)
				g1:Merge(g4)
				Duel.SetFusionMaterial(g1)
			end
end
--Fusion monster, name + condition
function Auxiliary.AddFusionProcCodeFun(c,code1,f,cc,sub,insf)
	if c.material_count==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.material_count=1
		mt.material={code1}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionCodeFun(code1,f,cc,sub,insf))
	e1:SetOperation(Auxiliary.FOperationCodeFun(code1,f,cc,sub,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilterCF(c,g2,cc)
	return g2:IsExists(aux.TRUE,cc,c)
end
function Auxiliary.FConditionCodeFun(code,f,cc,sub,insf)
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					if (gc:IsFusionCode(code) or (sub and gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))) and mg:IsExists(f,cc,gc) then
						return true
					elseif f(gc) then
						local g1=Group.CreateGroup() local g2=Group.CreateGroup()
						local tc=mg:GetFirst()
						while tc do
							if tc:IsFusionCode(code) or (sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
								then g1:AddCard(tc) end
							if f(tc) then g2:AddCard(tc) end
							tc=mg:GetNext()
						end
						if cc>1 then
							g2:RemoveCard(gc)
							return g1:IsExists(Auxiliary.FConditionFilterCF,1,gc,g2,cc-1)
						else
							g1:RemoveCard(gc)
							return g1:GetCount()>0
						end
					else return false end
				end
				local b1=0 local b2=0 local bw=0
				local fs=false
				local tc=mg:GetFirst()
				while tc do
					local c1=tc:IsFusionCode(code) or (sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
					local c2=f(tc)
					if c1 or c2 then
						if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end
						if c1 and c2 then bw=bw+1
						elseif c1 then b1=1
						else b2=b2+1
						end
					end
					tc=mg:GetNext()
				end
				if b2>cc then b2=cc end
				return b1+b2+bw>=1+cc and (fs or chkf==PLAYER_NONE)
			end
end
function Auxiliary.FOperationCodeFun(code,f,cc,sub,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if (gc:IsFusionCode(code) or (sub and gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))) and g:IsExists(f,cc,gc) then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
						local g1=g:FilterSelect(tp,f,cc,cc,gc)
						Duel.SetFusionMaterial(g1)
					else
						local sg1=Group.CreateGroup() local sg2=Group.CreateGroup()
						local tc=g:GetFirst()
						while tc do
							if tc:IsFusionCode(code) or (sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE)) then sg1:AddCard(tc) end
							if f(tc) then sg2:AddCard(tc) end
							tc=g:GetNext()
						end
						if cc>1 then
							sg2:RemoveCard(gc)
							if sg2:GetCount()==cc-1 then
								sg1:Sub(sg2)
							end
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
							local g1=sg1:Select(tp,1,1,gc)
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
							local g2=sg2:Select(tp,cc-1,cc-1,g1:GetFirst())
							g1:Merge(g2)
							Duel.SetFusionMaterial(g1)
						else
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
							local g1=sg1:Select(tp,1,1,gc)
							Duel.SetFusionMaterial(g1)
						end
					end
					return
				end
				local sg1=Group.CreateGroup() local sg2=Group.CreateGroup() local fs=false
				local tc=g:GetFirst()
				while tc do
					if tc:IsFusionCode(code) or (sub and tc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE)) then sg1:AddCard(tc) end
					if f(tc) then sg2:AddCard(tc) if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end end
					tc=g:GetNext()
				end
				if chkf~=PLAYER_NONE then
					if sg2:GetCount()==cc then
						sg1:Sub(sg2)
					end
					local g1=nil
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					if fs then g1=sg1:Select(tp,1,1,nil)
					else g1=sg1:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf) end
					local tc1=g1:GetFirst()
					sg2:RemoveCard(tc1)
					if Auxiliary.FConditionCheckF(tc1,chkf) or sg2:GetCount()==cc then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
						local g2=sg2:Select(tp,cc,cc,tc1)
						g1:Merge(g2)
					else
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
						local g2=sg2:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,tc1,chkf)
						g1:Merge(g2)
						if cc>1 then
							sg2:RemoveCard(g2:GetFirst())
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
							g2=sg2:Select(tp,cc-1,cc-1,tc1)
							g1:Merge(g2)
						end
					end
					Duel.SetFusionMaterial(g1)
				else
					if sg2:GetCount()==cc then
						sg1:Sub(sg2)
					end
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=sg1:Select(tp,1,1,nil)
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					g1:Merge(sg2:Select(tp,cc,cc,g1:GetFirst()))
					Duel.SetFusionMaterial(g1)
				end
			end
end
--Fusion monster, condition + condition
function Auxiliary.AddFusionProcFun2(c,f1,f2,insf)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionFun2(f1,f2,insf))
	e1:SetOperation(Auxiliary.FOperationFun2(f1,f2,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilterF2(c,g2)
	return g2:IsExists(aux.TRUE,1,c)
end
function Auxiliary.FConditionFilterF2c(c,f1,f2)
	return f1(c) or f2(c)
end
function Auxiliary.FConditionFilterF2r(c,f1,f2)
	return f1(c) and not f2(c)
end
function Auxiliary.FConditionFun2(f1,f2,insf)
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					return (f1(gc) and mg:IsExists(f2,1,gc))
						or (f2(gc) and mg:IsExists(f1,1,gc)) end
				local g1=Group.CreateGroup() local g2=Group.CreateGroup() local fs=false
				local tc=mg:GetFirst()
				while tc do
					if f1(tc) then g1:AddCard(tc) if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end end
					if f2(tc) then g2:AddCard(tc) if Auxiliary.FConditionCheckF(tc,chkf) then fs=true end end
					tc=mg:GetNext()
				end
				if chkf~=PLAYER_NONE then
					return fs and g1:IsExists(Auxiliary.FConditionFilterF2,1,nil,g2)
				else return g1:IsExists(Auxiliary.FConditionFilterF2,1,nil,g2) end
			end
end
function Auxiliary.FOperationFun2(f1,f2,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					local sg=Group.CreateGroup()
					if f1(gc) then sg:Merge(g:Filter(f2,gc)) end
					if f2(gc) then sg:Merge(g:Filter(f1,gc)) end
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=sg:Select(tp,1,1,nil)
					Duel.SetFusionMaterial(g1)
					return
				end
				local sg=g:Filter(Auxiliary.FConditionFilterF2c,nil,f1,f2)
				local g1=nil
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				if chkf~=PLAYER_NONE then
					g1=sg:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf)
				else g1=sg:Select(tp,1,1,nil) end
				local tc1=g1:GetFirst()
				sg:RemoveCard(tc1)
				local b1=f1(tc1)
				local b2=f2(tc1)
				if b1 and not b2 then sg:Remove(Auxiliary.FConditionFilterF2r,nil,f1,f2) end
				if b2 and not b1 then sg:Remove(Auxiliary.FConditionFilterF2r,nil,f2,f1) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g2=sg:Select(tp,1,1,nil)
				g1:Merge(g2)
				Duel.SetFusionMaterial(g1)
			end
end
--Fusion monster, name * n
function Auxiliary.AddFusionProcCodeRep(c,code1,cc,sub,insf)
	if c.material_count==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.material_count=1
		mt.material={code1}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionCodeRep(code1,cc,sub,insf))
	e1:SetOperation(Auxiliary.FOperationCodeRep(code1,cc,sub,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilterCR(c,code,sub)
	return c:IsFusionCode(code) or (sub and c:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
end
function Auxiliary.FConditionCodeRep(code,cc,sub,insf)
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					return (gc:IsFusionCode(code) or gc:IsHasEffect(EFFECT_FUSION_SUBSTITUTE)) and mg:IsExists(Card.IsFusionCode,cc-1,gc,code) end
				local g1=mg:Filter(Card.IsFusionCode,nil,code)
				if not sub then
					if chkf~=PLAYER_NONE then return g1:GetCount()>=cc and g1:FilterCount(Card.IsOnField,nil)~=0
					else return g1:GetCount()>=cc end
				end
				local g2=mg:Filter(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
				if chkf~=PLAYER_NONE then
					return (g1:FilterCount(Card.IsOnField,nil)~=0 or g2:FilterCount(Card.IsOnField,nil)~=0)
						and g1:GetCount()>=cc-1 and g1:GetCount()+g2:GetCount()>=cc
				else return g1:GetCount()>=cc-1 and g1:GetCount()+g2:GetCount()>=cc end
			end
end
function Auxiliary.FOperationCodeRep(code,cc,sub,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=g:FilterSelect(tp,Card.IsFusionCode,cc-1,cc-1,gc,code)
					Duel.SetFusionMaterial(g1)
					return
				end
				local sg=g:Filter(Auxiliary.FConditionFilterCR,nil,code,sub)
				local g1=nil
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				if chkf~=PLAYER_NONE then g1=sg:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf)
				else g1=sg:Select(tp,1,1,nil) end
				local tc1=g1:GetFirst()
				for i=1,cc-1 do
					if tc1:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then sg:Remove(Card.IsHasEffect,nil,EFFECT_FUSION_SUBSTITUTE)
					else sg:RemoveCard(tc1) end
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g2=sg:Select(tp,1,1,nil)
					tc1=g2:GetFirst()
					g1:Merge(g2)
				end
				Duel.SetFusionMaterial(g1)
			end
end
--Fusion monster, condition * n
function Auxiliary.AddFusionProcFunRep(c,f,cc,insf)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionFunRep(f,cc,insf))
	e1:SetOperation(Auxiliary.FOperationFunRep(f,cc,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFunRep(f,cc,insf)
	return	function(e,g,gc,chkf)
				if g==nil then return insf end
				local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
					return f(gc) and mg:IsExists(f,cc-1,gc) end
				local g1=mg:Filter(f,nil)
				if chkf~=PLAYER_NONE then
					return g1:FilterCount(Card.IsOnField,nil)~=0 and g1:GetCount()>=cc
				else return g1:GetCount()>=cc end
			end
end
function Auxiliary.FOperationFunRep(f,cc,insf)
	return	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
				local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
				if gc then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=g:FilterSelect(tp,f,cc-1,cc-1,gc)
					Duel.SetFusionMaterial(g1)
					return
				end
				local sg=g:Filter(f,nil)
				if chkf==PLAYER_NONE or sg:GetCount()==cc then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g1=sg:Select(tp,cc,cc,nil)
					Duel.SetFusionMaterial(g1)
					return
				end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local g1=sg:FilterSelect(tp,Auxiliary.FConditionCheckF,1,1,nil,chkf)
				if cc>1 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
					local g2=sg:Select(tp,cc-1,cc-1,g1:GetFirst())
					g1:Merge(g2)
				end
				Duel.SetFusionMaterial(g1)
			end
end
--Fusion monster, condition1 + condition2 * minc to maxc
function Auxiliary.AddFusionProcFunFunRep(c,f1,f2,minc,maxc,insf)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionFunFunRep(f1,f2,minc,maxc,insf))
	e1:SetOperation(Auxiliary.FOperationFunFunRep(f1,f2,minc,maxc,insf))
	c:RegisterEffect(e1)
end
function Auxiliary.FConditionFilterFFR(c,f1,f2,mg,minc,chkf)
	if not f1(c) then return false end
	if chkf==PLAYER_NONE or aux.FConditionCheckF(c,chkf) then
		return minc<=0 or mg:IsExists(f2,minc,c)
	else
		local mg2=mg:Filter(f2,c)
		return mg2:GetCount()>=minc and mg2:IsExists(aux.FConditionCheckF,1,nil,chkf)
	end
end
function Auxiliary.FConditionFunFunRep(f1,f2,minc,maxc,insf)
	return	function(e,g,gc,chkf)
			if g==nil then return insf end
			local mg=g:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
			if gc then
				if not gc:IsCanBeFusionMaterial(e:GetHandler()) then return false end
				if aux.FConditionFilterFFR(gc,f1,f2,mg,minc,chkf) then
					return true
				elseif f2(gc) then
					mg:RemoveCard(gc)
					if aux.FConditionCheckF(gc,chkf) then chkf=PLAYER_NONE end
					return mg:IsExists(aux.FConditionFilterFFR,1,nil,f1,f2,mg,minc-1,chkf)
				else return false end
			end
			return mg:IsExists(aux.FConditionFilterFFR,1,nil,f1,f2,mg,minc,chkf)
		end
end
function Auxiliary.FOperationFunFunRep(f1,f2,minc,maxc,insf)
	return 	function(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
			local g=eg:Filter(Card.IsCanBeFusionMaterial,nil,e:GetHandler())
			local minct=minc
			local maxct=maxc
			if gc then
				g:RemoveCard(gc)
				if aux.FConditionFilterFFR(gc,f1,f2,g,minct,chkf) then
					if aux.FConditionCheckF(gc,chkf) then chkf=PLAYER_NONE end
					local g1=Group.CreateGroup()
					if f2(gc) then
						local mg1=g:Filter(aux.FConditionFilterFFR,nil,f1,f2,g,minct-1,chkf)
						if mg1:GetCount()>0 then
							--if gc fits both, should allow an extra material that fits f1 but doesn't fit f2
							local mg2=g:Filter(f2,nil)
							mg1:Merge(mg2)
							if chkf~=PLAYER_NONE then
								Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
								local sg=mg1:FilterSelect(tp,aux.FConditionCheckF,1,1,nil,chkf)
								g1:Merge(sg)
								mg1:Sub(sg)
								minct=minct-1
								maxct=maxct-1
								if not f2(sg:GetFirst()) then
									if mg1:GetCount()>0 and maxct>0 and (minct>0 or Duel.SelectYesNo(tp,93)) then
										if minct<=0 then minct=1 end
										Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
										local sg=mg1:FilterSelect(tp,f2,minct,maxct,nil)
										g1:Merge(sg)
									end
									Duel.SetFusionMaterial(g1)
									return
								end
							end
							if maxct>1 and (minct>1 or Duel.SelectYesNo(tp,93)) then
								Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
								local sg=mg1:FilterSelect(tp,f2,minct-1,maxct-1,nil)
								g1:Merge(sg)
								mg1:Sub(sg)
								local ct=sg:GetCount()
								minct=minct-ct
								maxct=maxct-ct
							end
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
							local sg=mg1:Select(tp,1,1,nil)
							g1:Merge(sg)
							mg1:Sub(sg)
							minct=minct-1
							maxct=maxct-1
							if mg1:GetCount()>0 and maxct>0 and (minct>0 or Duel.SelectYesNo(tp,93)) then
								if minct<=0 then minct=1 end
								Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
								local sg=mg1:FilterSelect(tp,f2,minct,maxct,nil)
								g1:Merge(sg)
							end
							Duel.SetFusionMaterial(g1)
							return
						end
					end
					local mg=g:Filter(f2,nil)
					if chkf~=PLAYER_NONE then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
						local sg=mg:FilterSelect(tp,aux.FConditionCheckF,1,1,nil,chkf)
						g1:Merge(sg)
						mg:Sub(sg)
						minct=minct-1
						maxct=maxct-1
					end
					if mg:GetCount()>0 and maxct>0 and (minct>0 or Duel.SelectYesNo(tp,93)) then
						if minct<=0 then minct=1 end
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
						local sg=mg:Select(tp,minct,maxct,nil)
						g1:Merge(sg)
					end
					Duel.SetFusionMaterial(g1)
					return
				else
					if aux.FConditionCheckF(gc,chkf) then chkf=PLAYER_NONE end
					minct=minct-1
					maxct=maxct-1
				end
			end
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
			local g1=g:FilterSelect(tp,aux.FConditionFilterFFR,1,1,nil,f1,f2,g,minct,chkf)
			local mg=g:Filter(f2,g1:GetFirst())
			if chkf~=PLAYER_NONE and not aux.FConditionCheckF(g1:GetFirst(),chkf) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local sg=mg:FilterSelect(tp,aux.FConditionCheckF,1,1,nil,chkf)
				g1:Merge(sg)
				mg:Sub(sg)
				minct=minct-1
				maxct=maxct-1
			end
			if mg:GetCount()>0 and maxct>0 and (minct>0 or Duel.SelectYesNo(tp,93)) then
				if minct<=0 then minct=1 end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
				local sg=mg:Select(tp,minct,maxct,nil)
				g1:Merge(sg)
			end
			Duel.SetFusionMaterial(g1)
		end
end
function Auxiliary.FilterBoolFunctionCFR(code,sub)
	return	function(target)
				return target:IsFusionCode(code) or (sub and target:IsHasEffect(EFFECT_FUSION_SUBSTITUTE))
			end
end
--Fusion monster, name + condition * minc to maxc
function Auxiliary.AddFusionProcCodeFunRep(c,code1,f,minc,maxc,sub,insf)
	if c.material_count==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.material_count=1
		mt.material={code1}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_FUSION_MATERIAL)
	e1:SetCondition(Auxiliary.FConditionFunFunRep(Auxiliary.FilterBoolFunctionCFR(code1,sub),f,minc,maxc,insf))
	e1:SetOperation(Auxiliary.FOperationFunFunRep(Auxiliary.FilterBoolFunctionCFR(code1,sub),f,minc,maxc,insf))
	c:RegisterEffect(e1)
end
--Ritual Summon, geq fixed lv
function Auxiliary.AddRitualProcGreater(c,filter)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(Auxiliary.RPGTarget(filter))
	e1:SetOperation(Auxiliary.RPGOperation(filter))
	c:RegisterEffect(e1)
end
function Auxiliary.RPGFilter(c,filter,e,tp,m,ft)
	if (filter and not filter(c)) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) then return false end
	local mg=m:Filter(Card.IsCanBeRitualMaterial,c,c)
	if ft>0 then
		return mg:CheckWithSumGreater(Card.GetRitualLevel,c:GetOriginalLevel(),c)
	else
		return mg:IsExists(Auxiliary.RPGFilterF,1,nil,tp,mg,c)
	end
end
function Auxiliary.RPGFilterF(c,tp,mg,rc)
	if c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) then
		Duel.SetSelectedCard(c)
		return mg:CheckWithSumGreater(Card.GetRitualLevel,rc:GetOriginalLevel(),rc)
	else return false end
end
function Auxiliary.RPGTarget(filter)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then
					local mg=Duel.GetRitualMaterial(tp)
					local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
					return ft>-1 and Duel.IsExistingMatchingCard(Auxiliary.RPGFilter,tp,LOCATION_HAND,0,1,nil,filter,e,tp,mg,ft)
				end
				Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
			end
end
function Auxiliary.RPGOperation(filter)
	return	function(e,tp,eg,ep,ev,re,r,rp)
				local mg=Duel.GetRitualMaterial(tp)
				local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local tg=Duel.SelectMatchingCard(tp,Auxiliary.RPGFilter,tp,LOCATION_HAND,0,1,1,nil,filter,e,tp,mg,ft)
				local tc=tg:GetFirst()
				if tc then
					mg=mg:Filter(Card.IsCanBeRitualMaterial,tc,tc)
					local mat=nil
					if ft>0 then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						mat=mg:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetOriginalLevel(),tc)
					else
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						mat=mg:FilterSelect(tp,Auxiliary.RPGFilterF,1,1,nil,tp,mg,tc)
						Duel.SetSelectedCard(mat)
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						local mat2=mg:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetOriginalLevel(),tc)
						mat:Merge(mat2)
					end
					tc:SetMaterial(mat)
					Duel.ReleaseRitualMaterial(mat)
					Duel.BreakEffect()
					Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
					tc:CompleteProcedure()
				end
			end
end
function Auxiliary.AddRitualProcGreaterCode(c,code1)
	if not c:IsStatus(STATUS_COPYING_EFFECT) and c.fit_monster==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.fit_monster={code1}
	end
	Auxiliary.AddRitualProcGreater(c,Auxiliary.FilterBoolFunction(Card.IsCode,code1))
end
--Ritual Summon, equal to fixed lv
function Auxiliary.AddRitualProcEqual(c,filter)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(Auxiliary.RPETarget(filter))
	e1:SetOperation(Auxiliary.RPEOperation(filter))
	c:RegisterEffect(e1)
end
function Auxiliary.RPEFilter(c,filter,e,tp,m,ft)
	if (filter and not filter(c)) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) then return false end
	local mg=m:Filter(Card.IsCanBeRitualMaterial,c,c)
	if ft>0 then
		return mg:CheckWithSumEqual(Card.GetRitualLevel,c:GetOriginalLevel(),1,99,c)
	else
		return mg:IsExists(Auxiliary.RPEFilterF,1,nil,tp,mg,c)
	end
end
function Auxiliary.RPEFilterF(c,tp,mg,rc)
	if c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) then
		Duel.SetSelectedCard(c)
		return mg:CheckWithSumEqual(Card.GetRitualLevel,rc:GetOriginalLevel(),0,99,rc)
	else return false end
end
function Auxiliary.RPETarget(filter)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then
					local mg=Duel.GetRitualMaterial(tp)
					local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
					return ft>-1 and Duel.IsExistingMatchingCard(Auxiliary.RPEFilter,tp,LOCATION_HAND,0,1,nil,filter,e,tp,mg,ft)
				end
				Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
			end
end
function Auxiliary.RPEOperation(filter)
	return	function(e,tp,eg,ep,ev,re,r,rp)
				local mg=Duel.GetRitualMaterial(tp)
				local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local tg=Duel.SelectMatchingCard(tp,Auxiliary.RPEFilter,tp,LOCATION_HAND,0,1,1,nil,filter,e,tp,mg,ft)
				local tc=tg:GetFirst()
				if tc then
					mg=mg:Filter(Card.IsCanBeRitualMaterial,tc,tc)
					local mat=nil
					if ft>0 then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						mat=mg:SelectWithSumEqual(tp,Card.GetRitualLevel,tc:GetOriginalLevel(),1,99,tc)
					else
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						mat=mg:FilterSelect(tp,Auxiliary.RPEFilterF,1,1,nil,tp,mg,tc)
						Duel.SetSelectedCard(mat)
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						local mat2=mg:SelectWithSumEqual(tp,Card.GetRitualLevel,tc:GetOriginalLevel(),0,99,tc)
						mat:Merge(mat2)
					end
					tc:SetMaterial(mat)
					Duel.ReleaseRitualMaterial(mat)
					Duel.BreakEffect()
					Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
					tc:CompleteProcedure()
				end
			end
end
function Auxiliary.AddRitualProcEqualCode(c,code1)
	if not c:IsStatus(STATUS_COPYING_EFFECT) and c.fit_monster==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.fit_monster={code1}
	end
	Auxiliary.AddRitualProcEqual(c,Auxiliary.FilterBoolFunction(Card.IsCode,code1))
end
--Ritual Summon, equal to monster lv
function Auxiliary.AddRitualProcEqual2(c,filter)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(Auxiliary.RPETarget2(filter))
	e1:SetOperation(Auxiliary.RPEOperation2(filter))
	c:RegisterEffect(e1)
end
function Auxiliary.RPEFilter2(c,filter,e,tp,m,ft)
	if (filter and not filter(c)) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) then return false end
	local mg=m:Filter(Card.IsCanBeRitualMaterial,c,c)
	if ft>0 then
		return mg:CheckWithSumEqual(Card.GetRitualLevel,c:GetLevel(),1,99,c)
	else
		return mg:IsExists(Auxiliary.RPEFilter2F,1,nil,tp,mg,c)
	end
end
function Auxiliary.RPEFilter2F(c,tp,mg,rc)
	if c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) then
		Duel.SetSelectedCard(c)
		return mg:CheckWithSumEqual(Card.GetRitualLevel,rc:GetLevel(),0,99,rc)
	else return false end
end
function Auxiliary.RPETarget2(filter)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then
					local mg=Duel.GetRitualMaterial(tp)
					local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
					return ft>-1 and Duel.IsExistingMatchingCard(Auxiliary.RPEFilter2,tp,LOCATION_HAND,0,1,nil,filter,e,tp,mg,ft)
				end
				Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
			end
end
function Auxiliary.RPEOperation2(filter)
	return	function(e,tp,eg,ep,ev,re,r,rp)
				local mg=Duel.GetRitualMaterial(tp)
				local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local tg=Duel.SelectMatchingCard(tp,Auxiliary.RPEFilter2,tp,LOCATION_HAND,0,1,1,nil,filter,e,tp,mg,ft)
				local tc=tg:GetFirst()
				if tc then
					mg=mg:Filter(Card.IsCanBeRitualMaterial,tc,tc)
					local mat=nil
					if ft>0 then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						mat=mg:SelectWithSumEqual(tp,Card.GetRitualLevel,tc:GetLevel(),1,99,tc)
					else
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						mat=mg:FilterSelect(tp,Auxiliary.RPEFilter2F,1,1,nil,tp,mg,tc)
						Duel.SetSelectedCard(mat)
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
						local mat2=mg:SelectWithSumEqual(tp,Card.GetRitualLevel,tc:GetLevel(),0,99,tc)
						mat:Merge(mat2)
					end
					tc:SetMaterial(mat)
					Duel.ReleaseRitualMaterial(mat)
					Duel.BreakEffect()
					Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
					tc:CompleteProcedure()
				end
			end
end
function Auxiliary.AddRitualProcEqual2Code(c,code1)
	if not c:IsStatus(STATUS_COPYING_EFFECT) and c.fit_monster==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.fit_monster={code1}
	end
	Auxiliary.AddRitualProcEqual2(c,Auxiliary.FilterBoolFunction(Card.IsCode,code1))
end
function Auxiliary.AddRitualProcEqual2Code2(c,code1,code2)
	if not c:IsStatus(STATUS_COPYING_EFFECT) and c.fit_monster==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.fit_monster={code1,code2}
	end
	Auxiliary.AddRitualProcEqual2(c,Auxiliary.FilterBoolFunction(Card.IsCode,code1,code2))
end
--add procedure to Pendulum monster, also allows registeration of activation effect
function Auxiliary.EnablePendulumAttribute(c,reg)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC_G)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,10000000)
	e1:SetCondition(Auxiliary.PendCondition())
	e1:SetOperation(Auxiliary.PendOperation())
	e1:SetValue(SUMMON_TYPE_PENDULUM)
	c:RegisterEffect(e1)
	--register by default
	if reg==nil or reg then
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(1160)
		e2:SetType(EFFECT_TYPE_ACTIVATE)
		e2:SetCode(EVENT_FREE_CHAIN)
		c:RegisterEffect(e2)
	end
end
function Auxiliary.PConditionFilter(c,e,tp,lscale,rscale)
	local lv=0
	if c.pendulum_level then
		lv=c.pendulum_level
	else
		lv=c:GetLevel()
	end
	return (c:IsLocation(LOCATION_HAND) or (c:IsFaceup() and c:IsType(TYPE_PENDULUM)))
		and lv>lscale and lv<rscale and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_PENDULUM,tp,false,false)
		and not c:IsForbidden()
end
function Auxiliary.PendCondition()
	return	function(e,c,og)
				if c==nil then return true end
				local tp=c:GetControler()
				if c:GetSequence()~=6 then return false end
				local rpz=Duel.GetFieldCard(tp,LOCATION_SZONE,7)
				if rpz==nil then return false end
				local lscale=c:GetLeftScale()
				local rscale=rpz:GetRightScale()
				if lscale>rscale then lscale,rscale=rscale,lscale end
				local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
				if ft<=0 then return false end
				if og then
					return og:IsExists(Auxiliary.PConditionFilter,1,nil,e,tp,lscale,rscale)
				else
					if Duel.IsPlayerAffectedByEffect(tp,29724053) then
						--If the player is affected by Summon Gate's effect, Pendulum Summon is possible if there is a Pendulum Summonable monster in the hand or if the player can still summon from the Extra Deck
						return Duel.IsExistingMatchingCard(Auxiliary.PConditionFilter,tp,LOCATION_HAND,0,1,nil,e,tp,lscale,rscale) or (c29724053[tp]>0 and Duel.IsExistingMatchingCard(Auxiliary.PConditionFilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil,e,tp,lscale,rscale))
					else
						--If Summon Gate is not in play, everything proceeds as usual
						return Duel.IsExistingMatchingCard(Auxiliary.PConditionFilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil,e,tp,lscale,rscale)
					end
				end
			end
end
function Auxiliary.PendOperation()
	return	function(e,tp,eg,ep,ev,re,r,rp,c,sg,og)
				local rpz=Duel.GetFieldCard(tp,LOCATION_SZONE,7)
				local lscale=c:GetLeftScale()
				local rscale=rpz:GetRightScale()
				if lscale>rscale then lscale,rscale=rscale,lscale end
				local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
				if Duel.IsPlayerAffectedByEffect(tp,59822133) then ft=math.min(ft,1) end
				if og then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
					local g=og:FilterSelect(tp,Auxiliary.PConditionFilter,1,ft,nil,e,tp,lscale,rscale)
					sg:Merge(g)
				else
					if Duel.IsPlayerAffectedByEffect(tp,29724053) then
						--If the player is affected by Summon Gate's effect...
						local g=Duel.GetMatchingGroup(Auxiliary.PConditionFilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,nil,e,tp,lscale,rscale)
						if g:GetCount()==0 then return end
						local xg=g:Filter(Card.IsLocation,nil,LOCATION_EXTRA) --Summonable cards in Extra
						local hg=g:Filter(Card.IsLocation,nil,LOCATION_HAND) --Summonable cards in hand
						if xg:GetCount()>0 and c29724053[tp]>0 and (hg:GetCount()==0 or Duel.SelectYesNo(tp,aux.Stringid(29724053,0))) then
							--If there are monsters in the Extra Deck and the player can summon and wants to summon from the Extra Deck...
							--NOTE: If there are no Pendulum Summonable monsters in the hand, the procedure allows to summon from the Extra without asking
							local xct=math.min(ft,c29724053[tp])
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
							local xsg=xg:Select(tp,1,xct,nil)
							local rl=ft-xsg:GetCount() --Remaining locations
							sg:Merge(xsg)
							if hg:GetCount()>0 and rl>0 and Duel.SelectYesNo(tp,aux.Stringid(29724053,1)) then
								--If there are summonable monsters in the hand as well and the user can and wants to continue to summon...
								Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
								local hsg=hg:Select(tp,1,rl,nil)
								sg:Merge(hsg)
							end
						else
							--If there are no valid monsters in the Extra Deck, or the user wants to summon from hand only...
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
							local hsg=hg:Select(tp,1,ft,nil)
							sg:Merge(hsg)
						end
					else
						--If Summon Gate is not in play, everything proceeds as usual
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
						local g=Duel.SelectMatchingCard(tp,Auxiliary.PConditionFilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,ft,nil,e,tp,lscale,rscale)
						sg:Merge(g)
					end
				end
				Duel.HintSelection(Group.FromCards(c))
				Duel.HintSelection(Group.FromCards(rpz))
			end
end
function Auxiliary.IsMaterialListCode(c,code)
	if not c.material then return false end
	for i,mcode in ipairs(c.material) do
		if code==mcode then return true end
	end
	return false
end
function Auxiliary.IsMaterialListSetCard(c,setcode)
	return c.material_setcode and c.material_setcode==setcode
end
--card effect disable filter(target)
function Auxiliary.disfilter1(c)
	return c:IsFaceup() and not c:IsDisabled() and (not c:IsType(TYPE_NORMAL) or bit.band(c:GetOriginalType(),TYPE_EFFECT)~=0)
end
--condition of EVENT_BATTLE_DESTROYING
function Auxiliary.bdcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle()
end
--condition of EVENT_BATTLE_DESTROYING + opponent monster
function Auxiliary.bdocon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle() and c:IsStatus(STATUS_OPPO_BATTLE)
end
--condition of EVENT_BATTLE_DESTROYING + to_grave
function Auxiliary.bdgcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end
--condition of EVENT_BATTLE_DESTROYING + opponent monster + to_grave
function Auxiliary.bdogcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and c:IsStatus(STATUS_OPPO_BATTLE) and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end
--condition of "cannot be negated"
function Auxiliary.nfbdncon(e)
	return not e:GetHandler():IsForbidden()
end
--condition of "except the turn this card was sent to the Graveyard"
function Auxiliary.exccon(e)
	return Duel.GetTurnCount()~=e:GetHandler():GetTurnID() or e:GetHandler():IsReason(REASON_RETURN)
end
--flag effect for spell counter
function Auxiliary.chainreg(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():GetFlagEffect(1)==0 then
		e:GetHandler():RegisterFlagEffect(1,RESET_EVENT+0x1fc0000+RESET_CHAIN,0,1)
	end
end
--default filter for EFFECT_CANNOT_BE_BATTLE_TARGET/EFFECT_MUST_BE_ATTACKED
function Auxiliary.imval1(e,c)
	return not c:IsImmuneToEffect(e)
end
--default filter for EFFECT_CANNOT_BE_EFFECT_TARGET
function Auxiliary.tgval(e,re,rp)
	return not re:GetHandler():IsImmuneToEffect(e)
end
--filter for EFFECT_CANNOT_BE_EFFECT_TARGET + opponent 
function Auxiliary.tgoval(e,re,rp)
	return rp~=e:GetHandlerPlayer() and not re:GetHandler():IsImmuneToEffect(e)
end
--filter for non-zero ATK 
function Auxiliary.nzatk(c)
	return c:IsFaceup() and c:GetAttack()>0
end
--filter for non-zero DEF
function Auxiliary.nzdef(c)
	return c:IsFaceup() and c:GetDefence()>0
end
--flag effect for summon/sp_summon turn
function Auxiliary.sumreg(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	local code=e:GetLabel()
	while tc do
		if tc:GetOriginalCode()==code then 
			tc:RegisterFlagEffect(code,RESET_EVENT+0x1ec0000+RESET_PHASE+PHASE_END,0,1) 
		end
		tc=eg:GetNext()
	end
end
--sp_summon condition for fusion monster
function Auxiliary.fuslimit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
end
--sp_summon condition for ritual monster
function Auxiliary.ritlimit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_RITUAL)==SUMMON_TYPE_RITUAL
end
--sp_summon condition for synchro monster
function Auxiliary.synlimit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_SYNCHRO)==SUMMON_TYPE_SYNCHRO
end
--sp_summon condition for xyz monster
function Auxiliary.xyzlimit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_XYZ)==SUMMON_TYPE_XYZ
end
--sp_summon condition for pendulum monster
function Auxiliary.penlimit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end
--effects inflicting damage to tp
function Auxiliary.damcon1(e,tp,eg,ep,ev,re,r,rp)
	local e1=Duel.IsPlayerAffectedByEffect(tp,EFFECT_REVERSE_DAMAGE)
	local e2=Duel.IsPlayerAffectedByEffect(tp,EFFECT_REVERSE_RECOVER)
	local rd=e1 and not e2
	local rr=not e1 and e2
	local ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_DAMAGE)
	if ex and (cp==tp or cp==PLAYER_ALL) and not rd and not Duel.IsPlayerAffectedByEffect(tp,EFFECT_NO_EFFECT_DAMAGE) then 
		return true 
	end
	ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_RECOVER)
	return ex and (cp==tp or cp==PLAYER_ALL) and rr and not Duel.IsPlayerAffectedByEffect(tp,EFFECT_NO_EFFECT_DAMAGE)
end
--filter for the immune effetc of qli monsters
function Auxiliary.qlifilter(e,te)
	if te:IsActiveType(TYPE_MONSTER) and te:IsActivated() then
		local lv=e:GetHandler():GetLevel()
		local ec=te:GetOwner()
		if ec:IsType(TYPE_XYZ) then
			return ec:GetOriginalRank()<lv
		else
			return ec:GetOriginalLevel()<lv
		end
	else
		return false
	end
end
--filter for necro_valley test
function Auxiliary.nvfilter(c)
	return not c:IsHasEffect(EFFECT_NECRO_VALLEY)
end
--Kaiju Limit Condition
function Auxiliary.AddKaijuLimitCondition(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ADJUST)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(Auxiliary.KaijuCondition())
	e1:SetOperation(Auxiliary.KaijuAdjustOperation())
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1,0)
	e2:SetCondition(Auxiliary.KaijuCondition())
	e2:SetTarget(Auxiliary.KaijuSummonLimit())
	--c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	--c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	--c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	e5:SetCondition(Auxiliary.KaijuSummonLimit2())
	c:RegisterEffect(e5)
	--local e6=e5:Clone()
	--e6:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	--c:RegisterEffect(e6)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e6:SetCode(EFFECT_SPSUMMON_CONDITION)
	e6:SetCondition(Auxiliary.KaijuSummonLimit2())
	e6:SetValue(Auxiliary.KaijuSpLimit())
	c:RegisterEffect(e6)
	local e7=e5:Clone()
	e7:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e7)
	local e7b=e5:Clone()
	e7b:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e7b)
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_FIELD)
	e8:SetCode(EFFECT_SELF_DESTROY)
	e8:SetRange(LOCATION_MZONE)
	e8:SetTargetRange(LOCATION_MZONE,0)
	e8:SetCondition(Auxiliary.KaijuCondition())
	e8:SetTarget(Auxiliary.KaijuSDTarget())
	c:RegisterEffect(e8)
	local g=Group.CreateGroup()
	g:KeepAlive()
	e1:SetLabelObject(g)
end
function Auxiliary.KaijuAdjustFilter(c,g,pg)
	if pg:IsContains(c) then return false end
	return g:IsExists(Card.IsSetCard,1,c,0xd3) or pg:IsExists(Card.IsSetCard,1,c,0xd3)
end
function Auxiliary.KaijuAdjustOperation()
	return function(e,tp,eg,ep,ev,re,r,rp)
		local phase=Duel.GetCurrentPhase()
		if (phase==PHASE_DAMAGE and not Duel.IsDamageCalculated()) or phase==PHASE_DAMAGE_CAL then return end
		local c=e:GetHandler()
		local pg=e:GetLabelObject()
		local flag=e:GetCode()
		if c:GetFlagEffect(flag)==0 then
			c:RegisterFlagEffect(flag,RESET_EVENT+0x1ff0000,0,1)
			pg:Clear()
		end
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,c)
		local dg=g:Filter(Auxiliary.KaijuAdjustFilter,c,g,e:GetLabelObject())
		--Debug.Message("Cards to be destroyed because of "..flag..": "..dg:GetCount())
		if dg:GetCount()==0 or Duel.Destroy(dg,REASON_EFFECT)==0 then
			pg:Clear()
			pg:Merge(g)
			pg:Sub(dg)
		else
			g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
			pg:Clear()
			pg:Merge(g)
			pg:Sub(dg)
			Duel.Readjust()
		end
	end
end
function Auxiliary.KaijuCondition()
	return function(e)
		return e:GetHandler():IsSetCard(0xd3)
	end
end
function Auxiliary.KaijuSummonFilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd3)
end
function Auxiliary.KaijuSummonLimit()
	return function(e,c,sump,sumtype,sumpos,targetp)
		--if targetp then Debug.Message("Target player: "..targetp) end
		--return c:IsSetCard(0xd3) and (targetp==c:GetControler() or Duel.IsExistingMatchingCard(Auxiliary.KaijuSummonFilter,targetp,LOCATION_MZONE,0,1,nil))
		return c:IsSetCard(0xd3) and sumtype==SUMMON_TYPE_SPECIAL
	end
end
function Auxiliary.KaijuSummonLimit2()
	return function(e)
		return Duel.IsExistingMatchingCard(Auxiliary.KaijuSummonFilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil) and e:GetHandler():IsSetCard(0xd3)
	end
end
function Auxiliary.KaijuSDTarget()
	return function(e,c)
		return c:IsSetCard(0xd3) and c:GetFieldID()>e:GetHandler():GetFieldID()
	end
end
function Auxiliary.KaijuSpLimit()
	return function(e,se,sp,st)
		local sc=se:GetHandler()
		return sc==e:GetHandler() or (sc:IsSetCard(0xd3) and se:IsActiveType(TYPE_SPELL+TYPE_TRAP))
	end
end
--Function to check the summon method used for the card. Credit goes to Cute-Nekomimi
function Card.IsSummonType(c,t)
	return bit.band(c:GetSummonType(),t)==t
end

pcall(dofile,"init.lua")
