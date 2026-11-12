/* Loads every module of the installed bundle through the C binding, as modules.cpp does through the C++ API;
   fails when a call fails, when none loads, or not as many as expected. */
#include <copendaq.h>
#include <stdio.h>

#define CHECK(call)                                              \
    if (DAQ_FAILED(call))                                        \
    {                                                            \
        fprintf(stderr, "failed: %s\n", #call);                  \
        return 1;                                                \
    }

int main(void)
{
    daqString* path = NULL;
    CHECK(daqString_createString(&path, MODULES_DIR));

    daqInstanceBuilder* builder = NULL;
    CHECK(daqInstanceBuilder_createInstanceBuilder(&builder));
    CHECK(daqInstanceBuilder_setModulePath(builder, path));

    daqInstance* instance = NULL;
    CHECK(daqInstance_createInstanceFromBuilder(&instance, builder));

    daqModuleManager* manager = NULL;
    CHECK(daqInstance_getModuleManager(instance, &manager));
    daqList* modules = NULL;
    CHECK(daqModuleManager_getModules(manager, &modules));

    daqSizeT count = 0;
    CHECK(daqList_getCount(modules, &count));
    for (daqSizeT i = 0; i < count; ++i)
    {
        daqModule* module = NULL;
        CHECK(daqList_getItemAt(modules, i, (daqBaseObject**) &module));
        daqModuleInfo* info = NULL;
        CHECK(daqModule_getModuleInfo(module, &info));
        daqString* id = NULL;
        CHECK(daqModuleInfo_getId(info, &id));
        daqConstCharPtr text = NULL;
        CHECK(daqString_getCharPtr(id, &text));
        printf("loaded %s\n", text);

        daqReleaseRef((daqBaseObject*) id);
        daqReleaseRef((daqBaseObject*) info);
        daqReleaseRef((daqBaseObject*) module);
    }
    printf("%d modules\n", (int) count);

    daqReleaseRef((daqBaseObject*) modules);
    daqReleaseRef((daqBaseObject*) manager);
    daqReleaseRef((daqBaseObject*) instance);
    daqReleaseRef((daqBaseObject*) builder);
    daqReleaseRef((daqBaseObject*) path);

    if (EXPECT_MODULES > 0)
        return (int) count == EXPECT_MODULES ? 0 : 1;
    return count > 0 ? 0 : 1;
}
