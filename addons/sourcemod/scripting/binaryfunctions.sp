#include <sourcemod>
#include <sdkhooks>
#include <files>

//Globals
char g_CurrentDirectory[PLATFORM_MAX_PATH] = ".";

public Plugin myinfo =
{
  name = "Binary Functions",
  author = "Invex | Byte",
  description = "Useful binary functions.",
  version = "1.00",
  url = "http://www.invexgaming.com.au"
};

public OnPluginStart()
{
  RegAdminCmd("copy", Command_Copy, ADMFLAG_ROOT, "");
  RegAdminCmd("delete", Command_Delete, ADMFLAG_ROOT, "");
  RegAdminCmd("del", Command_Delete, ADMFLAG_ROOT, "");
  RegAdminCmd("list", Command_List, ADMFLAG_ROOT, "");
  RegAdminCmd("ls", Command_List, ADMFLAG_ROOT, "");
  RegAdminCmd("cd", Command_ChangeDirectory, ADMFLAG_ROOT, "");
}

public Action Command_Copy(int client, int args)
{
  char fromFile[PLATFORM_MAX_PATH];
  char toFile[PLATFORM_MAX_PATH];
  
  GetCmdArg(1, fromFile, sizeof(fromFile));
  GetCmdArg(2, toFile, sizeof(toFile));
  
  StripQuotes(fromFile);
  StripQuotes(toFile);
  
  bool result = BFCopyFile(fromFile, toFile);
  if (result)
    ReplyToCommand(client, "Copied file FROM '%s' TO '%s'", fromFile, toFile);
  else
    ReplyToCommand(client, "Failed to copy file FROM '%s' TO '%s'", fromFile, toFile);
    
  return Plugin_Handled;
}

public Action Command_Delete(int client, int args)
{
  char delFile[PLATFORM_MAX_PATH];
  GetCmdArg(1, delFile, sizeof(delFile));
  StripQuotes(delFile);
  
  if (!FileExists(delFile)) {
    ReplyToCommand(client, "File '%s' does not exist.", delFile);
    return Plugin_Handled;
  }
  
  bool result = DeleteFile(delFile);
  if (result)
    ReplyToCommand(client, "Deleted file '%s' successfully.", delFile);
  else
    ReplyToCommand(client, "Failed to delete file '%s'", delFile);
  
  return Plugin_Handled;
}

bool BFCopyFile(const char[] from, const char[] to)
{
  File fromFile = OpenFile(from, "rb");
  File toFile = OpenFile(to, "wb");
  
  if (fromFile == null || toFile == null)
    return false;
    
  //Lets read/write using a 32 byte cell buffer
  int buffer[32];
  int readcache; //this will remember how many bytes we've read
  
  while (!fromFile.EndOfFile()) {
    readcache = fromFile.Read(buffer, 32, 1);
    toFile.Write(buffer, readcache, 1);
  }
  
  fromFile.Close();
  toFile.Close();
  
  return true;
}

public Action Command_List(int client, int args)
{
  char dirPath[PLATFORM_MAX_PATH];
  
  if (args > 0) {
    GetCmdArg(1, dirPath, sizeof(dirPath));
    StripQuotes(dirPath);
  } else {
    Format(dirPath, sizeof(dirPath), g_CurrentDirectory);
  }
  
  if (!DirExists(dirPath)) {
    ReplyToCommand(client, "Directory '%s' does not exist.", dirPath);
    return Plugin_Handled;
  }
  
  DirectoryListing dirlist = OpenDirectory(dirPath);
  if (dirlist == null) {
    ReplyToCommand(client, "Directory Listing for '%s' was null.", dirPath);
    return Plugin_Handled;
  }
  
  ReplyToCommand(client, "> ls '%s'", dirPath);
  
  char buffer[1024];
  while (dirlist.GetNext(buffer, sizeof(buffer))) {
    ReplyToCommand(client, buffer);
  }
  
  delete dirlist;
  
  return Plugin_Handled;
}

public Action Command_ChangeDirectory(int client, int args)
{
  char dirPath[PLATFORM_MAX_PATH];
  GetCmdArg(1, dirPath, sizeof(dirPath));
  StripQuotes(dirPath);
  
  if (strlen(dirPath) == 0) {
    Format(g_CurrentDirectory, sizeof(g_CurrentDirectory), ".");
  }
  else {
    if (StrEqual(dirPath, ".")) {
      //NOP
    }
    else if (StrEqual(dirPath, "..")) {
      //Need to go up 1 level
      int index = FindCharInString(g_CurrentDirectory, '/', true);
      if (index == -1) {
        //Reset to default
        Format(g_CurrentDirectory, sizeof(g_CurrentDirectory), ".");
      }
      else {
        //Remove the bracket and everything after it
        Format(g_CurrentDirectory, index + 1, g_CurrentDirectory);
        
        //If string now empty, reset to default
        if (strlen(g_CurrentDirectory) == 0)
          Format(g_CurrentDirectory, sizeof(g_CurrentDirectory), ".");
      }
    }
    else {
      //Check if this is a local path
      char localDirPath[PLATFORM_MAX_PATH];
      Format(localDirPath, sizeof(localDirPath), "%s/%s", g_CurrentDirectory, dirPath);
      
      if (DirExists(localDirPath)) {
        Format(g_CurrentDirectory, sizeof(g_CurrentDirectory), localDirPath);
      }
      //Check if this is an absolute path
      else if (DirExists(dirPath)) {
        Format(g_CurrentDirectory, sizeof(g_CurrentDirectory), dirPath);
      }
      else {
        ReplyToCommand(client, "Directory '%s' does not exist.", dirPath);
        return Plugin_Handled;
      }
    }
  }
  
  ReplyToCommand(client, "> cd '%s'", g_CurrentDirectory);
  
  return Plugin_Handled;
}
