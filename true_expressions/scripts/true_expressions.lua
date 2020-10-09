function getCharacter(name)
    for _, vChar in pairs(DB.getChildren("charsheet")) do
        local sChar = DB.getValue(vChar, "name", "");
        if sChar == name then
            local mod = "bonus"
            local level = DB.getValue(vChar, "level", "");
            local abilities = DB.getChildren(vChar, "abilities");
            local strength = DB.getValue(abilities.strength, mod, "");
            local dexterity = DB.getValue(abilities.dexterity, mod, "");
            local constitution = DB.getValue(abilities.constitution, mod, "");
            local intelligence = DB.getValue(abilities.intelligence, mod, "");
            local wisdom = DB.getValue(abilities.wisdom, mod, "");
            local charisma = DB.getValue(abilities.charisma, mod, "");
            return {level = level, strength = strength, dexterity = dexterity, constitution = constitution, intelligence = intelligence, wisdom = wisdom, charisma = charisma};
        end
    end
end

function onEffectTextAddStart(rEffect)
    local name_tag = rEffect.sName:match("%[NAME|([^]]+)%]");
    if name_tag then
        local character = getCharacter(name_tag);
        if character then
            rEffect.sName = rEffect.sName:gsub("%[CLVL%]", character.level);
            rEffect.sName = rEffect.sName:gsub("%[CSTR%]", character.strength);
            rEffect.sName = rEffect.sName:gsub("%[CDEX%]", character.dexterity);
            rEffect.sName = rEffect.sName:gsub("%[CCON%]", character.constitution);
            rEffect.sName = rEffect.sName:gsub("%[CINT%]", character.intelligence);
            rEffect.sName = rEffect.sName:gsub("%[CWIS%]", character.wisdom);
            rEffect.sName = rEffect.sName:gsub("%[CCHA%]", character.charisma);
            rEffect.sName = rEffect.sName:gsub("%[NAME|" .. name_tag .. "%]", "");
        end
    end
end

function onInit()
    EffectManager.setCustomOnEffectAddStart(onEffectTextAddStart);
end