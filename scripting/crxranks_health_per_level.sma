#include <amxmodx>
#include <amxmisc>
#include <crxranks>
#include <fun>
#include <hamsandwich>

#define PLUGIN_VERSION "1.0"

new g_pMode, g_iMode
new Trie:g_tHealth

public plugin_init()
{
	register_plugin("CRXRanks: Health Per Level", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXRanksHPL", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1)
	g_pMode = register_cvar("crxranks_hpl_mode", "0")
	g_tHealth = TrieCreate()
	ReadFile()
}

public plugin_cfg()
	g_iMode = get_pcvar_num(g_pMode)

public plugin_end()
	TrieDestroy(g_tHealth)
	
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
		
	new szLevel[10]
	num_to_str(crxranks_get_user_level(id), szLevel, charsmax(szLevel))
		
	if(TrieKeyExists(g_tHealth, szLevel))
	{
		new iHealth
		TrieGetCell(g_tHealth, szLevel, iHealth)
		set_user_health(id, !g_iMode ? iHealth : get_user_health(id) + iHealth)
	}
}