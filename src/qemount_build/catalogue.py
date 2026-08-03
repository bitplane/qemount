"""
Catalogue loader for qemount build system.

Loads all markdown files from a directory tree, parsing YAML front-matter
into a flat dict keyed by relative path.
"""

import re
from pathlib import Path

import yaml


VAR_PATTERN = re.compile(r'\$\{(\w+)\}')


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """
    Parse YAML front-matter from markdown text.

    Returns (meta, content) tuple. If no front-matter found,
    returns empty dict and full text.
    """
    if not text.startswith("---"):
        return {}, text

    # Find closing ---
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text

    yaml_text = text[4:end]  # Skip opening ---\n
    content = text[end + 4:].lstrip("\n")  # Skip closing ---\n

    meta = yaml.safe_load(yaml_text) or {}
    return meta, content


def load_docs(root: Path) -> dict:
    """
    Load all markdown files from root directory into a catalogue.

    Returns dict mapping relative paths to {"meta": dict, "content": str}.
    """
    root = Path(root)
    docs = {}

    for md_file in sorted(root.rglob("*.md")):
        rel_path = str(md_file.relative_to(root))
        text = md_file.read_text()
        meta, content = parse_frontmatter(text)
        docs[rel_path] = {"meta": meta, "content": content}

    return docs


def doc_path(file_path: str, meta: dict) -> str:
    """
    Convert file path to logical catalogue path.

    Rules:
    - Explicit 'path' in meta wins
    - Strip 'docs/' prefix (web root for published docs)
    - Strip '/index.md' or '/README.md' suffix (directory becomes path)
    - Strip '.md' extension
    """
    if "path" in meta:
        return meta["path"]

    path = file_path

    if path.startswith("docs/"):
        path = path[5:]

    for suffix in ("/index.md", "/README.md"):
        if path.endswith(suffix):
            return path[:-len(suffix)]

    if path in ("index.md", "README.md"):
        return ""

    if path.endswith(".md"):
        return path[:-3]

    return path


def parent_path(path: str) -> str:
    """
    Get parent path in the catalogue hierarchy.

    Returns "" for root and top-level paths.
    """
    if "/" not in path:
        return ""
    return path.rsplit("/", 1)[0]


def normalize_list(items: list) -> dict:
    """
    Convert list to dict for merging.

    String items become keys with empty dict values.
    Dict items are merged into result.
    """
    result = {}
    for item in items:
        if isinstance(item, str):
            result[item] = {}
        elif isinstance(item, dict):
            result.update(item)
    return result


def merge_meta(parent: dict, child: dict, no_inherit: set = None, no_merge: set = None) -> dict:
    """
    Merge parent metadata into child.

    - Child keys extend/overwrite parent keys
    - Keys starting with "-" delete that key from parent
    - Lists are normalized to dicts before merging
    - Nested dicts are merged recursively (unless in no_merge)
    - Keys in no_inherit are not copied from parent
    - Keys in no_merge override parent entirely (no deep merge)
    """
    no_inherit = no_inherit or set()
    no_merge = no_merge or set()
    result = {}

    # Collect deletion markers from child
    deletions = {k[1:] for k in child if isinstance(k, str) and k.startswith("-")}

    # Copy parent keys that aren't deleted and aren't in no_inherit
    for key, value in parent.items():
        if key in deletions or key in no_inherit:
            continue
        result[key] = value

    # Merge child keys (skip deletion markers)
    for key, value in child.items():
        if isinstance(key, str) and key.startswith("-"):
            continue

        # Keys in no_merge override entirely - skip deep merge
        if key in no_merge:
            result[key] = value
            continue

        parent_val = result.get(key)

        # Normalize lists to dicts for merging
        if isinstance(value, list):
            value = normalize_list(value)
        if isinstance(parent_val, list):
            parent_val = normalize_list(parent_val)

        # Deep merge dicts
        if isinstance(value, dict) and isinstance(parent_val, dict):
            result[key] = merge_meta(parent_val, value, no_inherit, no_merge)
        else:
            result[key] = value

    return result


