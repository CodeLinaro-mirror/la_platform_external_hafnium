#
# Copyright (c) 2025, Google, Inc. All rights reserved
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/BSD-3-Clause.
#
#  This makefile contains rules for building Hafnium for Trusty.
#  It is expected that it will be included by the project that requires Hafnium
#  support and the caller will configure the following variables:
#
#      HAFNIUM_PLATFORM	       - The platform to build Hafnium for, e.g.,
#      				 secure_qemu_aarch64.
#
#  The following variable is returned to the caller:
#      HAFNIUM_BUILD_DIR  - Location that will be used to store temp files and
#                           build results.
#      HAFNIUM_BIN 	  - The output hafnium.bin binary.
#

LOCAL_DIR := $(GET_LOCAL_DIR)
HAFNIUM_BUILD_DIR := $(call TOBUILDDIR,$(LOCAL_DIR))
LIBFDT_DIR := external/dtc/libfdt

ifeq ($(HAFNIUM_PLATFORM),)
$(error HAFNIUM_PLATFORM is required to build Hafnium)
endif

ifeq ($(HAFNIUM_CLANG_BINDIR),)
HAFNIUM_CLANG_BINDIR := $(CLANG_BINDIR)
endif
HAFNIUM_CC := $(CCACHE) $(HAFNIUM_CLANG_BINDIR)/clang
HAFNIUM_LD := $(HAFNIUM_CLANG_BINDIR)/ld.lld
HAFNIUM_CLANG_RESOURCE_DIR := \
	$(shell $(HAFNIUM_CC) --print-resource-dir)

HAFNIUM_FLAGS :=
HAFNIUM_LDFLAGS :=

HAFNIUM_BIN := $(HAFNIUM_BUILD_DIR)/hafnium.bin
HAFNIUM_ELF := $(HAFNIUM_BUILD_DIR)/hafnium.elf

HAFNIUM_SRCS += \
	abort.c \
	api.c \
	boot_info.c \
	cpio.c \
	cpu.c \
	dlog.c \
	fdt.c \
	fdt_handler.c \
	fdt_patch.c \
	ffa_memory.c \
	hf_ipi.c \
	init.c \
	layout.c \
	load.c \
	main.c \
	manifest.c \
	memiter.c \
	mm.c \
	mpool.c \
	panic.c \
	partition_pkg.c \
	sp_pkg.c \
	std.c \
	stdout.c \
	string.c \
	timer_mgmt.c \
	transfer_list/transfer_list.c \
	vcpu.c \
	vm.c \

HAFNIUM_ARCH_SRCS += \
	cache_helpers.S \
	entry.S \
	irq.c \
	mm.c \
	smc.c \
	stacks.S \
	stack_protector.c \
	std.c \
	sysregs.c \
	timer.c \

HAFNIUM_HYP_SRCS += \
	arch_init.c \
	cpu.c \
	debug_el1.c \
	el1_physical_timer.c \
	exceptions.S \
	feature_id.c \
	ffa.c \
	fpu.c \
	handler.c \
	host_timer.c \
	hypervisor_entry.S \
	memcpy_trapped.S \
	other_world.c \
	perfmon.c \
	plat_entry.S \
	psci_handler.c \
	sme.c \
	sve.c \
	vm.c \

HAFNIUM_VMLIB_SRCS += \
	ffa.c \
	ffa_v1_0.c \

HAFNIUM_LIBFDT_SRCS := \
	fdt.c \
	fdt_addresses.c \
	fdt_check.c \
	fdt_ro.c \
	fdt_rw.c \
	fdt_wip.c \

ifeq ($(HAFNIUM_PLATFORM),secure_qemu_aarch64)
HAFNIUM_ARCH := aarch64

HAFNIUM_SRCS += \
	boot_flow/common.c \
	boot_flow/spmc.c \
	iommu/absent.c \
	memory_protect/absent.c \

HAFNIUM_ARCH_SRCS += \
	boot_flow/linux.S \
	pl011/pl011.c \
	plat/interrupts/gicv3.c \
	plat/prng/prng_fake.c \
	plat/psci/spmc.c \
	plat/smc/absent.c \

HAFNIUM_SRCS += \
	ffa/spmc/cpu_cycles.c \
	ffa/spmc/direct_messaging.c \
	ffa/spmc/ffa_memory.c \
	ffa/spmc/indirect_messaging.c \
	ffa/spmc/init.c \
	ffa/spmc/interrupts.c \
	ffa/spmc/notifications.c \
	ffa/spmc/setup_and_discovery.c \
	ffa/spmc/vm.c \

HAFNIUM_HYP_SRCS += \
	simd.c \

HAFNIUM_VMLIB_SRCS += \
	$(HAFNIUM_ARCH)/smc_call.c \

