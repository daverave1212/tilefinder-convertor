using System;
using System.Text.Json;


public class Stats {

    public int health = 0;
    public int mana = 0;
    public int damage = 0;
    public int armor = 0;
    public int crit = 0;
    public int dodge = 0;
    public int spellPower = 0;
    public int manaRegeneration = 0;
    public int speed = 0;
    public int initiative = 0;

    public Stats(Stats s=null) {
        if (s != null) {
            copy(s);
        }
    }

    public string ToJson() {
        return JsonSerializer.Serialize(this);
    }

    public static string[] Keys() {
        return new string[] { "health", "mana", "damage", "spellPower", "armor", "manaRegeneration", "crit", "dodge", "initiative", "speed" };
    }
    public static string[] GetStatNamesPretty() {
        return new string[] { "Health", "Mana", "Damage", "Spell Power", "Armor", "Mana Regen", "Crit", "Dodge", "Initiative", "Speed" };
    }

    public void ForEach(Action<string, int> func) {
        var statNames = GetStatNamesPretty();
        int[] statValues = { health, mana, damage, spellPower, armor, manaRegeneration, crit, dodge, initiative, speed };
        for (int i = 0; i < statNames.Length; i++) {
            func(statNames[i], statValues[i]);
        }
    }

    public void AddStat(string statName, int value) {
        Set(statName, Get(statName) + value);
    }

    public void Set(string statName, int value) {
        switch (statName) {
            case "health"			:	health = value; break;
            case "damage"			:	damage = value; break;
            case "armor"			:	armor = value; break;
            case "crit"				:	crit = value; break;
            case "dodge"			:	dodge = value; break;
            case "initiative"		:	initiative = value; break;
            case "mana"				:	mana = value; break;
            case "spellPower"		:	spellPower = value; break;
            case "manaRegeneration"	:	mana = value; break;
            case "speed"			:	speed = value; break;
            Console.WriteLine($"WARNING: Stat {statName} not found for set");
        }
    }
    public int Get(string statName) {
        switch (statName) {
            case "health"			:	return health; break;
            case "damage"			:	return damage; break;
            case "armor"			:	return armor; break;
            case "crit"				:	return crit; break;
            case "dodge"			:	return dodge; break;
            case "initiative"		:	return initiative; break;
            case "mana"				:	return mana; break;
            case "spellPower"		:	return spellPower; break;
            case "manaRegeneration"	:	return manaRegeneration; break;
            case "speed"			:	return speed; break;
            Console.WriteLine($"WARNING: Stat {statName} not found for get");
        }
    }

    public void ForEachNonZero(Action<string, int> func) {
        ForEach((name, value) => {
            if (value != 0) func(name, value);
        });
    }
    public bool AreAllZero() {
        var nNonZeroStats = 0;
        ForEachNonZero((_, _) -> nNonZeroStats++);
        return nNonZeroStats == 0;
    }
    public int GetNumberOfNonZeroStats() {
        var nNonZeroStats = 0;
        ForEachNonZero((_, _) -> nNonZeroStats++);
        return nNonZeroStats;
    }
    public string GenerateDescription(){
        string makeDesc(int value, string field) {
            if(value == 0)
                return "";
            else if (value > 0)
                return $"{value} {field} \n ";
            else
                return $"{value} {field} \n ";
        }
        var desc = "";
        desc += makeDesc(damage, "Damage");
        desc += makeDesc(health, "Max Health");
        desc += makeDesc(mana, "Max Mana");
        desc += makeDesc(speed, "Speed");
        desc += makeDesc(armor, "Armor");
        desc += makeDesc(manaRegeneration, "Mana Regen");
        desc += makeDesc(spellPower, "Spell Power");
        desc += makeDesc(crit, "Crit %");
        desc += makeDesc(dodge, "Dodge %");
        desc += makeDesc(initiative, "Initiative");
        return desc;
    }
    public string ToShortString() {
        return $"HP={health},MN={mana},DMG={damage},SP={spellPower},ARM={armor},DDG={dodge},CRT={crit},SPD={speed},MR={manaRegeneration},INI={initiative}";
    }

    public void Copy(Stats s) {
        health		= s.Health;
        damage		= s.damage;
        armor			= s.armor;
        crit			= s.crit;
        dodge			= s.dodge;
        initiative		= s.initiative;
        mana			= s.mana;
        spellPower	= s.spellPower;
        manaRegeneration = s.manaRegeneration;
        speed			= s.speed;
    }

    public Stats Clone(){
        var stats = new Stats();
        stats.Copy(this);
        return stats;
    }
    public void Add(Stats s) {
        health		+= s.health;
        damage		+= s.damage;
        armor			+= s.armor;
        crit			+= s.crit;
        dodge			+= s.dodge;
        initiative		+= s.initiative;
        mana			+= s.mana;
        spellPower += s.spellPower;
        manaRegeneration += s.manaRegeneration;
        speed			+= s.speed			;
    }
    public void Subtract(Stats s) {
        health		-= s.health;
        damage		-= s.damage;
        armor			-= s.armor;
        crit			-= s.crit;
        dodge			-= s.dodge;
        initiative		-= s.initiative;
        mana			-= s.mana;
        spellPower -= s.spellPower;
        manaRegeneration -= s.manaRegeneration;
        speed			-= s.speed			;
    }
    public bool IsPercentage(string statName) {
        statName = statName.ToLower();
        if (statName == "armor" || statName == "crit" || statName == "dodge") {
            return true;
        }
        return false;
    }

}