#!/usr/bin/env python3

import graphviz as _graphviz

from . import utils as _utils


def generate_png(view: bool = False):
    g = _graphviz.Digraph(name="roles")

    roles_path = _utils.get_repo_path() / "roles"
    for role_path in roles_path.iterdir():
        if not role_path.is_dir():
            continue
        role = role_path.stem
        g.node(role)

        meta_path = role_path / "meta"
        if (meta_path / "main.yml").exists():
            dependencies_path = meta_path / "main.yml"
        elif (meta_path / "main.yaml").exists():
            dependencies_path = meta_path / "main.yaml"
        else:
            continue

        yaml = _utils.yaml_read(dependencies_path)
        for dep in yaml["dependencies"]:
            g.edge(role, dep["role"])

    output_path = _utils.get_build_path() / "roles_graph"
    g.format = "png"
    g.render(output_path, view=view, quiet_view=view)
