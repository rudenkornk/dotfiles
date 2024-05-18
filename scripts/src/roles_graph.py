import graphviz as _graphviz  # type: ignore

from . import utils as _utils


def generate_png(view: bool = False) -> None:
    graph = _graphviz.Digraph(name="roles")

    roles_path = _utils.REPO_PATH / "roles"
    for role_path in roles_path.iterdir():
        if not role_path.is_dir():
            continue
        role = role_path.stem
        graph.node(role)

        meta_path = role_path / "meta"
        if (meta_path / "main.yml").exists():
            dependencies_path = meta_path / "main.yml"
        elif (meta_path / "main.yaml").exists():
            dependencies_path = meta_path / "main.yaml"
        else:
            continue

        yaml = _utils.yaml_read(dependencies_path)
        for dep in yaml["dependencies"]:
            graph.edge(role, dep["role"])

    output_path = _utils.ARTIFACTS_PATH / "roles_graph"
    graph.format = "png"
    graph.render(output_path, view=view, quiet_view=view)
