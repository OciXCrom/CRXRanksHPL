#include <amxmodx>
#include <amxmisc>
#include <crxranks>
#include <fun>
#include <hamsandwich>

#define PLUGIN_VERSION "1.1"

new g_pMode, g_pConstant, g_iMode, g_iConstant
new Trie:g_tHealth

public plugin_init()
{
	register_plugin("CRXRanks: Health Per Level", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXRanksHPL", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1)
	g_pMode = register_cvar("crxranks_hpl_mode", "0")
	g_pConstant = register_cvar("crxranks_hpl_constant", "0")
}

public plugin_cfg()
{
	g_iMode = get_pcvar_num(g_pMode)
	g_iConstant = get_pcvar_num(g_pConstant)

	if(!using_constant_mode())
	{
		g_tHealth = TrieCreate()
		ReadFile()
	}
}

public plugin_end()
{
	if(!using_constant_mode())
		TrieDestroy(g_tHealth)
}
	
ReadFile()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/RankSystemHealth.ini", szConfigsName)
	
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[64], szValue[32], szMap[32], szKey[32], bool:bRead = true, iSize
		get_mapname(szMap, charsmax(szMap))
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, '#', ';': continue
				case '-':
				{
					iSize = strlen(szData)
					
					if(szData[iSize - 1] == '-')
					{
						szData[0] = ' '
						szData[iSize - 1] = ' '
						trim(szData)
						
						if(contain(szData, "*") != -1)
						{
							strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '*')
							copy(szValue, strlen(szKey), szMap)
							bRead = equal(szValue, szKey) ? true : false
						}
						else
						{
							static const szAll[] = "#all"
							bRead = equal(szData, szAll) || equali(szData, szMap)
						}
					}
					else continue
				}
				default:
				{
					if(!bRead)
						continue
						
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)
							
					if(!szValue[0])
						continue
						
					TrieSetCell(g_tHealth, szKey, str_to_num(szValue))
				}
			}
		}
		
		fclose(iFilePointer)
	}
}

public OnPlayerSpawn(id)
{
	if(!is_user_alive(id))
		return

	if(using_constant_mode())
	{
		new iLevel = crxranks_get_user_level(id)
		add_health_amount(id, iLevel == 0 ? g_iConstant : iLevel * g_iConstant)
		return
	}
		
	new szLevel[10]
	num_to_str(crxranks_get_user_level(id), szLevel, charsmax(szLevel))
		
	if(TrieKeyExists(g_tHealth, szLevel))
	{
		new iHealth
		TrieGetCell(g_tHealth, szLevel, iHealth)
		add_health_amount(id, iHealth)
	}
}

add_health_amount(const id, const iAmount)
	set_user_health(id, !g_iMode ? iAmount : get_user_health(id) + iAmount)

bool:using_constant_mode()
	return g_iConstant != 0