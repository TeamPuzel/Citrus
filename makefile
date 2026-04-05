# ============================================= Citrus Build Configuration =============================================
#  This is a not-so-simple but relatively clean makefile setup used to easily build and manage a homebrew Swift program
# ======================================================================================================================
#                                             --- Copyright (c) 2026 Lua ---
#                                                      License: MIT

# --- Project Configuration --------------------------------------------------------------------------------------------
# Information used for the app template and bundling process.
NAME                  = Hello
AUTHOR                = Lua
UNIQUE_ID             = 0xF4520
PRODUCT_CODE          = CTR-H-LUA
DESCRIPTION           = Swift project for the 3DS.
BANNER_AUDIO          = sys/audio.wav
BANNER_IMAGE          = sys/banner.png
ICON                  = sys/icon.png
LOGO                  = sys/logo.bcma.lz
VERSION_MAJOR         = 0
VERSION_MINOR         = 1
VERSION_MICRO         = 0

# --- Build Configuration ----------------------------------------------------------------------------------------------
# Conditionally configures build settings at a higher level.
BUILD_TYPE            = Release
DEBUG_INFO            = Yes
ENABLE_UNICODE_DATA   = Yes

# --- Run/Debug Configuration ------------------------------------------------------------------------------------------
# Information used to automate integration with editors and 3DS hardware.
HOST_IP               = $(shell ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1)
IP                    = 192.168.1.49
PORT                  = 5000
DEBUG_PORT            = 4003
LINK_PORT             = 17491
AZAHAR                = /Applications/azahar.app/Contents/MacOS/azahar

# --- Tool Configuration -----------------------------------------------------------------------------------------------
# Information used to find required tooling and relevant files.
SWIFT_TOOLCHAIN       = $(shell swiftly use --print-location)
SWIFT_TOOLCHAIN_BIN   = $(SWIFT_TOOLCHAIN)/usr/bin
SWIFTC                = swiftc
GYB                   = utils/gyb/gyb

LD                    = $(DEVKITPRO)/devkitArm/arm-none-eabi/bin/ld
LDSCRIPT              = $(DEVKITPRO)/devkitARM/arm-none-eabi/lib/3dsx.ld

DBG                   = $(DEVKITPRO)/devkitARM/bin/arm-none-eabi-gdb

# --- Link Files -------------------------------------------------------------------------------------------------------
# Vendor files linked into the app for platform support.
CTRU = \
	$(DEVKITPRO)/libctru/lib/libctru.a
LIBC = \
	$(DEVKITPRO)/devkitARM/arm-none-eabi/lib/armv6k/fpu/3dsx_crt0.o \
	$(DEVKITPRO)/devkitARM/lib/gcc/arm-none-eabi/15.2.0/armv6k/fpu/crti.o \
	$(DEVKITPRO)/devkitARM/lib/gcc/arm-none-eabi/15.2.0/armv6k/fpu/crtn.o \
	$(DEVKITPRO)/devkitARM/arm-none-eabi/lib/armv6k/fpu/libc.a \
	$(DEVKITPRO)/devkitARM/arm-none-eabi/lib/armv6k/fpu/libg.a \
	$(DEVKITPRO)/devkitARM/arm-none-eabi/lib/armv6k/fpu/libm.a \
	$(DEVKITPRO)/devkitARM/lib/gcc/arm-none-eabi/15.2.0/armv6k/fpu/libgcc.a \
	$(DEVKITPRO)/devkitARM/arm-none-eabi/lib/armv6k/fpu/libsysbase.a \
	$(DEVKITPRO)/devkitARM/lib/gcc/arm-none-eabi/15.2.0/armv6k/fpu/libgcov.a

# --- Tool Flags -------------------------------------------------------------------------------------------------------
CFLAGS = \
	-target arm-none-eabi -std=c23 -mcpu=mpcore -march=armv6k -ffreestanding -fno-builtin -O3 -mfloat-abi=hard \
	-fshort-enums -pedantic -Wno-keyword-macro \
	-isystem $(DEVKITPRO)/libctru/include -isystem $(DEVKITPRO)/devkitARM/arm-none-eabi/include
CXXFLAGS = \
	-target arm-none-eabi -std=c++23 -mcpu=mpcore -march=armv6k -ffreestanding -fno-builtin -O3 -mfloat-abi=hard \
	-pedantic -Wno-keyword-macro -fno-exceptions -fno-rtti
