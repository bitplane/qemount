#!/usr/bin/env python3
"""
generate_makefiles.py

This script generates Makefiles for a component-based build system,
letting Make handle the dependency resolution.
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
        self.component_dirs = ["guests", "clients", "common"]
        
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
                
            # Find all build.sh and Dockerfile files
            for file_type in ["build.sh", "Dockerfile"]:
                for filepath in base_dir.glob(f"**/{file_type}"):
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
                inputs = [line.strip() for line in f.readlines() if line.strip()]
        
        outputs = []
        if outputs_file.exists():
            with open(outputs_file, "r") as f:
                outputs = [line.strip() for line in f.readlines() if line.strip()]
        
        has_build_script = (self.project_root / component_path / "build.sh").exists()
        
        return {
            "path": component_path,
            "inputs": inputs,
            "outputs": outputs,
            "has_build_script": has_build_script
        }
    
    def generate_component_makefile(self, component):
        """Generate a Makefile for a component."""
        makefile_path = self.builder_dir / component["path"] / "Makefile"
        makefile_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Start with header
        lines = [
            f"# Generated Makefile for {component['path']}",
            f"ROOT_DIR := {self.project_root}",
            f"BUILD_DIR := {self.build_dir}",
            "",
            ".PHONY: all clean",
            ""
        ]
        
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
                    else:
                        target_line += f" $(ROOT_DIR)/{input_path}"
                
                lines.append(target_line)
                
                # Add build commands
                if component["has_build_script"]:
                    lines.append(f"\t@mkdir -p $(dir $@)")
                    lines.append(f"\t@$(ROOT_DIR)/{component['path']}/build.sh $@")
                else:
                    # Use Docker
                    container_name = f"qemount-{component['path'].replace('/', '-')}"
                    lines.append(f"\t@mkdir -p $(dir $@)")
                    lines.append(f"\t@podman build -t {container_name} $(ROOT_DIR)/{component['path']}")
                    lines.append(f"\t@podman run --rm -v $(BUILD_DIR):/output {container_name}")
                    lines.append(f"\t@if [ ! -f $@ ]; then touch $@; fi")
                
                lines.append("")
        else:
            # No outputs, just a generic target
            lines.append("all:")
            if component["has_build_script"]:
                lines.append(f"\t@$(ROOT_DIR)/{component['path']}/build.sh")
            else:
                container_name = f"qemount-{component['path'].replace('/', '-')}"
                lines.append(f"\t@podman build -t {container_name} $(ROOT_DIR)/{component['path']}")
                lines.append(f"\t@podman run --rm -v $(BUILD_DIR):/output {container_name}")
            lines.append("")
        
        # Add clean target
        lines.append("clean:")
        for output in component["outputs"]:
            lines.append(f"\trm -f $(BUILD_DIR)/{output}")
        
        container_name = f"qemount-{component['path'].replace('/', '-')}"
        lines.append(f"\tpodman rmi -f {container_name} 2>/dev/null || true")
        
        # Write makefile if it's new or changed
        new_content = "\n".join(lines)
        write_makefile = True
        
        if makefile_path.exists():
            with open(makefile_path, "r") as f:
                current_content = f.read()
                if hashlib.md5(current_content.encode()).hexdigest() == hashlib.md5(new_content.encode()).hexdigest():
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
            "",
            ".PHONY: all clean refresh list",
            ""
        ]
        
        # Add main targets
        lines.append(f"all: {' '.join(all_targets)}")
        lines.append("")
        
        # Add include statements for all component Makefiles
        for component in self.components:
            component_makefile = f"builder/{component['path']}/Makefile"
            lines.append(f"include {component_makefile}")
        
        # Add refresh target
        lines.append("refresh:")
        lines.append(f"\t@$(ROOT_DIR)/generate_makefiles.py")
        lines.append("")
        
        # Add list target
        lines.append("list:")
        lines.append("\t@echo \"Available components:\"")
        for component in self.components:
            lines.append(f"\t@echo \"  {component['path']}\"")
        
        # Write the makefile
        with open(makefile_path, "w") as f:
            f.write("\n".join(lines))
        
        log.info("Generated root Makefile")
    
    def generate_all_makefiles(self):
        """Generate all Makefiles."""
        log.info("Discovering components...")
        component_paths = self.find_components()
        
        self.components = []
        for path in component_paths:
            self.components.append(self.load_component_metadata(path))
        
        log.info("Generating component Makefiles...")
        for component in self.components:
            self.generate_component_makefile(component)
        
        log.info("Generating root Makefile...")
        self.generate_root_makefile()
        
        log.info("Done! To build, run: make -C build")

if __name__ == "__main__":
    # Use current directory as project root by default
    project_root = os.getcwd()
    
    # Create and run build system
    build_system = QemountBuildSystem(project_root)
    build_system.generate_all_makefiles()