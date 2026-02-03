import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
import re
import sys
from typing import Optional, Dict, List
from urllib import request, error


SUPPORTED_PLUGIN_LOADERS = {
    "paper",
    "purpur",
    "folia",
    "spigot",
    "velocity",
}


class ModrinthClient:
    def __init__(self):
        self.base_url = "https://api.modrinth.com"

    def get(self, url: str) -> Optional[dict]:
        try:
            with request.urlopen(self.base_url + url) as response:
                return json.loads(response.read())
        except Exception as e:
            print(f"API error: {e}")
            return None

    def download_file(self, url: str, filename: str) -> bool:
        try:
            request.urlretrieve(url, filename)
            return os.path.exists(filename) and os.path.getsize(filename) > 0
        except Exception as e:
            print(f"Download failed: {e}")
            return False

    def get_project(self, project_id: str) -> Optional[dict]:
        return self.get(f"/v2/project/{project_id}")

    def get_versions(self, project_id: str) -> Optional[List[dict]]:
        return self.get(f"/v2/project/{project_id}/version")

    def get_collection(self, collection_id: str) -> Optional[dict]:
        return self.get(f"/v3/collection/{collection_id}")


def extract_collection_id(value: str) -> str:
    match = re.search(r"modrinth\.com/collection/([^/?]+)", value)
    return match.group(1) if match else value.strip()


def parse_args():
    parser = argparse.ArgumentParser(
        description="Download plugins from a Modrinth collection"
    )

    parser.add_argument("-c", "--collection", required=True)
    parser.add_argument("-v", "--version", required=True)
    parser.add_argument(
        "-l",
        "--loader",
        required=True,
        help="paper | purpur | folia | spigot | velocity",
    )
    parser.add_argument(
        "-d",
        "--directory",
        default="./plugins",
        help="Plugin directory (default: ./plugins)",
    )
    parser.add_argument(
        "-u",
        "--update",
        action="store_true",
        help="Update existing plugins",
    )

    args = parser.parse_args()

    args.collection = extract_collection_id(args.collection)
    args.loader = args.loader.lower()

    if args.loader not in SUPPORTED_PLUGIN_LOADERS:
        print(f"ERROR: Unsupported loader '{args.loader}'")
        sys.exit(1)

    return args


def validate_directory(path: str):
    if os.path.exists(path) and not os.path.isdir(path):
        print(f"ERROR: {path} exists but is not a directory")
        sys.exit(1)
    os.makedirs(path, exist_ok=True)


def get_existing_plugins(directory: str) -> Dict[str, str]:
    plugins = {}
    for file in os.listdir(directory):
        if not file.lower().endswith(".jar"):
            continue
        parts = file.rsplit(".", 2)
        if len(parts) >= 2:
            plugins[parts[-2]] = file
    return plugins


def version_matches(mc_version: str, declared_versions: List[str]) -> bool:
    if mc_version in declared_versions:
        return True
    for v in declared_versions:
        if v.endswith(".x") and mc_version.startswith(v[:-2]):
            return True
    return False


def get_latest_plugin_version(
    client: ModrinthClient, project_id: str, mc_version: str, loader: str
) -> Optional[dict]:

    versions = client.get_versions(project_id)
    if not versions:
        return None

    for v in versions:
        if loader not in v.get("loaders", []):
            continue
        if version_matches(mc_version, v.get("game_versions", [])):
            return v

    return None


def select_file(version_data: dict) -> Optional[dict]:
    files = version_data.get("files", [])
    if not files:
        return None
    for f in files:
        if f.get("primary"):
            return f
    return files[0]


def download_plugin(
    project_id: str,
    client: ModrinthClient,
    directory: str,
    mc_version: str,
    loader: str,
    update: bool,
    existing: Dict[str, str],
):

    version = get_latest_plugin_version(client, project_id, mc_version, loader)
    if not version:
        print(f"ERROR: No compatible version for {project_id}")
        return

    file = select_file(version)
    if not file:
        print(f"ERROR: No downloadable file for {project_id}")
        return

    filename = file["filename"]
    parts = filename.split(".")
    parts.insert(-1, project_id)
    final_name = ".".join(parts)
    path = os.path.join(directory, final_name)

    if project_id in existing and not update:
        print(f"SKIP: {project_id} already exists")
        return

    print(f"DOWNLOADING: {project_id} -> {final_name}")

    if not client.download_file(file["url"], path):
        print(f"FAILED: {project_id}")
        return

    old = existing.get(project_id)
    if old:
        try:
            os.remove(os.path.join(directory, old))
        except Exception:
            pass


def main():
    args = parse_args()
    validate_directory(args.directory)

    client = ModrinthClient()
    collection = client.get_collection(args.collection)

    if not collection:
        print("ERROR: Collection not found")
        return

    projects = collection.get("projects", [])
    if not projects:
        print("Collection is empty")
        return

    existing = get_existing_plugins(args.directory)

    with ThreadPoolExecutor(max_workers=5) as executor:
        for pid in projects:
            executor.submit(
                download_plugin,
                pid,
                client,
                args.directory,
                args.version,
                args.loader,
                args.update,
                existing,
            )


if __name__ == "__main__":
    main()
