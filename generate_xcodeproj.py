#!/usr/bin/env python3
"""
Generate an Xcode project.pbxproj for the PokedexTutorial app.
Created: 2026-07-02
Last modified: 2026-07-02
Description: Generates a complete Xcode project file from the source directory
             structure so the app can be built with xcodebuild and run in the simulator.
Author: enigmak9
"""

import uuid
import hashlib
import os
import sys

def make_uuid(seed):
    """Generate a deterministic UUID from a seed string."""
    h = hashlib.md5(seed.encode()).hexdigest()
    return h[:24].upper()

# ── Source files ──────────────────────────────────────────────

source_files = [
    # App
    ("App/PokedexTutorialApp.swift", "PokedexTutorialApp.swift"),
    # Models
    ("Models/Pokemon.swift", "Pokemon.swift"),
    ("Models/PokemonType.swift", "PokemonType.swift"),
    ("Models/PokemonDetail.swift", "PokemonDetail.swift"),
    ("Models/LoadingState.swift", "LoadingState.swift"),
    # Extensions
    ("Extensions/Color+PokemonType.swift", "Color+PokemonType.swift"),
    ("Extensions/View+Extensions.swift", "View+Extensions.swift"),
    # Services
    ("Services/PokemonServiceProtocol.swift", "PokemonServiceProtocol.swift"),
    ("Services/MockPokemonService.swift", "MockPokemonService.swift"),
    ("Services/PokemonAPIService.swift", "PokemonAPIService.swift"),
    # Stores
    ("Stores/FavoritesStore.swift", "FavoritesStore.swift"),
    # ViewModels
    ("ViewModels/PokemonListViewModel.swift", "PokemonListViewModel.swift"),
    ("ViewModels/PokemonDetailViewModel.swift", "PokemonDetailViewModel.swift"),
    # Views
    ("Views/TypeBadgeView.swift", "TypeBadgeView.swift"),
    ("Views/PokemonRowView.swift", "PokemonRowView.swift"),
    ("Views/PokemonListView.swift", "PokemonListView.swift"),
    ("Views/PokemonDetailView.swift", "PokemonDetailView.swift"),
    ("Views/StatBarView.swift", "StatBarView.swift"),
    ("Views/FilterChipView.swift", "FilterChipView.swift"),
]

resource_files = [
    ("Resources/mock_pokemon_list.json", "mock_pokemon_list.json"),
]

test_files = [
    ("PokedexTutorialTests/PokemonModelTests.swift", "PokemonModelTests.swift"),
    ("PokedexTutorialTests/PokemonListViewModelTests.swift", "PokemonListViewModelTests.swift"),
    ("PokedexTutorialTests/PokemonAPIServiceTests.swift", "PokemonAPIServiceTests.swift"),
]

uitest_files = [
    ("PokedexTutorialUITests/PokedexTutorialUITests.swift", "PokedexTutorialUITests.swift"),
]

# ── Generate UUIDs ────────────────────────────────────────────

