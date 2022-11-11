/** 
 * Print the number of millis since the Epoch (Jan 1 1970)
 * Compile: cc millis.cc -o millis
 * Put in your path: mv millis /usr/local/bin
 * 
 * Gist: https://gist.github.com/fatso83/86e94e91926d1311f3fa
 */
#include <stdio.h>
#include <sys/time.h>
int main(void)
{ 
    struct timeval time_now;
    gettimeofday(&time_now,NULL);
    printf ("%ld%03d\n",time_now.tv_sec, (int) time_now.tv_usec/1000);

    return 0;
}
