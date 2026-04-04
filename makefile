NAME = Hello
AUTHOR = Lua
UNIQUE_ID = 0xF4520
PRODUCT_CODE = CTR-H-LUA
DESCRIPTION = Swift project for the 3DS.
BANNER_AUDIO = sys/audio.wav
BANNER_IMAGE = sys/banner.png
ICON = sys/icon.png
LOGO = sys/logo.bcma.lz
VERSION_MAJOR = 0
VERSION_MINOR = 1
VERSION_MICRO = 0

HOST_IP = $(shell ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1)
IP = 192.168.1.49
PORT = 5000
DEBUG_PORT = 4003
LINK_PORT = 17491
AZAHAR = /Applications/azahar.app/Contents/MacOS/azahar

SWIFT_TOOLCHAIN = $(shell swiftly use --print-location)
SWIFT_TOOLCHAIN_BIN = $(SWIFT_TOOLCHAIN)/usr/bin

SWIFTC = swiftc
LD = $(DEVKITPRO)/devkitArm/arm-none-eabi/bin/ld
LDSCRIPT = $(DEVKITPRO)/devkitARM/arm-none-eabi/lib/3dsx.ld

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

CFLAGS = \
	-target arm-none-eabi -std=c23 -mcpu=mpcore -march=armv6k -ffreestanding -fno-builtin -O3 -mfloat-abi=hard \
	-fshort-enums -pedantic -Wno-keyword-macro \
	-isystem $(DEVKITPRO)/libctru/include -isystem $(DEVKITPRO)/devkitARM/arm-none-eabi/include
CXXFLAGS = \
	-target arm-none-eabi -std=c++23 -mcpu=mpcore -march=armv6k -ffreestanding -fno-builtin -O3 -mfloat-abi=hard \
	-pedantic -Wno-keyword-macro -fno-exceptions -fno-rtti
LFLAGS = -T $(LDSCRIPT) --no-pie -static -z max-page-size=0x1000 -no-gc-sections -z noexecstack
SWIFT_FLAGS = \
	-g -target armv6-none-none-eabi -Xcc -mcpu=mpcore -Xcc -march=armv6k -Xfrontend -disable-stack-protector \
	-cross-module-optimization \
	-swift-version 6 \
	-wmo \
	-parse-as-library \
	-nostdimport -nostdlibimport \
	-I modules/swift/.build/armv6-none-none-eabi/release/Modules \
	-O \
	-strict-memory-safety \
	-enable-experimental-feature BuiltinModule \
	-enable-experimental-feature Extern \
	-enable-experimental-feature Embedded \
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
	-enable-experimental-feature LiteralExpressions \
	-enable-experimental-feature BorrowAndMutateAccessors \
	-enable-experimental-feature BorrowInout \
	-enable-experimental-feature BorrowingSequence \
	-enable-experimental-feature ThenStatements \
	-enable-experimental-feature DoExpressions \
	-enable-experimental-feature EmbeddedExistentials \
	-Xcc -fmodule-map-file=sdk/sys/module.modulemap \
	-Xcc -I$(DEVKITPRO)/libctru/include \
	-Xcc -I$(DEVKITPRO)/devkitARM/arm-none-eabi/include \
	-Xcc -mfloat-abi=hard -Xcc -mfpu=vfp -Xcc -mcpu=mpcore -Xcc -march=armv6k -Xcc -fshort-enums

# -enable-experimental-feature CoroutineAccessors // broken with classes at the moment, will not compile

ELF = build/$(NAME).elf
CXI = build/$(NAME).cxi
CIA = build/$(NAME).cia
3DSX = build/$(NAME).3dsx
ROMFS = build/romfs.bin
BANNER_BIN = build/banner.bnr
ICON_BIN = build/icon.icn