def gen():
    """Generate all UUIDs deterministically."""
    u = {}
    u["project"] = make_uuid("project")
    u["main_group"] = make_uuid("main_group")
    u["src_group"] = make_uuid("src_group")
    u["app_group"] = make_uuid("app_group")
    u["models_group"] = make_uuid("models_group")
    u["extensions_group"] = make_uuid("extensions_group")
    u["services_group"] = make_uuid("services_group")
    u["stores_group"] = make_uuid("stores_group")
    u["viewmodels_group"] = make_uuid("viewmodels_group")
    u["views_group"] = make_uuid("views_group")
    u["resources_group"] = make_uuid("resources_group")
    u["tests_group"] = make_uuid("tests_group")
    u["uitests_group"] = make_uuid("uitests_group")
    u["products_group"] = make_uuid("products_group")

    u["app_target"] = make_uuid("app_target")
    u["test_target"] = make_uuid("test_target")
    u["uitest_target"] = make_uuid("uitest_target")

    u["app_product"] = make_uuid("app_product")
    u["test_product"] = make_uuid("test_product")
    u["uitest_product"] = make_uuid("uitest_product")

    u["app_sources_phase"] = make_uuid("app_sources_phase")
    u["app_resources_phase"] = make_uuid("app_resources_phase")
    u["app_frameworks_phase"] = make_uuid("app_frameworks_phase")
    u["test_sources_phase"] = make_uuid("test_sources_phase")
    u["test_frameworks_phase"] = make_uuid("test_frameworks_phase")
    u["uitest_sources_phase"] = make_uuid("uitest_sources_phase")
    u["uitest_frameworks_phase"] = make_uuid("uitest_frameworks_phase")

    for path, name in source_files:
        u[f"file_{name}"] = make_uuid(f"file_{name}")
        u[f"build_{name}"] = make_uuid(f"build_{name}")

    for path, name in resource_files:
        u[f"file_{name}"] = make_uuid(f"file_{name}")
        u[f"build_{name}"] = make_uuid(f"build_{name}")

    for path, name in test_files:
        u[f"file_{name}"] = make_uuid(f"file_{name}")
        u[f"build_{name}"] = make_uuid(f"build_{name}")

    for path, name in uitest_files:
        u[f"file_{name}"] = make_uuid(f"file_{name}")
        u[f"build_{name}"] = make_uuid(f"build_{name}")

    # Build configs
    for config in ["debug", "release"]:
        u[f"proj_{config}"] = make_uuid(f"proj_{config}")
        u[f"app_{config}"] = make_uuid(f"app_{config}")
        u[f"test_{config}"] = make_uuid(f"test_{config}")
        u[f"uitest_{config}"] = make_uuid(f"uitest_{config}")

    u["proj_config_list"] = make_uuid("proj_config_list")
    u["app_config_list"] = make_uuid("app_config_list")
    u["test_config_list"] = make_uuid("test_config_list")
    u["uitest_config_list"] = make_uuid("uitest_config_list")

    # Native target deps
    u["test_target_dep"] = make_uuid("test_target_dep")
    u["uitest_target_dep"] = make_uuid("uitest_target_dep")

    return u

u = gen()

# ── Render the pbxproj ────────────────────────────────────────

def quote(s):
    return f'"{s}"'

def render_file_ref(uuid, name, path, source_tree="<group>"):
    return f'\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {"sourcecode.swift" if path.endswith(".swift") else "text.json"}; path = {quote(path)}; sourceTree = {quote(source_tree)}; }};'

def render_build_file(uuid, file_ref_uuid):
    return f'\t\t{uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid}; }};'

def render_product_ref(uuid, name, product_type, path):
    explicit_type = ""
    if product_type == "com.apple.product-type.application":
        explicit_type = f"explicitFileType = wrapper.application; "
    elif product_type == "com.apple.product-type.bundle.unit-test":
        explicit_type = f"explicitFileType = wrapper.cfbundle; "
    elif product_type == "com.apple.product-type.bundle.ui-testing":
        explicit_type = f"explicitFileType = wrapper.cfbundle; "
    return f'\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; {explicit_type}includeInIndex = 0; path = {quote(path)}; sourceTree = BUILT_PRODUCTS_DIR; }};'

def render_group(uuid, name, children, source_tree="<group>"):
    children_str = ", ".join(children)
    return f'\t\t{uuid} /* {name} */ = {{isa = PBXGroup; children = ({children_str}); name = {quote(name)}; sourceTree = {quote(source_tree)}; }};'

def render_build_phase(uuid, name, build_files_uuids):
    files_str = ", ".join(build_files_uuids)
    return f'\t\t{uuid} /* {name} */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({files_str}); runOnlyForDeploymentPostprocessing = 0; }};'

def render_resources_phase(uuid, name, build_files_uuids):
    files_str = ", ".join(build_files_uuids)
    return f'\t\t{uuid} /* {name} */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({files_str}); runOnlyForDeploymentPostprocessing = 0; }};'

def render_frameworks_phase(uuid, name):
    return f'\t\t{uuid} /* {name} */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};'

def render_native_target(uuid, name, product_ref, product_type, build_phases, dependencies, build_config_list):
    phases_str = ",\n".join(build_phases)
    deps_str = ",\n".join(dependencies) if dependencies else ""
    deps_line = f"dependencies = ({deps_str});" if deps_str else "dependencies = ();"
    return f'''\t\t{uuid} /* {name} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {build_config_list} /* Build configuration list for PBXNativeTarget "{name}" */;
\t\t\tbuildPhases = (
\t\t\t\t{phases_str}
\t\t\t);
\t\t\t{deps_line}
\t\t\tname = {quote(name)};
\t\t\tproductName = {quote(name)};
\t\t\tproductReference = {product_ref};
\t\t\tproductType = {quote(product_type)};
\t\t}};'''

