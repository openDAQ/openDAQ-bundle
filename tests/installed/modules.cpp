// Loads every module of the installed bundle; fails when none loads, or not as many as expected.
#include <opendaq/opendaq.h>
#include <iostream>

int main()
{
    const auto instance = daq::Instance(MODULES_DIR);
    const auto modules = instance.getModuleManager().getModules();
    for (const auto& module : modules)
        std::cout << "loaded " << module.getModuleInfo().getId() << "\n";

    const auto count = static_cast<int>(modules.getCount());
    std::cout << count << " modules\n";
    if (EXPECT_MODULES > 0)
        return count == EXPECT_MODULES ? 0 : 1;
    return count > 0 ? 0 : 1;
}
