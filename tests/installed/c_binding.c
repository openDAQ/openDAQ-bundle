/* Calls the C binding: makes a string and releases it, as the core's own compile test does. */
#include <copendaq.h>
#include <stdio.h>

int main(void)
{
    daqString* str = NULL;
    daqErrCode err = daqString_createString(&str, "Hello, C bindings!");
    int refs = daqReleaseRef(str);
    printf("C binding: error %d, references left %d\n", (int) err, refs);
    return err | refs;
}