def render_target_dependency(uuid, target_uuid):
    return f'\t\t{uuid} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {target_uuid}; }};'

def render_build_config(uuid, name, settings):
    lines = [f'\t\t{uuid} /* {name} */ = {{']
    lines.append(f'\t\t\tisa = XCBuildConfiguration;')
    lines.append(f'\t\t\tbuildSettings = {{')
    for k, v in settings.items():
        if isinstance(v, bool):
            v_str = "YES" if v else "NO"
        elif isinstance(v, list):
            v_str = f'({", ".join(quote(x) for x in v)})'
        else:
            v_str = quote(str(v))
        lines.append(f'\t\t\t\t{k} = {v_str};')
    lines.append(f'\t\t\t}};')
    lines.append(f'\t\t\tname = {quote(name)};')
    lines.append(f'\t\t}};')
    return "\n".join(lines)

def render_config_list(uuid, name, config_uuids, default_name):
    configs_str = ",\n".join(config_uuids)
    return f'\t\t{uuid} /* Build configuration list for PBXProject "{name}" */ = {{isa = XCConfigurationList; buildConfigurations = (\n{configs_str}\n\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = {quote(default_name)}; }};'

# ── Build the project ─────────────────────────────────────────

lines = []

# Header
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append(f'\tarchiveVersion = 1;')
lines.append(f'\tclasses = {{}};')
lines.append(f'\tobjectVersion = 56;')
lines.append(f'\tobjects = {{')
lines.append("")
lines.append("/* Begin PBXBuildFile section */")

# Build files for source
for path, name in source_files:
    build_uuid = u[f"build_{name}"]
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{build_uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};')

# Build files for resources
for path, name in resource_files:
    build_uuid = u[f"build_{name}"]
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{build_uuid} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};')

# Build files for tests
for path, name in test_files:
    build_uuid = u[f"build_{name}"]
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{build_uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};')

# Build files for UITests
for path, name in uitest_files:
    build_uuid = u[f"build_{name}"]
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{build_uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid}; }};')

lines.append("/* End PBXBuildFile section */")
lines.append("")
lines.append("/* Begin PBXContainerItemProxy section */")

# Container item proxy for test target
test_proxy_uuid = make_uuid("test_proxy")
lines.append(f'\t\t{test_proxy_uuid} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {u["project"]} /* Project object */; proxyType = 1; remoteGlobalIDString = {u["app_target"]}; remoteInfo = PokedexTutorial; }};')

# Container item proxy for UITest target
uitest_proxy_uuid = make_uuid("uitest_proxy")
lines.append(f'\t\t{uitest_proxy_uuid} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {u["project"]} /* Project object */; proxyType = 1; remoteGlobalIDString = {u["app_target"]}; remoteInfo = PokedexTutorial; }};')

lines.append("/* End PBXContainerItemProxy section */")
lines.append("")
lines.append("/* Begin PBXFileReference section */")

# File references for source
for path, name in source_files:
    file_uuid = u[f"file_{name}"]
    file_type = "sourcecode.swift"
    lines.append(f'\t\t{file_uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = {quote(name)}; sourceTree = "<group>"; }};')

# File references for resources
for path, name in resource_files:
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{file_uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = {quote(name)}; sourceTree = "<group>"; }};')

# File references for tests
for path, name in test_files:
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{file_uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(name)}; sourceTree = "<group>"; }};')

# File references for UITests
for path, name in uitest_files:
    file_uuid = u[f"file_{name}"]
    lines.append(f'\t\t{file_uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(name)}; sourceTree = "<group>"; }};')