def map_paths(files: dict) -> dict:
    """
    Map file paths to logical catalogue paths.

    Returns dict mapping logical paths to {"sources": [file_paths]}.
    Raises ValueError if multiple files map to the same logical path.
    """
    paths = {}
    for file_path, doc in sorted(files.items()):
        path = doc_path(file_path, doc["meta"])
        if path not in paths:
            paths[path] = {"sources": []}
        paths[path]["sources"].append(file_path)

    duplicates = {
        path: data["sources"]
        for path, data in paths.items()
        if len(data["sources"]) > 1
    }
    if duplicates:
        details = "; ".join(
            f"{path or '<root>'}: {', '.join(sources)}"
            for path, sources in sorted(duplicates.items())
        )
        raise ValueError(f"Duplicate catalogue path(s): {details}")

    return paths


def resolve_inheritance(files: dict, paths: dict) -> dict:
    """
    Resolve inheritance for all paths.

    Walks up parent chain, merges metadata from root to leaf.
    Returns new paths dict with "meta" added to each path.

    Collects no_inherit and no_merge from each ancestor as we walk down.
    """
    result = {}

    for path, path_data in paths.items():
        # Build parent chain (leaf to root)
        chain = []
        current = path
        while True:
            if current in paths:
                chain.append(current)
            if not current:
                break
            current = parent_path(current)

        # Reverse to go root to leaf
        chain.reverse()

        # Merge metadata from root to leaf, collecting settings as we go
        merged = {}
        no_inherit = set()
        no_merge = set()
        for ancestor in chain:
            source = paths[ancestor]["sources"][0]
            meta = files[source]["meta"]
            # Collect settings from this level (before merge removes them)
            no_inherit.update(meta.get("no_inherit", []))
            no_merge.update(meta.get("no_merge", []))
            merged = merge_meta(merged, meta, no_inherit, no_merge)

        result[path] = {**path_data, "meta": merged}

    return result


def load(root: Path) -> dict:
    """
    Load catalogue from root directory.

    Returns {"files": {...}, "paths": {...}}.
    """
    files = load_docs(root)
    paths = map_paths(files)
    paths = resolve_inheritance(files, paths)
    return {"files": files, "paths": paths}


def resolve_vars(value: str, context: dict) -> str:
    """
    Replace ${VAR} with context values.

    Unresolved variables are left as-is.
    """
    def replace(match):
        var = match.group(1)
        return str(context.get(var, match.group(0)))
    return VAR_PATTERN.sub(replace, value)


def resolve_value(value, context: dict):
    """
    Recursively resolve variables in a value.

    Handles strings, lists, and dicts. Dict keys are also resolved.
    """
    if isinstance(value, str):
        return resolve_vars(value, context)
    if isinstance(value, list):
        return [resolve_value(v, context) for v in value]
    if isinstance(value, dict):
        return {
            resolve_vars(k, context) if isinstance(k, str) else k: resolve_value(v, context)
            for k, v in value.items()
        }
    return value


def resolve_env(env: dict, context: dict) -> dict:
    """
    Resolve env dict in definition order, accumulating into context.

    Each key is resolved using current context, then added to context
    for subsequent keys. Returns the updated context.
    """
    result = context.copy()
    for key, value in env.items():
        resolved = resolve_vars(value, result)
        result[key] = resolved
    return result


def resolve_path(path: str, catalogue: dict, context: dict) -> dict:
    """
    Get fully resolved metadata for a path.

    Walks ancestor chain resolving env at each level, then resolves
    all metadata values using the final context.
    """
    paths = catalogue["paths"]

    if path not in paths:
        raise KeyError(f"Path not found: {path}")

    # Build ancestor chain (root to leaf)
    chain = []
    current = path
    while True:
        if current in paths:
            chain.append(current)
        if not current:
            break
        current = parent_path(current)
    chain.reverse()

    # Walk chain, resolve env at each level
    ctx = context.copy()
    for ancestor in chain:
        meta = paths[ancestor]["meta"]
        if env := meta.get("env"):
            ctx = resolve_env(env, ctx)

    # Resolve all metadata values
    meta = paths[path]["meta"]
    resolved = resolve_value(meta, ctx)

    # Merge build_requires into requires (already normalized to dict by merge_meta)
    if "build_requires" in resolved:
        br = resolved["build_requires"]
        req = resolved.get("requires", {})
        for key in br:
            if key not in req:
                req[key] = br[key]

        resolved["requires"] = req

    return resolved