# Platform-specific flags
#
# TRUSTY: we need more memory, so we give Hafnium double the heap pages
# TRUSTY: TF-A has PLATFORM_CORE_COUNT=32 so we give Hafnium more CPUs too
# TODO: set LOG_LEVEL depending on the Trusty build
HAFNIUM_FLAGS += \
	-DHEAP_PAGES=360 \
	-DMAX_CPUS=32 \
	-DMAX_VMS=16 \
	-DLOG_LEVEL=LOG_LEVEL_INFO \
	-DENABLE_ASSERTIONS=1 \
	-DPARTITION_MAX_UUIDS=4 \
	-DPARTITION_MAX_MEMORY_REGIONS=8 \
	-DPARTITION_MAX_DEVICE_REGIONS=8 \
	-DPARTITION_MAX_DMA_DEVICES=2 \
	-DPARTITION_MAX_INTERRUPTS_PER_DEVICE=4 \
	-DPARTITION_MAX_STREAMS_PER_DEVICE=4 \
	-DHF_NUM_INTIDS=1024 \
	-DSECURE_WORLD=1 \

# Hardware flags
HAFNIUM_FLAGS += \
	-DGIC_VERSION=3 \
	-DGICD_BASE=0x08000000 \
	-DGICR_BASE=0x080A0000 \
	-DGICR_FRAMES=8 \
	-DPL011_BASE=0x09000000 \

HAFNIUM_ORIGIN_ADDRESS := 0xe200000
else
$(error unrecognized Hafnium platform: $(HAFNIUM_PLATFORM))
endif

HAFNIUM_SRCS := \
	$(addprefix $(LIBFDT_DIR)/,$(HAFNIUM_LIBFDT_SRCS)) \
	$(addprefix $(LOCAL_DIR)/src/,$(HAFNIUM_SRCS)) \
	$(addprefix $(LOCAL_DIR)/src/arch/$(HAFNIUM_ARCH)/,$(HAFNIUM_ARCH_SRCS)) \
	$(addprefix $(LOCAL_DIR)/src/arch/$(HAFNIUM_ARCH)/hypervisor/,$(HAFNIUM_HYP_SRCS)) \
	$(addprefix $(LOCAL_DIR)/vmlib/,$(HAFNIUM_VMLIB_SRCS)) \

# Generic Hafnium build flags
HAFNIUM_FLAGS += \
	-DVM_TOOLCHAIN=0 \
	-O2 \
	-gdwarf-4 \
	-fcolor-diagnostics \
	-fstack-protector-all \
	-std=c11 \
	-ffunction-sections \
	-fdata-sections \
	-flto \
	-nostdinc \
	-fno-builtin \
	-ffreestanding \
	-fpic \

ifeq ($(HAFNIUM_ARCH),aarch64)
HAFNIUM_FLAGS += \
	-target aarch64-none-elf \
	-march=armv8.5-a+nopauth \
	-mcpu=cortex-a57+nofp \
	-mgeneral-regs-only \
	-mstrict-align \
	-DENABLE_MTE=0 \

else
$(error unknown or undefined Hafnium architecture $(HAFNIUM_ARCH))
endif

HAFNIUM_FLAGS += \
	-isystem $(HAFNIUM_CLANG_RESOURCE_DIR)/include \
	-isystem prebuilts/build-tools/sysroots/aarch64-unknown-linux-musl/include \
	-I $(LOCAL_DIR)/inc \
	-I $(LOCAL_DIR)/inc/vmapi \
	-I $(LOCAL_DIR)/src/arch/$(HAFNIUM_ARCH) \
	-I $(LOCAL_DIR)/src/arch/$(HAFNIUM_ARCH)/inc \
	-I $(LOCAL_DIR)/android/hafnium_inc \
	-I $(HAFNIUM_BUILD_DIR)/gen \
	-I $(LIBFDT_DIR) \

HAFNIUM_LDFLAGS += \
	-pie \
	--gc-sections \
	-O2 \
	--icf=all \
	--color-diagnostics \
	-T $(LOCAL_DIR)/build/image/image.ld \
	--defsym=ORIGIN_ADDRESS=$(HAFNIUM_ORIGIN_ADDRESS) \

# Variables for generic_compile.mk
# We should use module.mk here, but none of its variables are set up
# by the time the project build file is included.
GENERIC_CC := $(HAFNIUM_CC)
GENERIC_SRCS := $(HAFNIUM_SRCS)
GENERIC_OBJ_DIR := $(HAFNIUM_BUILD_DIR)/obj
GENERIC_FLAGS := $(HAFNIUM_FLAGS)
GENERIC_CFLAGS :=
GENERIC_CPPFLAGS :=
GENERIC_SRCDEPS :=
include make/generic_compile.mk
HAFNIUM_OBJS := $(GENERIC_OBJS)