LFLAGS = -T $(LDSCRIPT) --no-pie -static -z max-page-size=0x1000 -no-gc-sections -z noexecstack

# The Swift pointer size.
SWIFT_POINTER_SIZE = 4

# Bloat only relevant to Apple platforms.
SWIFT_AVAILABILITY = \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 9999:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.0:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.1:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.2:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.3:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.4:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.5:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.6:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.7:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.8:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.9:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 5.10:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 6.0:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 6.1:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 6.2:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 6.3:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftStdlib 6.4:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftCompatibilitySpan 5.0:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "SwiftCompatibilitySpan 6.2:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 9999:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.0:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.1:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.2:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.3:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.4:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.5:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.6:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.7:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.8:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.9:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 5.10:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 6.0:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 6.1:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 6.2:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 6.3:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0" \
	-Xfrontend -define-availability \
	-Xfrontend "StdlibDeploymentTarget 6.4:macOS 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0, visionOS 1.0"

SWIFT_FEATURES = \
	-enable-experimental-feature BuiltinModule \
	-enable-experimental-feature Extern \
	-enable-experimental-feature SymbolLinkageMarkers \
	-enable-experimental-feature ValueGenerics \
	-enable-experimental-feature LifetimeDependence \
	-enable-experimental-feature Lifetimes \
	-enable-experimental-feature RawLayout \
	-enable-experimental-feature Volatile \
	-enable-experimental-feature ReferenceBindings \
	-enable-experimental-feature MoveOnlyTuples \
	-enable-experimental-feature MoveOnlyClasses \
	-enable-experimental-feature StructLetDestructuring \
	-enable-experimental-feature CompileTimeValues \
	-enable-experimental-feature BorrowAndMutateAccessors \
	-enable-experimental-feature BorrowInout \
	-enable-experimental-feature BorrowingSequence \
	-enable-experimental-feature ThenStatements \
	-enable-experimental-feature AddressableTypes \
	-enable-experimental-feature AddressableParameters \
	-enable-experimental-feature Reparenting \
	-enable-experimental-feature TypedThrows \
	-enable-experimental-feature StaticExclusiveOnly

# -enable-experimental-feature CoroutineAccessors # broken with classes at the moment, will not compile.
# -enable-experimental-feature DoExpressions      # broken with typed throws at the moment, breaks stdlib.
# -enable-experimental-feature LiteralExpressions # broken with complex enum raw values.

# General flags for Swift code.
SWIFT_COREFLAGS = $(SWIFT_AVAILABILITY) \
	-g \
	-target armv6-none-none-eabi \
	-cross-module-optimization \
	-swift-version 6 \
	-wmo \
	-parse-as-library \
	-nostdimport -nostdlibimport \
	-strict-memory-safety \
	$(SWIFT_FEATURES) \
	-enable-experimental-feature Embedded \
	-enable-experimental-feature EmbeddedExistentials \
	-Xcc -fmodule-map-file=sdk/sys/module.modulemap \
	-Xcc -fmodule-map-file=sdk/shims/module.modulemap \
	-Xcc -I$(DEVKITPRO)/libctru/include \
	-Xcc -I$(DEVKITPRO)/devkitARM/arm-none-eabi/include \
	-Xcc -mfloat-abi=hard \
	-Xcc -mfpu=vfp \
	-Xcc -mcpu=mpcore \
	-Xcc -march=armv6k \
	-Xcc -fshort-enums \
	-Xfrontend -disable-stack-protector

ifeq ($(BUILD_TYPE), Release)
	SWIFT_COREFLAGS += -O
else ifeq ($(BUILD_TYPE), Size)
	SWIFT_COREFLAGS += -Osize
else ifeq ($(BUILD_TYPE), Debug)
	SWIFT_COREFLAGS += -Onone
else
	$(error BUILD_TYPE must be set to Debug, Release or Size)
endif

ifeq ($(DEBUG_INFO), Yes)
	SWIFT_COREFLAGS += -g
else ifeq ($(DEBUG_INFO), No)
	SWIFT_COREFLAGS += -gnone
else
	$(error DEBUG_INFO must be set to Yes or No)
endif

ifeq ($(ENABLE_UNICODE_DATA), Yes)
	SWIFT_COREFLAGS += -DSWIFT_STDLIB_ENABLE_UNICODE_DATA