def resolve_output(path: str, output: str, catalogue: dict, context: dict) -> dict:
    """
    Get fully resolved metadata for a specific output from a path.

    The output inherits from its catalogue entry and can extend/override.
    Note: no_inherit/no_merge from path are for directory inheritance,
    not provides->output inheritance, so we don't apply them here.
    """
    path_meta = resolve_path(path, catalogue, context)
    output_meta = path_meta.get("provides", {}).get(output, {})

    if not output_meta:
        return path_meta

    return merge_meta(path_meta, output_meta)


def split_platform(platform: str | None) -> dict:
    """Return the canonical components of a target platform name."""
    if not platform:
        return {
            "OUTPUT_PLATFORM": "",
            "OUTPUT_ARCH": "",
            "OUTPUT_OS": "",
            "OUTPUT_ENV": "",
        }

    parts = platform.split("-")
    if len(parts) < 2:
        raise ValueError(f"Invalid output platform: {platform}")
    return {
        "OUTPUT_PLATFORM": platform,
        "OUTPUT_ARCH": parts[0],
        "OUTPUT_OS": parts[1],
        "OUTPUT_ENV": "-".join(parts[2:]),
    }


def provider_instance(path: str, output_platform: str | None) -> str:
    """Return a stable graph/cache identity for a provider variant."""
    return f"{path}@{output_platform}" if output_platform else path


def resolve_provider_instances(path: str, catalogue: dict, context: dict) -> list[dict]:
    """Resolve every output-platform variant of a catalogue provider."""
    base = resolve_path(path, catalogue, context)
    variants = base.get("output_platforms")
    platform_keys = list(variants) if variants else [None]
    result = []

    for platform_key in platform_keys:
        output_platform = None if platform_key == "neutral" else platform_key
        instance_context = {**context, **split_platform(output_platform)}
        meta = resolve_path(path, catalogue, instance_context)
        if platform_key is not None:
            variant_meta = meta.get("output_platforms", {}).get(platform_key, {})
            meta = merge_meta(
                meta, variant_meta, no_merge={"provides", "build_platforms"}
            )
            if isinstance(meta.get("provides"), list):
                meta["provides"] = normalize_list(meta["provides"])
        meta.pop("output_platforms", None)
        result.append(
            {
                "id": provider_instance(path, output_platform),
                "provider": path,
                "output_platform": output_platform,
                "context": instance_context,
                "meta": meta,
            }
        )

    return result


def output_meta(record: dict, output: str) -> dict:
    """Merge an output's metadata into its resolved provider variant."""
    meta = record["meta"]
    specific = meta.get("provides", {}).get(output, {})
    return merge_meta(meta, specific) if specific else meta


def build_provides_index(
    catalogue: dict, context: dict, build_dir: Path | None = None
) -> dict:
    """
    Build the available output-to-provider index for this context.

    Returns dict: {output: catalogue_path}
    """
    outputs = build_output_index(catalogue, context, build_dir)
    return {
        output: record["provider"]
        for output, record in outputs.items()
        if record["buildable"]
    }