CITRUS_SRC = $(wildcard sdk/citrus/*.swift)
DRAW_SRC = $(wildcard sdk/draw/*.swift)
APP_SRC = $(wildcard src/*.swift)

CITRUS_MOD = build/Citrus.swiftmodule
DRAW_MOD = build/Draw.swiftmodule
APP_OBJ = build/$(NAME).o
UNICODE_TABLES = $(wildcard modules/swift/.build/armv6-none-none-eabi/release/SwiftUnicodeDataTables.build/*.o)

SUBMODULES = modules/swift
SWIFT_STDLIB = modules/swift/.build/armv6-none-none-eabi/release/Modules/Swift.swiftmodule

all: $(CIA)

$(SWIFT_STDLIB):
	@cd modules/swift && SWIFT_POINTER_SIZE=4 swift build \
        --traits UnicodeDataTables \
        --triple armv6-none-none-eabi \
        -c release \
        -Xswiftc -O \
        -Xcc -mfloat-abi=hard \
        -Xcc -mfpu=vfp \
        -Xcc -mcpu=mpcore \
        -Xcc -march=armv6k \
        -Xcc -fshort-enums \
        -Xcc -ffreestanding \
        -Xcc -fno-exceptions \
        -Xcc -fno-rtti \
        -Xcc -nostdinc++

$(SUBMODULES):
	@git clone git@github.com:TeamPuzel/swift.git modules/swift

configure: $(SUBMODULES)
	@mkdir -p build

$(CITRUS_MOD): $(CITRUS_SRC) $(CITRUS_CSRC) $(DRAW_MOD) $(SWIFT_STDLIB)
	@$(SWIFTC) $(SWIFT_FLAGS) $(CITRUS_SRC) -I build -module-name Citrus -emit-module -emit-module-path $(CITRUS_MOD)

$(DRAW_MOD): $(DRAW_SRC) $(SWIFT_STDLIB)
	@$(SWIFTC) $(SWIFT_FLAGS) $(DRAW_SRC) -I build -module-name Draw -emit-module -emit-module-path $(DRAW_MOD)

$(APP_OBJ): $(APP_SRC) $(CITRUS_MOD) $(DRAW_MOD) $(SWIFT_STDLIB)
	@$(SWIFTC) $(SWIFT_FLAGS) $(APP_SRC) -I build -c -o $(APP_OBJ)

$(ELF): $(APP_OBJ) $(UNICODE_TABLES)
	@$(LD) $(LFLAGS) --start-group $(APP_OBJ) $(CTRU) $(LIBC) $(UNICODE_TABLES) --end-group -o $@

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

$(3DSX): $(ELF) $(ROMFS)
	@3dsxtool $(ELF) $(3DSX) --smdh=$(ICON_BIN) --romfs=$(ROMFS)

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
	@3dslink -a $(IP) $(3DSX)

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
	@$(DEVKITPRO)/devkitARM/bin/arm-none-eabi-gdb $(ELF) \
   	-ex "directory src sdk/citrus sdk/draw" \
    -ex "set architecture armv6k" \
    -ex "set remotetimeout 60" \
    -ex "set remote multiprocess-feature-packet off" \
    -ex "target remote $(IP):$(DEBUG_PORT)"

.PHONY: clean install run configure commands meta push serve debug-remote link

commands:
	@echo "Generating compile_commands.json..."
	@echo "[" > compile_commands.json
	@# Swift Draw Module files
	@$(foreach file, $(DRAW_SRC), \
		echo '  {' >> compile_commands.json; \
		echo '    "directory": "$(PWD)",' >> compile_commands.json; \
		echo '    "file": "$(file)",' >> compile_commands.json; \
		echo '    "command": "$(SWIFTC) $(SWIFT_FLAGS) $(DRAW_SRC) -I build -module-name Draw -emit-module -emit-module-path build/Draw.swiftmodule",' >> compile_commands.json; \
		echo '    "output": "build/Draw.swiftmodule"' >> compile_commands.json; \
		echo '  },' >> compile_commands.json; \
	)
	@# Swift Citrus Module files
	@$(foreach file, $(CITRUS_SRC), \
		echo '  {' >> compile_commands.json; \
		echo '    "directory": "$(PWD)",' >> compile_commands.json; \
		echo '    "file": "$(file)",' >> compile_commands.json; \
		echo '    "command": "$(SWIFTC) $(SWIFT_FLAGS) $(CITRUS_SRC) -I build -module-name Citrus -emit-module -emit-module-path build/Citrus.swiftmodule",' >> compile_commands.json; \
		echo '    "output": "build/Citrus.swiftmodule"' >> compile_commands.json; \
		echo '  },' >> compile_commands.json; \
	)
	@# Swift App files
	@$(foreach file, $(APP_SRC), \
		echo '  {' >> compile_commands.json; \
		echo '    "directory": "$(PWD)",' >> compile_commands.json; \
		echo '    "file": "$(file)",' >> compile_commands.json; \
		echo '    "command": "$(SWIFTC) $(SWIFT_FLAGS) $(APP_SRC) -I build -c -o build/$(NAME).o",' >> compile_commands.json; \
		echo '    "output": "build/$(NAME).o"' >> compile_commands.json; \
		echo '  },' >> compile_commands.json; \
	)
	@# Remove trailing comma from the last entry to ensure valid JSON (macOS sed syntax)
	@sed -i '' -e '$$ s/},/}/' compile_commands.json
	@echo "]" >> compile_commands.json
	@echo "compile_commands.json created successfully."
