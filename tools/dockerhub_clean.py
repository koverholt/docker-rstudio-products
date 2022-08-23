#!/usr/bin/env python3
import os
import sys
from datetime import datetime, timedelta, timezone
from pprint import pprint

import requests

ENDPOINTS = {
    "create_token": "https://hub.docker.com/v2/users/login",
    "get_images": "https://hub.docker.com/v2/namespaces/rstudio/repositories/{repository}/images",
    "delete_images": "https://hub.docker.com/v2/namespaces/rstudio/delete-images"
}
REPOSITORIES = [
    "r-session-complete",
    "r-session-complete-preview",
    "rstudio-connect",
    "rstudio-connect-content-init",
    "rstudio-connect-content-init-preview",
    "rstudio-connect-preview",
    "rstudio-package-manager",
    "rstudio-package-manager-preview",
    "rstudio-workbench",
    "rstudio-workbench-for-microsoft-azure-ml",
    "rstudio-workbench-preview",
]


def create_token(docker_hub_username, docker_hub_password):
    data = {"username": docker_hub_username, "password": docker_hub_password}
    r = requests.post(ENDPOINTS["create_token"], data=data)
    if r.status_code != 200:
        print(f"{r.status_code} Failed to get bearer token", file=sys.stderr)
        exit(1)
    return r.json()["token"]


def get_images(bearer_token, repository, active_from):
    page = 1
    objects_remaining = True
    image_list = []
    while objects_remaining:
        headers = {
            "Authorization": f"Bearer {bearer_token}"
        }
        params = {
            "status": "inactive",
            "ordering": "last_activity",
            "active_from": active_from,
            "page": page,
            "page_size": 100,
        }
        r = requests.get(ENDPOINTS["get_images"].format(repository=repository), headers=headers, params=params)
        if r.status_code != 200:
            print(f"{r.status_code} Failed to get image list for {repository}", file=sys.stderr)
            break
        data = r.json()
        image_list.extend(data["results"])
        if not data["next"]:
            objects_remaining = False
        page += 1
    return image_list


def delete_images(bearer_token, repository, image_list, active_from, dry_run=True):
    headers = {
        "Authorization": f"Bearer {bearer_token}"
    }
    data = {
        "dry_run": dry_run,
        "active_from": active_from,
        "manifests": [],
    }
    print_image_list = []
    total_images = 0
    batch_count = 0
    for image in image_list:
        if image["status"] == "active":
            print(f"Skipping active image {image['repository']}@{image['digest']}", file=sys.stderr)
            continue
        current_tags = []
        for tag in image["tags"]:
            if tag["tag"] == "latest" and tag["is_current"]:
                print(f"Skipping image tagged as latest {image['repository']}@{image['digest']}", file=sys.stderr)
                continue
            if tag["is_current"]:
                current_tags.append(tag["tag"])
        if current_tags:
            if "ignore_warnings" not in data:
                data["ignore_warnings"] = []
            data["ignore_warnings"].append({
                "repository": image["repository"],
                "digest": image["digest"],
                "warning": "current_tag",
                "tags": current_tags
            })
        data["manifests"].append({
            "repository": image["repository"],
            "digest": image["digest"],
        })
        print_image_list.append({
            "repository": f"{image['namespace']}/{image['repository']}",
            "digest": image["digest"],
            "tags": [t["tag"] for t in image["tags"] if t["is_current"]],
            "last_pulled": image["last_pulled"],
        })
        total_images += 1
        batch_count += 1
        if batch_count == 25:  # Docker Hub caps delete requests to 25 manifests
            batch_count = 0
            print("Deleting the following images:", file=sys.stderr)
            pprint(print_image_list, stream=sys.stderr)
            r = requests.post(ENDPOINTS["delete_images"], headers=headers, json=data)
            if r.status_code != 200:
                print(f"{r.status_code} Failed to delete batch of images for {repository}", file=sys.stderr)
            data["manifests"] = []
            print_image_list = []

    if data["manifests"]:  # Runs if there are any remaining images queued for deletion after the last 25 image batch
        print("Deleting the following images:", file=sys.stderr)
        pprint(print_image_list, stream=sys.stderr)
        r = requests.post(ENDPOINTS["delete_images"], headers=headers, json=data)
        if r.status_code == 200:
            print(f"Successfully deleted {total_images} total images from {repository}", file=sys.stderr)
        else:
            print(f"{r.status_code} Failed to delete images for {repository}", file=sys.stderr)


def main():
    dry_run = bool(int(os.getenv("DRY_RUN", 1)))
    if dry_run:
        print("The DRY_RUN flag is enabled. No images will be deleted.", file=sys.stderr)
    docker_hub_username = os.getenv("DOCKER_HUB_USERNAME")
    docker_hub_password = os.getenv("DOCKER_HUB_PASSWORD")  # Can be password or generated PAT
    bearer_token = create_token(docker_hub_username, docker_hub_password)
    days_since_last_active = os.getenv("DAYS_SINCE_LAST_ACTIVE", 548)
    active_from = (datetime.now(timezone.utc) - timedelta(days=days_since_last_active)).isoformat()
    for repository in REPOSITORIES:
        image_list = get_images(bearer_token, repository, active_from)
        if image_list:
            delete_images(bearer_token, repository, image_list, active_from, dry_run=dry_run)
        else:
            print(f"Skipping {repository}, no images matched the deletion criteria.", file=sys.stderr)


if __name__ == "__main__":
    main()
