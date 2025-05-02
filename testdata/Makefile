# Simple Makefile for generating test images
TEMPLATE_DIR := template
SCRIPT_DIR := scripts
OUTPUT_DIR := images

# Get templates and formats
TEMPLATES := $(notdir $(wildcard $(TEMPLATE_DIR)/*))
FORMATS := $(basename $(notdir $(wildcard $(SCRIPT_DIR)/*.sh)))

# Create targets list with explicit paths
TARGETS := $(foreach t,$(TEMPLATES),$(foreach f,$(FORMATS),$(OUTPUT_DIR)/$(t).$(f)))

.PHONY: all clean info

# Default target - use -k to keep going if a format fails
all: 
	$(MAKE) -k $(TARGETS)

# Create output directory
$(OUTPUT_DIR):
	mkdir -p $@

# Debug info
info:
	@echo "Templates: $(TEMPLATES)"
	@echo "Formats: $(FORMATS)"
	@echo "Targets: $(TARGETS)"

# Explicit rules for each combination
define make_rule
$(OUTPUT_DIR)/$(1).$(2): $(TEMPLATE_DIR)/$(1) $(SCRIPT_DIR)/$(2).sh | $(OUTPUT_DIR)
	@echo "Building $$@..."
	@$(SCRIPT_DIR)/$(2).sh $(TEMPLATE_DIR)/$(1) $$@.tmp && mv $$@.tmp $$@ || (rm -f $$@.tmp; exit 1)
endef

# Generate the rules
$(foreach t,$(TEMPLATES),$(foreach f,$(FORMATS),$(eval $(call make_rule,$(t),$(f)))))

# Clean target
clean:
	rm -rf $(OUTPUT_DIR)