# Generate offsets.h from offsets.c
HAFNIUM_OFFSETS_HDR := $(HAFNIUM_BUILD_DIR)/gen/hf/arch/offsets.h
HAFNIUM_OFFSETS_OBJ := $(HAFNIUM_BUILD_DIR)/gen/offsets.o
HAFNIUM_OFFSETS_PY := $(LOCAL_DIR)/build/toolchain/gen_offset_size_header.py
HAFNIUM_OFFSETS_SRC := $(LOCAL_DIR)/src/arch/$(HAFNIUM_ARCH)/hypervisor/offsets.c

# Some of the .S files include offsets.h
HAFNIUM_ASM_OBJS := $(filter %.S.o,$(HAFNIUM_OBJS))
$(HAFNIUM_ASM_OBJS): $(HAFNIUM_OFFSETS_HDR)

$(HAFNIUM_OFFSETS_OBJ): CC := $(HAFNIUM_CC)
$(HAFNIUM_OFFSETS_OBJ): FLAGS := $(HAFNIUM_FLAGS)
$(HAFNIUM_OFFSETS_OBJ): $(HAFNIUM_OFFSETS_SRC)
	@$(MKDIR)
	$(NOECHO)$(CC) $(FLAGS) -DGENERATE_BINARY -fno-lto -c $< -o $@

$(HAFNIUM_OFFSETS_HDR): CLANG_BINDIR := $(HAFNIUM_CLANG_BINDIR)
$(HAFNIUM_OFFSETS_HDR): OFFSETS_PY := $(HAFNIUM_OFFSETS_PY)
$(HAFNIUM_OFFSETS_HDR): OFFSETS_OBJ := $(HAFNIUM_OFFSETS_OBJ)
$(HAFNIUM_OFFSETS_HDR): OFFSETS_HDR := $(HAFNIUM_OFFSETS_HDR)
$(HAFNIUM_OFFSETS_HDR): $(HAFNIUM_OFFSETS_OBJ) $(HAFNIUM_OFFSETS_PY)
	@$(MKDIR)
	@$(call ECHO,$(MODULE),generating,$@)
	$(NOECHO)env PATH=$(CLANG_BINDIR):$(PATH) $(PY3) $(OFFSETS_PY) $(OFFSETS_OBJ) $(OFFSETS_HDR)
	@$(call ECHO_DONE_SILENT,$(MODULE),generating,$@)

GENERATED += $(HAFNIUM_OFFSETS_OBJ) $(HAFNIUM_OFFSETS_HDR)

# Link the hypervisor
$(HAFNIUM_ELF): LD := $(HAFNIUM_LD)
$(HAFNIUM_ELF): LDFLAGS := $(HAFNIUM_LDFLAGS)
$(HAFNIUM_ELF): OBJS := $(HAFNIUM_OBJS)
$(HAFNIUM_ELF): $(HAFNIUM_OBJS) $(LK_BIN)
	@$(call ECHO,$(MODULE),linking,$@)
	$(NOECHO)$(LD) $(LDFLAGS) --start-group $(OBJS) --end-group -o $@
	@$(call ECHO_DONE_SILENT,$(MODULE),linking,$@)

# TODO: use convert_to_binary.py?
$(HAFNIUM_BIN): $(HAFNIUM_ELF)
	@$(call ECHO_LOG,Generating image: $@)
	$(NOECHO)$(OBJCOPY) -O binary $< $@

ALLSRCS += $(HAFNIUM_SRCS)
ALLOBJS += $(HAFNIUM_OBJS)
GENERATED += $(HAFNIUM_BIN) $(HAFNIUM_ELF)
EXTRA_BUILDDEPS += $(HAFNIUM_BIN)

# Clear variables
LIBFDT_DIR :=
GENERIC_OBJS :=
HAFNIUM_ARCH :=
HAFNIUM_ARCH_SRCS :=
HAFNIUM_ASM_OBJS :=
HAFNIUM_CC :=
HAFNIUM_CLANG_RESOURCE_DIR :=
HAFNIUM_ELF :=
HAFNIUM_FLAGS :=
HAFNIUM_HYP_SRCS :=
HAFNIUM_LD :=
HAFNIUM_LDFLAGS :=
HAFNIUM_LIBFDT_SRCS :=
HAFNIUM_PLATFORM :=
HAFNIUM_PROJECT_DIR :=
HAFNIUM_OBJS :=
HAFNIUM_OFFSETS_HDR :=
HAFNIUM_OFFSETS_OBJ :=
HAFNIUM_OFFSETS_PY :=
HAFNIUM_OFFSETS_SRC :=
HAFNIUM_ORIGIN_ADDRESS :=
HAFNIUM_SRCS :=
HAFNIUM_VMLIB_SRCS :=