# Products
lines.append(f'\t\t{u["app_product"]} /* PokedexTutorial.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = PokedexTutorial.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
lines.append(f'\t\t{u["test_product"]} /* PokedexTutorialTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = PokedexTutorialTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
lines.append(f'\t\t{u["uitest_product"]} /* PokedexTutorialUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = PokedexTutorialUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')

lines.append("/* End PBXFileReference section */")
lines.append("")
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.append(render_frameworks_phase(u["app_frameworks_phase"], "Frameworks"))
lines.append(render_frameworks_phase(u["test_frameworks_phase"], "Frameworks"))
lines.append(render_frameworks_phase(u["uitest_frameworks_phase"], "Frameworks"))
lines.append("/* End PBXFrameworksBuildPhase section */")
lines.append("")
lines.append("/* Begin PBXGroup section */")

# Main group
lines.append(f'\t\t{u["main_group"]} /* CustomTemplate */ = {{')
lines.append(f'\t\t\tisa = PBXGroup;')
lines.append(f'\t\t\tchildren = (')
lines.append(f'\t\t\t\t{u["src_group"]} /* PokedexTutorial */,')
lines.append(f'\t\t\t\t{u["tests_group"]} /* PokedexTutorialTests */,')
lines.append(f'\t\t\t\t{u["uitests_group"]} /* PokedexTutorialUITests */,')
lines.append(f'\t\t\t\t{u["products_group"]} /* Products */,')
lines.append(f'\t\t\t);')
lines.append(f'\t\t\tsourceTree = "<group>";')
lines.append(f'\t\t}};')

# Source group with subdirectories
src_children = [
    u["app_group"], u["models_group"], u["extensions_group"],
    u["services_group"], u["stores_group"], u["viewmodels_group"],
    u["views_group"], u["resources_group"]
]
src_children_str = ",\n\t\t\t\t".join(src_children)
lines.append(f'\t\t{u["src_group"]} /* PokedexTutorial */ = {{')
lines.append(f'\t\t\tisa = PBXGroup;')
lines.append(f'\t\t\tchildren = (')
lines.append(f'\t\t\t\t{src_children_str}')
lines.append(f'\t\t\t);')
lines.append(f'\t\t\tpath = PokedexTutorial;')
lines.append(f'\t\t\tsourceTree = "<group>";')
lines.append(f'\t\t}};')

# Subgroups
for group_uuid, name, file_list in [
    (u["app_group"], "App", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("App/")]),
    (u["models_group"], "Models", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("Models/")]),
    (u["extensions_group"], "Extensions", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("Extensions/")]),
    (u["services_group"], "Services", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("Services/")]),
    (u["stores_group"], "Stores", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("Stores/")]),
    (u["viewmodels_group"], "ViewModels", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("ViewModels/")]),
    (u["views_group"], "Views", [(n, u[f"file_{n}"]) for p, n in source_files if p.startswith("Views/")]),
    (u["resources_group"], "Resources", [(n, u[f"file_{n}"]) for p, n in resource_files]),
]:
    children = ", ".join(uuid for _, uuid in file_list)
    lines.append(f'\t\t{group_uuid} /* {name} */ = {{isa = PBXGroup; children = ({children}); name = {quote(name)}; sourceTree = "<group>"; }};')

# Test group
test_children = ", ".join(u[f"file_{n}"] for p, n in test_files)
lines.append(f'\t\t{u["tests_group"]} /* PokedexTutorialTests */ = {{isa = PBXGroup; children = ({test_children}); path = PokedexTutorialTests; sourceTree = "<group>"; }};')

# UITest group
uitest_children = ", ".join(u[f"file_{n}"] for p, n in uitest_files)
lines.append(f'\t\t{u["uitests_group"]} /* PokedexTutorialUITests */ = {{isa = PBXGroup; children = ({uitest_children}); path = PokedexTutorialUITests; sourceTree = "<group>"; }};')

# Products group
lines.append(f'\t\t{u["products_group"]} /* Products */ = {{isa = PBXGroup; children = ({u["app_product"]} /* PokedexTutorial.app */, {u["test_product"]} /* PokedexTutorialTests.xctest */, {u["uitest_product"]} /* PokedexTutorialUITests.xctest */); name = Products; sourceTree = "<group>"; }};')

lines.append("/* End PBXGroup section */")
lines.append("")
lines.append("/* Begin PBXNativeTarget section */")

# App target
app_sources = ", ".join(u[f"build_{n}"] for p, n in source_files)
app_resources_build = ", ".join(u[f"build_{n}"] for p, n in resource_files)

lines.append(f'''\t\t{u["app_target"]} /* PokedexTutorial */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u["app_config_list"]} /* Build configuration list for PBXNativeTarget "PokedexTutorial" */;
\t\t\tbuildPhases = (
\t\t\t\t{u["app_sources_phase"]} /* Sources */,
\t\t\t\t{u["app_resources_phase"]} /* Resources */,
\t\t\t\t{u["app_frameworks_phase"]} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = PokedexTutorial;
\t\t\tproductName = PokedexTutorial;
\t\t\tproductReference = {u["app_product"]} /* PokedexTutorial.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};''')

