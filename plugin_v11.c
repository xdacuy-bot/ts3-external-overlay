#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "teamspeak/public_definitions.h"
#include "teamspeak/public_errors.h"
#include "ts3_functions.h"
#define PLUGIN_API_VERSION 26
static struct TS3Functions F; static CRITICAL_SECTION L; static anyID talking[128]; static int nt=0;
static int talks(anyID id){for(int i=0;i<nt;i++)if(talking[i]==id)return 1;return 0;}
static void settalk(anyID id,int on){int p=-1;for(int i=0;i<nt;i++)if(talking[i]==id){p=i;break;}if(on&&p<0&&nt<128)talking[nt++]=id;else if(!on&&p>=0){for(int i=p;i<nt-1;i++)talking[i]=talking[i+1];nt--;}}
static void clean(char*s){for(;*s;s++)if(*s==9||*s==10||*s==13)*s=' ';}
static void path(char*out,size_t n){const char*a=getenv("APPDATA");if(!a)a=".";snprintf(out,n,"%s\\TS3ExternalOverlay",a);CreateDirectoryA(out,0);strncat_s(out,n,"\\state.tsv",_TRUNCATE);}
static void write_state(uint64 sch){
 char p[MAX_PATH*2],tmp[MAX_PATH*2];path(p,sizeof(p));snprintf(tmp,sizeof(tmp),"%s.tmp",p);FILE*f=0;fopen_s(&f,tmp,"wb");if(!f)return;
 anyID me=0;uint64 ch=0;if(F.getClientID(sch,&me)!=ERROR_ok||F.getChannelOfClient(sch,me,&ch)!=ERROR_ok){fclose(f);return;}
 char*cn=0;if(F.getChannelVariableAsString(sch,ch,CHANNEL_NAME,&cn)==ERROR_ok&&cn){clean(cn);fprintf(f,"CHANNEL\t%s\n",cn);F.freeMemory(cn);}
 anyID*ids=0;if(F.getChannelClientList(sch,ch,&ids)==ERROR_ok&&ids){for(int i=0;ids[i];i++){anyID id=ids[i];char name[512]={0};if(F.getClientDisplayName(sch,id,name,sizeof(name))!=ERROR_ok)continue;clean(name);int im=0,om=0,ide=0;F.getClientVariableAsInt(sch,id,CLIENT_INPUT_MUTED,&im);F.getClientVariableAsInt(sch,id,CLIENT_OUTPUT_MUTED,&om);F.getClientVariableAsInt(sch,id,CLIENT_INPUT_DEACTIVATED,&ide);fprintf(f,"USER\t%d\t%d\t%s\n",talks(id),(im||om||ide)?1:0,name);}F.freeMemory(ids);}
 fclose(f);MoveFileExA(tmp,p,MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH);
}
static void refresh(uint64 s){EnterCriticalSection(&L);write_state(s);LeaveCriticalSection(&L);}
__declspec(dllexport) const char* ts3plugin_name(void){return "TS3 External Overlay Bridge";} __declspec(dllexport) const char* ts3plugin_version(void){return "1.1.0";} __declspec(dllexport) int ts3plugin_apiVersion(void){return PLUGIN_API_VERSION;} __declspec(dllexport) const char* ts3plugin_author(void){return "TS3 External Overlay";} __declspec(dllexport) const char* ts3plugin_description(void){return "Persistent external channel overlay bridge.";} __declspec(dllexport) void ts3plugin_setFunctionPointers(const struct TS3Functions f){F=f;} __declspec(dllexport) int ts3plugin_init(void){InitializeCriticalSection(&L);return 0;} __declspec(dllexport) void ts3plugin_shutdown(void){DeleteCriticalSection(&L);} __declspec(dllexport) int ts3plugin_requestAutoload(void){return 1;} __declspec(dllexport) int ts3plugin_offersConfigure(void){return 0;} __declspec(dllexport) void ts3plugin_registerPluginID(const char*x){(void)x;} __declspec(dllexport) void ts3plugin_freeMemory(void*x){free(x);}
__declspec(dllexport) void ts3plugin_onTalkStatusChangeEvent(uint64 s,int st,int w,anyID id){(void)w;EnterCriticalSection(&L);settalk(id,st==STATUS_TALKING);write_state(s);LeaveCriticalSection(&L);} __declspec(dllexport) void ts3plugin_onClientMoveEvent(uint64 s,anyID a,uint64 b,uint64 c,int d,const char*e){(void)a;(void)b;(void)c;(void)d;(void)e;refresh(s);} __declspec(dllexport) void ts3plugin_onClientMoveSubscriptionEvent(uint64 s,anyID a,uint64 b,uint64 c,int d){(void)a;(void)b;(void)c;(void)d;refresh(s);} __declspec(dllexport) void ts3plugin_onUpdateClientEvent(uint64 s,anyID a,anyID b,const char*c,const char*d){(void)a;(void)b;(void)c;(void)d;refresh(s);} __declspec(dllexport) void ts3plugin_onConnectStatusChangeEvent(uint64 s,int st,unsigned int e){(void)e;if(st==STATUS_CONNECTION_ESTABLISHED)refresh(s);}
