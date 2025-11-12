#!/usr/bin/env python3
"""
generate_makefiles.py

This script generates Makefiles for a component-based build system,
letting Make handle the dependency resolution while the actual build
happens in containers via Dockerfile.
"""

import os
import sys
import glob
import hashlib
import logging
from pathlib import Path

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(message)s')
log = logging.getLogger('qemount-build')

class QemountBuildSystem:
    def __init__(self, project_root):
        self.project_root = Path(project_root).resolve()
        self.build_dir = self.project_root / "build"
        self.builder_dir = self.build_dir / "builder"
        self.component_dirs = ["guests", "clients", "common", "tests"]
        
        # Ensure directories exist
        self.builder_dir.mkdir(parents=True, exist_ok=True)
        
        # Storage for components
        self.components = []
    
    def find_components(self):
        """Find all components in the project."""
        components = []
        
        for base_dir in [self.project_root / d for d in self.component_dirs]:
            if not base_dir.exists():
                continue
                
            # Find all Dockerfile files
            for filepath in base_dir.glob(f"**/Dockerfile"):
                component_dir = filepath.parent
                component_path = component_dir.relative_to(self.project_root)
                components.append(str(component_path))
        
        # Sort and deduplicate
        return sorted(set(components))
    
    def load_component_metadata(self, component_path):
        """Load inputs and outputs for a component."""
        inputs_file = self.project_root / component_path / "inputs.txt"
        outputs_file = self.project_root / component_path / "outputs.txt"
        
        inputs = []
        if inputs_file.exists():
            with open(inputs_file, "r") as f:
                inputs = [line.strip() for line in f.readlines() if line.strip() and not line.strip().startswith('#')]
        
        outputs = []
        if outputs_file.exists():
            with open(outputs_file, "r") as f:
                outputs = [line.strip() for line in f.readlines() if line.strip() and not line.strip().startswith('#')]
        
        has_dockerfile = (self.project_root / component_path / "Dockerfile").exists()
        
        return {
            "path": component_path,
            "inputs": inputs,
            "outputs": outputs,
            "has_dockerfile": has_dockerfile
        }
    
    def is_component_path(self, path):
        """Check if a path is a component path."""
        for component in self.components:
            if component['path'] == path:
                return True
        return False
    
    def generate_component_makefile(self, component):
        """Generate a Makefile for a component."""
        makefile_path = self.builder_dir / component["path"] / "Makefile"
        makefile_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Generate container name for Dockerfile-based components
        container_name = f"qemount-{component['path'].replace('/', '-')}-$(ARCH)"
        lock_file = f"$(BUILD_DIR)/builder/{component['path']}/.{container_name}.lock"
        
        # Start with header
        lines = [
            f"# Generated Makefile for {component['path']}",
            f"ROOT_DIR := {self.project_root}",
            f"BUILD_DIR := {self.build_dir}",
            f"COMPONENT_DIR := {self.project_root}/{component['path']}",
            "ARCH ?= $(shell uname -m)",
            "PLATFORM ?= $(shell $(ROOT_DIR)/common/scripts/arch_to_platform.sh $(ARCH))",
            "REGISTRY ?= localhost",
            "",
            ".PHONY: all",
            ""
        ]
        
        # If component has a Dockerfile, add a lockfile target for build caching
        if component["has_dockerfile"]:
            lines.append(f"# Container build lock file for caching")
            lines.append(f"{lock_file}: $(ROOT_DIR)/{component['path']}/Dockerfile")
    
            # Add ALL files in the component directory as dependencies (container-like behavior)
            lines.append(f"{lock_file}: $(shell find $(ROOT_DIR)/{component['path']} -type f)")
    
            # Process explicit inputs for component dependencies
            for input_path in component["inputs"]:
                if self.is_component_path(input_path):
                    # Component dependencies still need explicit handling
                    input_container = f"qemount-{input_path.replace('/', '-')}-$(ARCH)"
                    input_lock = f"$(BUILD_DIR)/builder/{input_path}/.{input_container}.lock"
                    lines.append(f"{lock_file}: {input_lock}")

            lines.append(f"\t@mkdir -p $(dir $@)")
            lines.append(f"\t@echo \"Building container {container_name} for ARCH=$(ARCH)...\"")
            lines.append(f"\t@podman build --platform=$(PLATFORM) --build-arg ARCH=$(ARCH) -t $(REGISTRY)/{container_name} $(ROOT_DIR)/{component['path']}")
            lines.append(f"\t@touch $@")
            lines.append("")
        
        # Add targets
        if component["outputs"]:
            # All target depends on all outputs
            lines.append("all: " + " ".join([f"$(BUILD_DIR)/{output}" for output in component["outputs"]]))
            lines.append("")
            
            # Generate rule for each output
            for output in component["outputs"]:
                # Target
                target_line = f"$(BUILD_DIR)/{output}:"
                
                # Add dependencies
                for input_path in component["inputs"]:
                    # If input is a build output (doesn't exist in source tree)
                    if not (self.project_root / input_path).exists():
                        target_line += f" $(BUILD_DIR)/{input_path}"
                    elif self.is_component_path(input_path) and (self.project_root / input_path / "Dockerfile").exists():
                        # If the input is a component with a Dockerfile, depend on its lock file
                        input_container = f"qemount-{input_path.replace('/', '-')}-$(ARCH)"
                        input_lock = f"$(BUILD_DIR)/builder/{input_path}/.{input_container}.lock"
                        target_line += f" {input_lock}"
                    else:
                        target_line += f" $(ROOT_DIR)/{input_path}"
                
                # If using Dockerfile, add dependency on the lock file
                if component["has_dockerfile"]:
                    target_line += f" {lock_file}"
                
                lines.append(target_line)
                
                # Add build commands for Dockerfile
                output_dir = os.path.dirname(output)
                output_file = os.path.basename(output)
                
                # Create output directory
                lines.append(f"\t@mkdir -p $(dir $@)")
                
                # Use podman to extract output from container
                lines.append(f"\t@echo \"Extracting {output} from container {container_name}...\"")
                lines.append(f"\t@podman run --platform=$(PLATFORM) --rm -v $(BUILD_DIR):/host/build -e ARCH=$(ARCH) $(REGISTRY)/{container_name} {output}")
                
                lines.append("")
        else:
            # No outputs, just a generic target - in this case, the container build is the target
            if component["has_dockerfile"]:
                lines.append(f"all: {lock_file}")
                lines.append("")
            else:
                # Neither Dockerfile - probably just a placeholder
                lines.append("all:")
                lines.append(f"\t@echo \"Component {component['path']} has no Dockerfile\"")
                lines.append("")
        
        # Write makefile if it's new or changed
        new_content = "\n".join(lines)
        write_makefile = True
        
        if makefile_path.exists():
            with open(makefile_path, "r") as f:
                current_content = f.read()
                if current_content == new_content:
                    write_makefile = False
        
        if write_makefile:
            with open(makefile_path, "w") as f:
                f.write(new_content)
            log.info(f"Generated Makefile for {component['path']}")
    
    def generate_root_makefile(self):
        """Generate the root Makefile that includes all components."""
        makefile_path = self.build_dir / "Makefile"
        
        # Find all output targets from all components
        all_targets = []
        for component in self.components:
            all_targets.extend([f"$(BUILD_DIR)/{output}" for output in component["outputs"]])
        
        # Start with header
        lines = [
            "# Root Makefile for qemount build system",
            f"ROOT_DIR := {self.project_root}",
            f"BUILD_DIR := {self.build_dir}",
            "ARCH ?= $(shell uname -m)",
            "",
            ".PHONY: all clean clean-outputs clean-containers clean-makefiles clean-all refresh list",
            ""
        ]
        
        # Add main targets
        lines.append(f"all: {' '.join(all_targets)}")
        lines.append("")
        
        # Add include statements for all component Makefiles
        lines.append("# Include component makefiles")
        for component in self.components:
            component_makefile = f"$(BUILD_DIR)/builder/{component['path']}/Makefile"
            # Use -include to ignore missing files
            lines.append(f"-include {component_makefile}")
        lines.append("")
        
        # Add auto-regeneration rule
        lines.append("# Auto-regenerate makefiles if missing")
        lines.append(f"$(BUILD_DIR)/builder/%/Makefile: $(ROOT_DIR)/common/scripts/generate_makefiles.py")
        lines.append("\t@$(ROOT_DIR)/common/scripts/generate_makefiles.py")
        lines.append("")
        
        # Add clean targets
        lines.append("clean: clean-outputs clean-locks")
        lines.append("")

        lines.append("clean-outputs:")
        lines.append("\t@echo \"Removing build outputs...\"")
        # Clean all outputs
        for component in self.components:
            for output in component["outputs"]:
                lines.append(f"\t@rm -f $(BUILD_DIR)/{output}")
        lines.append("")

        lines.append("clean-locks:")
        lines.append("\t@echo \"Removing stale lock files...\"")
        lines.append("\t@find $(BUILD_DIR)/builder -name '.*.lock' -delete")
        lines.append("")

        lines.append("clean-containers:")
        lines.append("\t@echo \"Removing container images...\"")
        lines.append("\t@for container in $$(podman images --format '{{.Repository}}' | grep '^qemount-'); do \\")
        lines.append("\t    echo \"Removing $$container\"; \\")
        lines.append("\t    podman rmi -f $$container 2>/dev/null || true; \\")
        lines.append("\tdone")
        lines.append("")

        lines.append("clean-makefiles:")
        lines.append("\t@echo \"Removing generated makefiles...\"")
        lines.append("\t@find $(BUILD_DIR)/builder -name 'Makefile' -delete")
        lines.append("")

        lines.append("clean-all: clean-outputs clean-locks clean-containers clean-makefiles")
        lines.append("\t@echo \"Clean complete\"")
        lines.append("")
        
        # Add refresh target
        lines.append("refresh:")
        lines.append(f"\t@$(ROOT_DIR)/common/scripts/generate_makefiles.py")
        lines.append("")
        
        # Add list target
        lines.append("list:")
        lines.append("\t@echo \"Available components (for ARCH=$(ARCH)):\"")
        for component in self.components:
            # Show output files for each component
            lines.append(f"\t@echo \"  {component['path']}:\"")
            if component["outputs"]:
                for output in component["outputs"]:
                    lines.append(f"\t@echo \"    - {output}\"")
            else:
                lines.append(f"\t@echo \"    (no defined outputs)\"")
        lines.append("")
        
        # Write the makefile
        with open(makefile_path, "w") as f:
            f.write("\n".join(lines))
        
        log.info("Generated root Makefile")
    
    def generate_all_makefiles(self):
        """Generate all Makefiles."""
        log.info("Discovering components...")
        component_paths = self.find_components()
        
        log.info(f"Found {len(component_paths)} components")
        
        self.components = []
        for path in component_paths:
            component = self.load_component_metadata(path)
            self.components.append(component)
            log.info(f"Loaded metadata for {path} ({len(component['inputs'])} inputs, {len(component['outputs'])} outputs)")
        
        log.info("Generating component Makefiles...")
        for component in self.components:
            self.generate_component_makefile(component)
        
        log.info("Generating root Makefile...")
        self.generate_root_makefile()
        
        log.info("Done! To build, run: make")

if __name__ == "__main__":
    # Use current directory as project root by default
    project_root = os.getcwd()
    
    # Create and run build system
    build_system = QemountBuildSystem(project_root)
    build_system.generate_all_makefiles()
