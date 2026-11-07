// Loads the modules of one layer from the store into the core from the store.
#include <opendaq/opendaq.h>
#include <iostream>

int main()
{
    const auto instance = daq::Instance(MODULES_DIR);
    const auto modules = instance.getModuleManager().getModules();
    for (const auto& module : modules)
        std::cout << "loaded " << module.getModuleInfo().getId() << "\n";
    return modules.getCount() > 0 ? 0 : 1;
}