else ifeq ($(ENABLE_UNICODE_DATA), No)
else
	$(error ENABLE_UNICODE_DATA must be set to Yes or No)
endif

# Flags for normal Swift code.
SWIFT_FLAGS = $(SWIFT_COREFLAGS) \
	-Xfrontend -import-module -Xfrontend _Unicode \
	-Xfrontend -import-module -Xfrontend _Volatile
# -Xfrontend -import-module -Xfrontend _Concurrency

# Flags for the Swift Standard Library.
SWIFT_STDFLAGS = $(SWIFT_COREFLAGS) -swift-version 5 -parse-stdlib

# --- Misc Declarations ------------------------------------------------------------------------------------------------
# Things I found no better place for yet.
ELF           = build/$(NAME).elf
CXI           = build/$(NAME).cxi
CIA           = build/$(NAME).cia
3DSX          = build/$(NAME).3dsx
ROMFS         = build/romfs.bin
BANNER_BIN    = build/banner.bnr
ICON_BIN      = build/icon.icn

# --- Default ----------------------------------------------------------------------------------------------------------
# The conventional command used to build the most useful distributable bundle format.
all: $(CIA)

# --- Module Definition ------------------------------------------------------------------------------------------------
# A simple macro system for easier declaration of Swift modules.
MODULES =

