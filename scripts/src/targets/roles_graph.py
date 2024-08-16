import graphviz  # type: ignore

from .. import utils
from .bootstrap import bootstrap


def roles_graph() -> dict[str, set[str]]:
    roles_path = utils.REPO_PATH / "roles"
    graph: dict[str, set[str]] = {}
    for role_path in roles_path.iterdir():
        if not role_path.is_dir():
            continue
        role = role_path.stem
        graph[role] = set()

        meta_path = role_path / "meta"
        if (meta_path / "main.yml").exists():
            dependencies_path = meta_path / "main.yml"
        elif (meta_path / "main.yaml").exists():
            dependencies_path = meta_path / "main.yaml"
        else:
            continue

        yaml, _ = utils.yaml_read(dependencies_path)
        assert isinstance(yaml, dict)
        for dep in yaml["dependencies"]:
            graph[role].add(dep["role"])

    return graph


def generate_png(view: bool = False) -> None:
    bootstrap()

    graph = graphviz.Digraph(name="roles")

    str_graph = roles_graph()

    for node, dependencies in str_graph.items():
        graph.node(node)
        for dep in dependencies:
            graph.edge(node, dep)

    output_path = utils.ARTIFACTS_PATH / "roles_graph"
    graph.format = "png"
    graph.render(output_path, view=view, quiet_view=view)