# Test target
test_sources = ", ".join(u[f"build_{n}"] for p, n in test_files)
lines.append(f'''\t\t{u["test_target"]} /* PokedexTutorialTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u["test_config_list"]} /* Build configuration list for PBXNativeTarget "PokedexTutorialTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{u["test_sources_phase"]} /* Sources */,
\t\t\t\t{u["test_frameworks_phase"]} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{u["test_target_dep"]} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = PokedexTutorialTests;
\t\t\tproductName = PokedexTutorialTests;
\t\t\tproductReference = {u["test_product"]} /* PokedexTutorialTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};''')

# UITest target
uitest_sources = ", ".join(u[f"build_{n}"] for p, n in uitest_files)
lines.append(f'''\t\t{u["uitest_target"]} /* PokedexTutorialUITests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u["uitest_config_list"]} /* Build configuration list for PBXNativeTarget "PokedexTutorialUITests" */;
\t\t\tbuildPhases = (
\t\t\t\t{u["uitest_sources_phase"]} /* Sources */,
\t\t\t\t{u["uitest_frameworks_phase"]} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = (
\t\t\t\t{u["uitest_target_dep"]} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = PokedexTutorialUITests;
\t\t\tproductName = PokedexTutorialUITests;
\t\t\tproductReference = {u["uitest_product"]} /* PokedexTutorialUITests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};''')

lines.append("/* End PBXNativeTarget section */")
lines.append("")
lines.append("/* Begin PBXProject section */")

proj_debug = u["proj_debug"]
proj_release = u["proj_release"]
targets = f'{u["app_target"]} /* PokedexTutorial */,\n\t\t\t\t{u["test_target"]} /* PokedexTutorialTests */,\n\t\t\t\t{u["uitest_target"]} /* PokedexTutorialUITests */'

lines.append(f'''\t\t{u["project"]} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1520;
\t\t\t\tLastUpgradeCheck = 1520;
\t\t\t}};
\t\t\tbuildConfigurationList = {u["proj_config_list"]} /* Build configuration list for PBXProject "PokedexTutorial" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, Base);
\t\t\tmainGroup = {u["main_group"]};
\t\t\tproductRefGroup = {u["products_group"]};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{targets}
\t\t\t);
\t\t}};''')

lines.append("/* End PBXProject section */")
lines.append("")
lines.append("/* Begin PBXResourcesBuildPhase section */")

lines.append(f'''\t\t{u["app_resources_phase"]} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ({app_resources_build});
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};''')

lines.append("/* End PBXResourcesBuildPhase section */")
lines.append("")
lines.append("/* Begin PBXSourcesBuildPhase section */")

# App sources phase
lines.append(f'''\t\t{u["app_sources_phase"]} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ({app_sources});
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};''')

# Test sources phase
lines.append(f'''\t\t{u["test_sources_phase"]} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ({test_sources});
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};''')

# UITest sources phase
lines.append(f'''\t\t{u["uitest_sources_phase"]} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ({uitest_sources});
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};''')

lines.append("/* End PBXSourcesBuildPhase section */")
lines.append("")
lines.append("/* Begin PBXTargetDependency section */")
lines.append(f'\t\t{u["test_target_dep"]} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {u["app_target"]} /* PokedexTutorial */; }};')
lines.append(f'\t\t{u["uitest_target_dep"]} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {u["app_target"]} /* PokedexTutorial */; }};')
lines.append("/* End PBXTargetDependency section */")
lines.append("")
lines.append("/* Begin XCBuildConfiguration section */")

# Project level build configs
app_config_debug = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "ENABLE_PREVIEWS": True,
    "GENERATE_INFOPLIST_FILE": True,
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": True,
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": True,
    "INFOPLIST_KEY_UILaunchScreen_Generation": True,
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.enigmak9.PokedexTutorial",
    "PRODUCT_NAME": "PokedexTutorial",
    "SWIFT_EMIT_LOC_STRINGS": True,
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
}

app_config_release = dict(app_config_debug)

proj_config_debug = {
    "ALWAYS_SEARCH_USER_PATHS": False,
    "CLANG_ANALYZER_NONNULL": True,
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": True,
    "CLANG_ENABLE_OBJC_ARC": True,
    "COPY_PHASE_STRIP": False,
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": True,
    "ENABLE_TESTABILITY": True,
    "GCC_DYNAMIC_NO_PIC": False,
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": True,
    "SDKROOT": "iphoneos",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
}