define MODULE_DEF # $(1): Module Name, $(2): Module Directory, $(3): Dependencies, $(4): Flags
$(1)_SRC     = $$(foreach dir,$(2),$$(wildcard $$(dir)/*.swift))
$(1)_GYB     = $$(foreach dir,$(2),$$(wildcard $$(dir)/*.swift.gyb))
$(1)_GYB_SRC = $$(patsubst %.swift.gyb, build/gyb/%.swift, $$($(1)_GYB))
$(1)_ALL_SRC = $$($(1)_SRC) $$($(1)_GYB_SRC)

$(1)_MOD     = build/$(1).swiftmodule
$(1)_CMD     = $$(SWIFTC) $(4) $$($(1)_ALL_SRC) -I build -module-name $(1) -emit-module -emit-module-path $$($(1)_MOD)

$$($(1)_MOD): $$($(1)_ALL_SRC) $(3)
	@echo "Compiling $(1)..."
	@$$($(1)_CMD)

MODULES += $(1)
endef

# --- Configuration ----------------------------------------------------------------------------------------------------
# Utility logic to prepare the project for use with other commands.
configure:
	@mkdir -p build

# --- Swift Gyb --------------------------------------------------------------------------------------------------------
# Swift (unfortunately) uses a python script to instantiate templates for some source files.
# It is not impossible to get rid of the Swift build system for these modules, but gyb has to stay.
GYB_FLAGS = -DCMAKE_SIZEOF_VOID_P=$(SWIFT_POINTER_SIZE)

build/gyb/%.swift: %.swift.gyb
	@mkdir -p $(dir $@)
	@$(GYB) $(GYB_FLAGS) --line-directive '' -o $@ $<

# --- Unicode Tables ---------------------------------------------------------------------------------------------------
# To have Unicode support we need the Unicode runtime. I have ported the runtime to Swift to avoid depending on
# C++ (though in this case it's a rather portable subset it doesn't hurt to streamline things).
# We need to generate the tables as well which is done by utils/unicode, a port of Swift's table generator.
# It is critical to resolve files by hand as the order they are evaluated is important in script mode.
UNICODE_TABLES = build/unicode/tables.swift
UNICODE_GENERATOR = $(wildcard utils/unicode/*.swift)
UNICODE_GENERATOR_FLAGS = -parse-as-library
UNICODE_GENERATOR_CMD = $(SWIFTC) $(UNICODE_GENERATOR) $(SWIFT_FEATURES) $(UNICODE_GENERATOR_FLAGS) \
	-O -o build/unicode-generator

ifeq ($(shell uname -s), Darwin)
	UNICODE_GENERATOR_CMD += -sdk $(shell xcrun --show-sdk-path)
endif

$(UNICODE_TABLES): $(UNICODE_GENERATOR)
	@mkdir -p build/unicode
	@echo "Generating Unicode tables..."
	@$(UNICODE_GENERATOR_CMD)
	@build/unicode-generator > $(UNICODE_TABLES)

uni-tables: $(UNICODE_TABLES)

# --- Swift Standard Modules -------------------------------------------------------------------------------------------
# Swift does not normally build these for whatever platform we choose easily (for now) but worst of all
# parts of the implementation use C++. For the sake of my sanity I have ported them to Swift and simplified the
# build process to avoid any overly complex tooling.
$(eval $(call MODULE_DEF,Swift,sdk/swift,,$(SWIFT_STDFLAGS)))
$(eval $(call MODULE_DEF,_Unicode,sdk/unicode build/unicode,$(Swift_MOD),$(SWIFT_STDFLAGS)))
$(eval $(call MODULE_DEF,_Volatile,sdk/volatile,$(Swift_MOD),$(SWIFT_STDFLAGS)))
$(eval $(call MODULE_DEF,Synchronization,sdk/synchronization,$(Swift_MOD),$(SWIFT_COREFLAGS)))
#$(eval $(call MODULE_DEF,_Concurrency,sdk/concurrency,$(Swift_MOD),$(SWIFT_STDFLAGS) -DSWIFT_CONCURRENCY_EMBEDDED))

SWIFT_STDLIB = \
	$(Swift_MOD) \
	$(_Unicode_MOD) \
	$(_Volatile_MOD) \
	$(Synchronization_MOD) \
	$(_Concurrency_MOD)

# --- Citrus Modules ---------------------------------------------------------------------------------------------------
# Configuration of framework modules and application objects.
$(eval $(call MODULE_DEF,Draw,sdk/draw,$(SWIFT_STDLIB),$(SWIFT_FLAGS)))
$(eval $(call MODULE_DEF,Citrus,sdk/citrus,$(SWIFT_STDLIB) $(Draw_MOD),$(SWIFT_FLAGS)))

APP_SRC = $(wildcard src/*.swift)
APP_OBJ = build/$(NAME).o
$(APP_OBJ): $(APP_SRC) $(Citrus_MOD) $(Draw_MOD) $(SWIFT_STDLIB)
	@$(SWIFTC) $(SWIFT_FLAGS) $(APP_SRC) -I build -c -o $(APP_OBJ)

# --- App Products -----------------------------------------------------------------------------------------------------
# Application products such as binaries, resources and differend kinds of distributable bundles.
$(ELF): $(APP_OBJ)
	@$(LD) $(LFLAGS) --start-group $(APP_OBJ) $(CTRU) $(LIBC) --end-group -o $@

$(ROMFS):
	@3dstool -ctf romfs build/romfs.bin --romfs-dir romfs

$(CIA): $(ELF) $(ROMFS) $(BANNER_BIN) $(ICON_BIN)
	@makerom -f cia -o $@ -elf $< -target t -rsf sys/app.rsf -romfs $(ROMFS) -exefslogo \
	-major $(VERSION_MAJOR) -minor $(VERSION_MINOR) -micro $(VERSION_MICRO) \
	-DNAME=$(NAME) -DPRODUCT_CODE=$(PRODUCT_CODE) -DUNIQUE_ID=$(UNIQUE_ID) \
	-icon $(ICON_BIN) -banner $(BANNER_BIN) # -logo $(LOGO)

$(CXI): $(ELF) $(ROMFS) $(BANNER_BIN) $(ICON_BIN)
	@makerom -f cxi -o $@ -elf $< -target t -rsf sys/app.rsf -romfs $(ROMFS) -exefslogo \
	-major $(VERSION_MAJOR) -minor $(VERSION_MINOR) -micro $(VERSION_MICRO) \
	-DNAME=$(NAME) -DPRODUCT_CODE=$(PRODUCT_CODE) -DUNIQUE_ID=$(UNIQUE_ID) \
	-icon $(ICON_BIN) -banner $(BANNER_BIN) # -logo $(LOGO)

$(3DSX): $(ELF) $(ROMFS) $(ICON_BIN)
	@3dsxtool $(ELF) $(3DSX) --smdh=$(ICON_BIN) --romfs=romfs

$(BANNER_BIN) $(ICON_BIN):
	@bannertool makebanner -i $(BANNER_IMAGE) -a $(BANNER_AUDIO) -o $(BANNER_BIN)
	@bannertool makesmdh -i $(ICON) -l $(NAME) -s $(NAME) -p $(AUTHOR) -o $(ICON_BIN)

clean:
	@rm -rf build
	@rm -f compile_commands.json

install: $(CIA)
	@$(AZAHAR) -i $(realpath $(CIA))

run: $(CXI)
	@$(AZAHAR) $(realpath $(CXI))

link: $(3DSX)
	@3dslink -a $(IP) $(3DSX) -0 sdmc:/3ds/$(NAME).3dsx

serve:
	@caddy file-server --root build --listen :8001

push: $(CIA)
	@$(eval URL := http://$(HOST_IP):8001/$(NAME).cia)
	@$(eval LEN := $(shell printf '%s' '$(URL)' | wc -c))
	@$(eval HEXLEN := $(shell printf '%08x' $(LEN)))
	@echo "Sending $(URL) (length: $(LEN)) to $(IP)..."
	@{ \
		printf "\x$$(echo $(HEXLEN) | cut -c1-2)"; \
		printf "\x$$(echo $(HEXLEN) | cut -c3-4)"; \
		printf "\x$$(echo $(HEXLEN) | cut -c5-6)"; \
		printf "\x$$(echo $(HEXLEN) | cut -c7-8)"; \
		printf "%s" "$(URL)"; \
	} | nc -w 2 $(IP) $(PORT)

debug-remote:
	@$(DBG) $(ELF) \
   	-ex "directory src sdk/citrus sdk/draw" \
    -ex "set architecture armv6k" \
    -ex "set remotetimeout 60" \
    -ex "set remote multiprocess-feature-packet off" \
    -ex "target remote $(IP):$(DEBUG_PORT)"

commands:
	@echo "Generating compile_commands.json..."
	@printf "[\n" > compile_commands.json
	@first=1; \
	$(foreach mod,$(MODULES), \
		cmd='$(subst ','\'',$($(mod)_CMD))'; \
		esc_cmd=$$(printf "%s" "$$cmd" | sed 's/"/\\"/g'); \
		out='$($(mod)_MOD)'; \
		for file in $($(mod)_ALL_SRC); do \
			if [ $$first -ne 1 ]; then printf ",\n" >> compile_commands.json; fi; \
			first=0; \
			printf "  {\n" >> compile_commands.json; \
			printf "    \"directory\": \"%s\",\n" "$(PWD)" >> compile_commands.json; \
			printf "    \"file\": \"%s\",\n" "$$file" >> compile_commands.json; \
			printf "    \"command\": \"%s\",\n" "$$esc_cmd" >> compile_commands.json; \
			printf "    \"output\": \"%s\"\n" "$$out" >> compile_commands.json; \
			printf "  }" >> compile_commands.json; \
		done; \
	) \
	app_cmd='$(subst ','\'',$(SWIFTC) $(SWIFT_FLAGS) $(APP_SRC) -I build -c -o $(APP_OBJ))'; \
	esc_app_cmd=$$(printf "%s" "$$app_cmd" | sed 's/"/\\"/g'); \
	for file in $(APP_SRC); do \
		if [ $$first -ne 1 ]; then printf ",\n" >> compile_commands.json; fi; \
		first=0; \
		printf "  {\n" >> compile_commands.json; \
		printf "    \"directory\": \"%s\",\n" "$(PWD)" >> compile_commands.json; \
		printf "    \"file\": \"%s\",\n" "$$file" >> compile_commands.json; \
		printf "    \"command\": \"%s\",\n" "$$esc_app_cmd" >> compile_commands.json; \
		printf "    \"output\": \"%s\"\n" "build/$(NAME).o" >> compile_commands.json; \
		printf "  }" >> compile_commands.json; \
	done; \
	generator_cmd='$(subst ','\'',$(UNICODE_GENERATOR_CMD))'; \
	esc_generator_cmd=$$(printf "%s" "$$generator_cmd" | sed 's/"/\\"/g'); \
	for file in $(UNICODE_GENERATOR); do \
		if [ $$first -ne 1 ]; then printf ",\n" >> compile_commands.json; fi; \
		first=0; \
		printf "  {\n" >> compile_commands.json; \
		printf "    \"directory\": \"%s\",\n" "$(PWD)" >> compile_commands.json; \
		printf "    \"file\": \"%s\",\n" "$$file" >> compile_commands.json; \
		printf "    \"command\": \"%s\",\n" "$$esc_generator_cmd" >> compile_commands.json; \
		printf "  }" >> compile_commands.json; \
	done
	@printf "\n]\n" >> compile_commands.json
	@echo "Done."

.PHONY: clean install run configure commands serve push debug-remote link
