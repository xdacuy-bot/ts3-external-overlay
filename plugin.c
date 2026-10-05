#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "teamspeak/public_definitions.h"
#include "teamspeak/public_errors.h"
#include "ts3_functions.h"

#define PLUGIN_API_VERSION 26
static struct TS3Functions ts3Functions;
static CRITICAL_SECTION g_lock;
static char g_talkers[128][512];
static anyID g_ids[128];
static int g_count=0;

static void output_path(char *out, size_t n){
  const char *app=getenv("APPDATA");
  if(!app) app=".";
  snprintf(out,n,"%s\\TS3ExternalOverlay",app);
  CreateDirectoryA(out,NULL);
  strncat_s(out,n,"\\talkers.txt",_TRUNCATE);
}
static void write_state(void){
  char path[MAX_PATH*2]; output_path(path,sizeof(path));
  char tmp[MAX_PATH*2]; snprintf(tmp,sizeof(tmp),"%s.tmp",path);
  FILE *f=NULL; fopen_s(&f,tmp,"wb"); if(!f) return;
  EnterCriticalSection(&g_lock);
  for(int i=0;i<g_count;i++) fprintf(f,"%s\n",g_talkers[i]);
  LeaveCriticalSection(&g_lock);
  fclose(f); MoveFileExA(tmp,path,MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH);
}

__declspec(dllexport) const char* ts3plugin_name(void){return "TS3 External Overlay Bridge";}
__declspec(dllexport) const char* ts3plugin_version(void){return "1.0.0";}
__declspec(dllexport) int ts3plugin_apiVersion(void){return PLUGIN_API_VERSION;}
__declspec(dllexport) const char* ts3plugin_author(void){return "TS3 External Overlay";}
__declspec(dllexport) const char* ts3plugin_description(void){return "Sends TeamSpeak talk status to an external OBS-excludable overlay.";}
__declspec(dllexport) void ts3plugin_setFunctionPointers(const struct TS3Functions funcs){ts3Functions=funcs;}
__declspec(dllexport) int ts3plugin_init(void){InitializeCriticalSection(&g_lock); write_state(); return 0;}
__declspec(dllexport) void ts3plugin_shutdown(void){EnterCriticalSection(&g_lock);g_count=0;LeaveCriticalSection(&g_lock);write_state();DeleteCriticalSection(&g_lock);}
__declspec(dllexport) int ts3plugin_requestAutoload(void){return 1;}
__declspec(dllexport) int ts3plugin_offersConfigure(void){return 0;}
__declspec(dllexport) void ts3plugin_registerPluginID(const char* id){(void)id;}
__declspec(dllexport) void ts3plugin_freeMemory(void* data){free(data);}

__declspec(dllexport) void ts3plugin_onTalkStatusChangeEvent(uint64 serverConnectionHandlerID, int status, int isReceivedWhisper, anyID clientID){
  (void)isReceivedWhisper;
  char name[512]={0};
  EnterCriticalSection(&g_lock);
  int found=-1; for(int i=0;i<g_count;i++) if(g_ids[i]==clientID){found=i;break;}
  if(status==STATUS_TALKING){
    if(found<0 && g_count<128 && ts3Functions.getClientDisplayName(serverConnectionHandlerID,clientID,name,sizeof(name))==ERROR_ok){
      g_ids[g_count]=clientID; strcpy_s(g_talkers[g_count],sizeof(g_talkers[g_count]),name); g_count++;
    }
  } else if(found>=0){
    for(int i=found;i<g_count-1;i++){g_ids[i]=g_ids[i+1];strcpy_s(g_talkers[i],sizeof(g_talkers[i]),g_talkers[i+1]);}
    g_count--;
  }
  LeaveCriticalSection(&g_lock);
  write_state();
}