proj_config_release = {
    "ALWAYS_SEARCH_USER_PATHS": False,
    "CLANG_ANALYZER_NONNULL": True,
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": True,
    "CLANG_ENABLE_OBJC_ARC": True,
    "COPY_PHASE_STRIP": False,
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": False,
    "ENABLE_STRICT_OBJC_MSGSEND": True,
    "GCC_OPTIMIZATION_LEVEL": "s",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SDKROOT": "iphoneos",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": "-O",
    "VALIDATE_PRODUCT": True,
}

def render_config(uuid, name, settings):
    lines = [f'\t\t{uuid} /* {name} */ = {{']
    lines.append(f'\t\t\tisa = XCBuildConfiguration;')
    lines.append(f'\t\t\tbuildSettings = {{')
    for k, v in settings.items():
        if isinstance(v, bool):
            v_str = "YES" if v else "NO"
        elif isinstance(v, list):
            items = ",\n\t\t\t\t\t".join(quote(x) for x in v)
            v_str = f'(\n\t\t\t\t\t{items}\n\t\t\t\t)'
        else:
            v_str = quote(str(v))
        lines.append(f'\t\t\t\t{k} = {v_str};')
    lines.append(f'\t\t\t}};')
    lines.append(f'\t\t\tname = {quote(name)};')
    lines.append(f'\t\t}};')
    return "\n".join(lines)

# Project configs
lines.append(render_config(u["proj_debug"], "Debug", proj_config_debug))
lines.append(render_config(u["proj_release"], "Release", proj_config_release))

# App target configs
lines.append(render_config(u["app_debug"], "Debug", app_config_debug))
lines.append(render_config(u["app_release"], "Release", app_config_release))

# Test target configs
test_config = {
    "BUNDLE_LOADER": "$(TEST_HOST)",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": True,
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.enigmak9.PokedexTutorialTests",
    "PRODUCT_NAME": "PokedexTutorialTests",
    "SWIFT_EMIT_LOC_STRINGS": False,
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/PokedexTutorial.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PokedexTutorial",
}
lines.append(render_config(u["test_debug"], "Debug", test_config))
lines.append(render_config(u["test_release"], "Release", test_config))

# UITest target configs
uitest_config = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "GENERATE_INFOPLIST_FILE": True,
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.enigmak9.PokedexTutorialUITests",
    "PRODUCT_NAME": "PokedexTutorialUITests",
    "SWIFT_EMIT_LOC_STRINGS": False,
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
    "TEST_TARGET_NAME": "PokedexTutorial",
}
lines.append(render_config(u["uitest_debug"], "Debug", uitest_config))
lines.append(render_config(u["uitest_release"], "Release", uitest_config))

lines.append("/* End XCBuildConfiguration section */")
lines.append("")
lines.append("/* Begin XCConfigurationList section */")

lines.append(f'\t\t{u["proj_config_list"]} /* Build configuration list for PBXProject "PokedexTutorial" */ = {{isa = XCConfigurationList; buildConfigurations = ({u["proj_debug"]} /* Debug */, {u["proj_release"]} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')
lines.append(f'\t\t{u["app_config_list"]} /* Build configuration list for PBXNativeTarget "PokedexTutorial" */ = {{isa = XCConfigurationList; buildConfigurations = ({u["app_debug"]} /* Debug */, {u["app_release"]} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')
lines.append(f'\t\t{u["test_config_list"]} /* Build configuration list for PBXNativeTarget "PokedexTutorialTests" */ = {{isa = XCConfigurationList; buildConfigurations = ({u["test_debug"]} /* Debug */, {u["test_release"]} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')
lines.append(f'\t\t{u["uitest_config_list"]} /* Build configuration list for PBXNativeTarget "PokedexTutorialUITests" */ = {{isa = XCConfigurationList; buildConfigurations = ({u["uitest_debug"]} /* Debug */, {u["uitest_release"]} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')

lines.append("/* End XCConfigurationList section */")
lines.append("")
lines.append("\t};")
lines.append(f'\trootObject = {u["project"]} /* Project object */;')
lines.append("}")

pbxproj_content = "\n".join(lines) + "\n"

# Write the file
output_path = "PokedexTutorial.xcodeproj/project.pbxproj"
with open(output_path, "w") as f:
    f.write(pbxproj_content)

print(f"Generated {output_path} ({len(pbxproj_content)} bytes)")
print("Done!")