def build_output_index(
    catalogue: dict, context: dict, build_dir: Path | None = None
) -> dict:
    """Describe every output and whether it is buildable in this context."""
    index = {}
    build_platform = context.get("BUILD_PLATFORM")

    for path in catalogue["paths"]:
        for instance in resolve_provider_instances(path, catalogue, context):
            meta = instance["meta"]
            build_platforms = meta.get("build_platforms", {})
            buildable = not build_platforms or build_platform in build_platforms
            reason = None
            if not buildable:
                supported = ", ".join(build_platforms)
                reason = (
                    f"build platform {build_platform} is not in "
                    f"build_platforms ({supported})"
                )

            for output in meta.get("provides", {}):
                if output in index:
                    raise ValueError(
                        f"Duplicate provider for {output}: "
                        f"{index[output]['provider']} and {path}"
                    )
                record = {
                    **instance,
                    "buildable": buildable,
                    "reason": reason,
                }
                index[output] = record

    changed = True
    while changed:
        changed = False
        for output, record in index.items():
            if not record["buildable"]:
                continue
            meta = output_meta(record, output)
            for requirement in meta.get("requires", {}):
                dependency = index.get(requirement)
                if dependency is None:
                    if build_dir is None or (build_dir / requirement).exists():
                        continue
                    record["buildable"] = False
                    record["reason"] = f"requires output with no provider: {requirement}"
                    changed = True
                    break
                if dependency["buildable"]:
                    continue
                record["buildable"] = False
                record["reason"] = (
                    f"requires unavailable output {requirement}: "
                    f"{dependency['reason']}"
                )
                changed = True
                break

    return index


def build_graph(targets: list[str], catalogue: dict, context: dict, build_dir: Path) -> dict:
    """
    Build dependency graph for one or more targets.

    Returns dict with:
        - nodes: {provider_instance: resolved_record}
        - edges: [(from_path, to_path), ...]
        - targets: list of provider instances that provide the targets
        - order: topologically sorted provider instances
        - needed: {provider_instance: set of required outputs}

    File dependencies that exist in build_dir are allowed even without
    a catalogue provider (e.g., catalogue.json).
    """
    outputs = build_output_index(catalogue, context, build_dir)
    index = {
        output: record["id"]
        for output, record in outputs.items()
        if record["buildable"]
    }

    for target in targets:
        if target not in index:
            if target in outputs:
                raise KeyError(f"Not buildable: {target}: {outputs[target]['reason']}")
            raise KeyError(f"No provider for target: {target}")

    nodes = {}
    edges = []
    visited = set()
    needed = {}  # path -> set of outputs needed from that path

    def visit(output: str, chain: list):
        if output not in index:
            if output in outputs:
                raise KeyError(f"Not buildable: {output}: {outputs[output]['reason']}")
            # Allow file dependencies that exist in build_dir
            if (build_dir / output).exists():
                return
            raise KeyError(f"No provider for: {output} (required by {chain[-1] if chain else 'root'})")

        instance_id = index[output]
        record = outputs[output]

        # Track which output we actually need from this path
        if instance_id not in needed:
            needed[instance_id] = set()
        needed[instance_id].add(output)

        # Cycle detection must happen before visited check
        if instance_id in chain:
            cycle = chain[chain.index(instance_id):] + [instance_id]
            raise ValueError(f"Dependency cycle: {' -> '.join(cycle)}")

        if output in visited:
            return
        visited.add(output)

        meta = output_meta(record, output)

        # Store path metadata only once (first output wins)
        if instance_id not in nodes:
            nodes[instance_id] = record

        for req in meta.get("requires", {}):
            edges.append((instance_id, index.get(req, req)))
            visit(req, chain + [instance_id])

    for target in targets:
        visit(target, [])

    # Topological sort from edges using Kahn's algorithm.
    # edges are (dependent, dependency) so dependency must come first.
    from collections import defaultdict, deque

    in_degree = {p: 0 for p in nodes}
    adj = defaultdict(set)
    for src, dst in edges:
        if dst in nodes and dst != src and src not in adj[dst]:
            adj[dst].add(src)
            in_degree[src] += 1

    queue = deque(p for p in nodes if in_degree[p] == 0)
    order = []
    while queue:
        p = queue.popleft()
        order.append(p)
        for neighbor in adj[p]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)

    return {
        "nodes": nodes,
        "edges": edges,
        "targets": [index[t] for t in targets],
        "order": order,  # dependencies first, targets last
        "needed": needed,
    }
