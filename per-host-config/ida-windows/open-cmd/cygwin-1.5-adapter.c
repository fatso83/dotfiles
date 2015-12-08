/**
 * Adapter for old Cygwin 1.x functions missing from Cygwin 2.x
 * @author Carl-Erik Kopseng
 *
 * Based on the documentation for 1.4 and 2.x
 * - http://pipeline.lbl.gov/code/3rd_party/licenses.win/cygwin-doc-1.4/html/cygwin-api/func-cygwin-posix-to-win32-path-list.html
 * - https://cygwin.com/cygwin-api/func-cygwin-conv-path.html
 *
 */
#include <sys/cygwin.h>
#include <windows.h>
#include <shellapi.h>

void cygwin_posix_to_win32_path_list(const char *posix, char * win32){

    // We do not know the size of the win32 buffer, but hopefully 
    // it is at least size long, and _most probably MAX_PATH long_ ;)
    ssize_t size = cygwin_conv_path( CCP_POSIX_TO_WIN_A, posix, NULL, 0);

    cygwin_conv_path( CCP_POSIX_TO_WIN_A, posix, win32, size);
}

