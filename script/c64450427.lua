--ＥＭウィム・ウィッチ
--Performapal Whim Witch
--Scripted by Eerie Code
function c64450427.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	--
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(64450427,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetCountLimit(1,64450427)
	e1:SetCondition(c64450427.spcon)
	e1:SetTarget(c64450427.sptg)
	e1:SetOperation(c64450427.spop)
	c:RegisterEffect(e1)
	--
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DOUBLE_TRIBUTE)
	e2:SetValue(c64450427.tricon)
	c:RegisterEffect(e2)
end

function c64450427.spfil(c)
	return c:IsFaceup() and c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:GetPreviousLocation()==LOCATION_EXTRA
end
function c64450427.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(c64450427.spfil,tp,0,LOCATION_MZONE,1,nil) and not Duel.IsExistingMatchingCard(c64450427.spfil,tp,LOCATION_MZONE,0,1,nil)
end
function c64450427.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function c64450427.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<1 or not c:IsRelateToEffect(e) then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end

function c64450427.tricon(e,c)
	return c:IsType(TYPE_PENDULUM)
end