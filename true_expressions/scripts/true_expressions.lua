function getCharacter(name)
    for _, vChar in pairs(DB.getChildren("charsheet")) do
        local sChar = DB.getValue(vChar, "name", "");
        if sChar == name then
            local mod = "bonus";
            local level = DB.getValue(vChar, "level", "");
            local abilities = DB.getChildren(vChar, "abilities");
            local strength = DB.getValue(abilities.strength, mod, "");
            local dexterity = DB.getValue(abilities.dexterity, mod, "");
            local constitution = DB.getValue(abilities.constitution, mod, "");
            local intelligence = DB.getValue(abilities.intelligence, mod, "");
            local wisdom = DB.getValue(abilities.wisdom, mod, "");
            local charisma = DB.getValue(abilities.charisma, mod, "");
            return {LVL = level, STR = strength, DEX = dexterity, CON = constitution, INT = intelligence, WIS = wisdom, CHA = charisma};
        end
    end
end

function replaceCharacterValues(sName)
    local codedLine = sName;
    local name_tag = codedLine:match("%[NAME|([^]]+)%]");
    if name_tag then
        local character = getCharacter(name_tag);
        if character then
            for key, value in pairs(character) do
                codedLine = codedLine:gsub("%[" .. key .. "%]", value);
            end
            codedLine = codedLine:gsub("%[NAME|" .. name_tag .. "%]", "");
        end
    end
    return codedLine;
end

function hasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true;
        end
    end
    return false;
end

local rollable = {"INIT", "ATK", "CMB", "DMG", "DMGS", "HEAL", "ABIL", "DMGO", "FHEAL", "REGEN", "SKILL"};
function isRollabe(modifier)
    return hasValue(rollable, modifier);
end

local numberable = {"CC", "AC", "CMD", "SAVE", "CLC", "STR", "DEX", "CON", "INT", "WIS", "CHA", "DR", "RESIST", "VULN", "NLVL", "SPEED"};
function isNumberable(modifier)
    return hasValue(numberable, modifier);
end

function evaluateRollable(rollVal)
    local lexer = dice_parser.make_lexer(rollVal);
    local token = lexer.peek();
    local last_die = 0;
    local rebuilt = "";
    while token.kind ~= dice_parser.PARSER_TOKEN_EOF do
        if token.kind == dice_parser.PARSER_TOKEN_DIE then
            rebuilt = rebuilt .. dice_parser.evaluate(rollVal:sub(last_die + 1, token.location - 1)) .. "d";
            last_die = token.location;
        end
        lexer.advance();
        token = lexer.peek();
    end
    rebuilt = rebuilt .. dice_parser.evaluate(rollVal:sub(last_die + 1));
    return rebuilt;
end

local plausibleExtras = {"alchemical", "armor", "circumstance", "competence", "deflection", "dodge", "enhancement", "insight", "luck", "morale", "natural", "profane", "racial", "resistance", "sacred", "shield", "size", "melee", "ranged", "acid", "cold", "electricity", "fire", "sonic", "force", "negative", "positive", "adamantine", "bludgeoning", "cold iron", "epic", "magic", "piercing", "silver", "slashing", "chaotic", "evil", "good", "lawful", "nonlethal", "spellcraft", "spell", "strength", "constitution", "dexterity", "intelligence", "wisdom", "charisma", "acrobatics", "appraise", "bluff", "climb", "craft", "diplomacy", "disable device", "disguise", "escape artist", "fly", "handle animal", "heal", "intimidate", "knowledge", "linguistics", "perception", "profession", "ride", "sense motive", "sleight of hand", "stealth", "survival", "swim", "use magic device", "opportunity", "all"};
function splitAndEvaluate(sName)
    local codedLine = sName;
    local rebuilt = "";
    for section in string.gmatch(codedLine, "([^"..";".."]+)") do
        if string.find(section, ":") then
            local modifier = string.match(section, "^.+:");
            modifier = modifier:sub(1, modifier:len() -1);
            modifier = modifier:match( "^%s*(.-)%s*$" );
            local rollVal = string.match(section, ":.+");
            rollVal = string.sub(rollVal, 2);
            local extras = " ";
            for i, val in ipairs(plausibleExtras) do
                if string.find(rollVal, val) then
                    rollVal = rollVal:gsub(val, "");
                    extras = extras .. val .. ",";
                end
            end
            extras = extras:sub(1, extras:len() - 1);
            rollVal = rollVal:gsub("[,\s]+$", "");
            if isNumberable(modifier) then
                rebuilt = rebuilt .. modifier .. ":" .. dice_parser.evaluate(rollVal) .. extras .. ";";
            elseif isRollabe(modifier) then
                rebuilt = rebuilt .. modifier .. ":" .. evaluateRollable(rollVal) .. extras .. ";";
            else
                rebuilt = rebuilt .. modifier .. ":" .. rollVal .. extras .. ";";
            end
        else
            rebuilt = rebuilt .. section .. ";";
        end
    end
    return rebuilt;
end

function onEffectTextAddStart(rEffect)
    EffectManager35E.onEffectAddStart(rEffect);
    Debug.console("Original: ", rEffect.sName);
    rEffect.sName = replaceCharacterValues(rEffect.sName);
    Debug.console("Replaced: ", rEffect.sName);
    rEffect.sName = splitAndEvaluate(rEffect.sName);
    Debug.console("Result: ", rEffect.sName);
end

function onInit()
    EffectManager.setCustomOnEffectAddStart(onEffectTextAddStart);
end
