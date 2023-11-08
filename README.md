FastAPI Emotion Classification
---

This example wraps an Emotion Classification model from Huggingface Hub in a FastAPI app

## Run Locally

1. Install requirements

```shell
python -m pip install -r requirements.txt
```

2. Run with uvicorn

```shell
uvicorn app:app --host 0.0.0.0 --port 8000
```

## Deploy with Truefoundry

1. Install `servicefoundry`

```shell
python -m pip install -U servicefoundry
```

2. Login

```shell
sfy login --host <Truefoundry Platform URL>
```

1. Add a deploy.py

- Edit your `host` and optionally `path` for endpoint ([Docs](https://docs.truefoundry.com/docs/routing ))
- Edit your `workspace_fqn` ([Docs](https://docs.truefoundry.com/docs/workspace#copy-workspace-fqn-fully-qualified-name))

```python
import argparse

from servicefoundry import (
    Build,
    DockerFileBuild,
    Image,
    LocalSource,
    Port,
    PythonBuild,
    Service,
    Resources
)

service = Service(
    name="emotion-class-svc",

    # --- Build configuration i.e. How to package and build source code ---

    # This will instruct Truefoundry to automatically generate the Dockerfile and build it
    image=Build(
        build_source=LocalSource(local_build=False),
        build_spec=PythonBuild(
            python_version="3.10",
            requirements_path="requirements.txt",
            command="uvicorn app:app --host 0.0.0.0 --port 8000"
        )
        # Alternatively, you can also use DockerFileBuild to use the written Dockerfile like follows:
        # build_spec=DockerFileBuild()
    ),
    # Alternatively, you can use an already built public image of this codebase like follows:
    # image=Image(image_uri="truefoundrycloud/emotion-classification-fastapi:0.0.1")

    # --- Endpoints configuration i.e. How requests will reach the container ---

    ports=[
        Port(
            port=8000,
            # A model endpoint looks like https://{host}/{path}
            # Please see https://docs.truefoundry.com/docs/routing
            host="<Enter a host for the model endpoint>",
            path=None # <Enter optional path for model endpoint>,
        )
    ],

    # --- Environment Variables ---
    env={},

    # --- Resources ---
    resources=Resources(
        cpu_request=0.5, cpu_limit=0.5,
        memory_request=500, memory_limit=1000,
        ephemeral_storage_request=100, ephemeral_storage_limit=500
    )
)

# Get your workspace fqn from https://docs.truefoundry.com/docs/workspace#copy-workspace-fqn-fully-qualified-name
service.deploy(workspace_fqn="<Enter Workspace FQN>")
```

4. Deploy!

```shell
python deploy.py
```
