// target Windows 7 and later
// must be defined before windows.h
// @see https://msdn.microsoft.com/en-us/library/windows/desktop/aa383745(v=vs.85).aspx
#define _WIN32_WINNT _WIN32_WINNT_WIN7

#include <stdio.h>
#include <windows.h>
#include <shellapi.h>

#if defined( __GNUC__ )
#include <sys/cygwin.h>
#else
#define __STDC__            1
#endif
#define HAVE_DECL_GETOPT    0
#include "getopt.h"

#pragma comment( lib, "shell32.lib" )
#pragma comment( lib, "kernel32.lib" )
#pragma comment( lib, "user32.lib" )
#pragma comment( lib, "gdi32.lib" )

// use our adapter
extern "C" void cygwin_posix_to_win32_path_list(const char *posix, char * win32);

bool  gDirSpecified     = false;
bool  gParamsSpecified  = false;
bool  gVerbose          = false;

char  gCurrDir[ MAX_PATH ];
char  gParams[ 1024 ];

extern "C" HWND hWndMain;
HWND hWndMain;

extern "C" WINBASEAPI HWND WINAPI GetConsoleWindow( void );

void Usage();

/**************************************************************************
*
* main
*/

int main( int argc, char **argv )
{
   char dosPath[ MAX_PATH ];

   hWndMain = GetConsoleWindow();

   int opt;
   while (( opt = getopt( argc, argv, "d:hp:v" )) != -1 )
   {
      switch ( opt )
      {
         case 'd':
         {
            gDirSpecified = true;
#if defined( __GNUC__ )
            if ( cygwin_posix_path_list_p( optarg ))
            {
               cygwin_posix_to_win32_path_list( optarg, gCurrDir );
            }
            else
#endif
            {
               strcpy( gCurrDir, optarg );
            }
            break;
         }

         case 'h':
         {
            Usage();
            exit( 0 );
         }

         case 'p':
         {
            gParamsSpecified = true;
            strcpy( gParams, optarg );
            break;
         }

         case 'v':
         {
            gVerbose = true;
            break;
         }

         case '?':
         default:
         {
            fprintf( stderr, "Unrecognized option: '%c'\n", opt );
            Usage();
            exit( 1 );
         }
      }
   }

   if ( optind >= argc )
   {
      Usage();
      exit( 1 );
   }

   for ( int i = optind; i < argc; i++ )
   {
      const char *fileName = argv[ i ];

#if defined( __GNUC__ )
      if ( cygwin_posix_path_list_p( fileName ))
      {
         cygwin_posix_to_win32_path_list( fileName, dosPath );
         fileName = dosPath;
      }
#endif

      SHELLEXECUTEINFO  ei;

      memset( &ei, 0, sizeof( ei ));

      ei.cbSize = sizeof( ei );
      ei.lpFile = fileName;
      ei.fMask |= SEE_MASK_FLAG_DDEWAIT;

      DWORD attr = GetFileAttributes( fileName );
      if (( attr & FILE_ATTRIBUTE_DIRECTORY ) != 0 )
      {
         ei.lpVerb = "explore";
      }
      else
      {
         ei.lpVerb = "open";
      }

      ei.nShow = 5;

      if ( gDirSpecified )
      {
         ei.lpDirectory = gCurrDir;
      }
      if ( gParamsSpecified )
      {
         ei.lpParameters = gParams;
      }

      if ( gVerbose )
      {
         printf( "About to %s '%s'", ei.lpVerb, ei.lpFile );
         if ( ei.lpParameters != NULL )
         {
            printf( " with params '%s'", ei.lpParameters );
         }
         if ( ei.lpDirectory != NULL )
         {
            printf( " with CWD set to '%s'", ei.lpDirectory );
            }
         printf( ".\n" );
      }

      if ( !ShellExecuteEx( &ei ))
      {
         fprintf( stderr, "Error trying to open '%s'\n", fileName );
      }
   }

   return 0;
}

/**************************************************************************
*
* Usage
*/

void Usage()
{
   fprintf( stderr, "Usage: open [-vh] [-d dir] [-p params] file ...\n" );
   fprintf( stderr, "\n" );
   fprintf( stderr, "Options:\n" );
   fprintf( stderr, "  -h        Print this screen\n" );
   fprintf( stderr, "  -v        Verbose mode\n" );
   fprintf( stderr, "  -d dir    Sets the current directory to 'dir'\n" );
   fprintf( stderr, "  -p params Passes 'params' (only for executables)\n" );
}

