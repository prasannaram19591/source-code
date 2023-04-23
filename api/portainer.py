from fastapi import FastAPI
import subprocess

app = FastAPI(title="Container API service", description="This is an api endpoint for home lab.")

@app.post("/start-container")
def start_container(NAME: str):
    try:
        docker_cmd = ["docker", "start", NAME]
        subprocess.run(docker_cmd, check=True)
        return {"status": "success", "message": f"Started the container {NAME}"}
    except subprocess.CalledProcessError as e:
        return {"status": "error", "message": f"Failed to start container {NAME}: {e.output.decode()}"}

@app.put("/stop-container")
def start_container(NAME: str):
    try:
        docker_cmd = ["docker", "stop", NAME]
        subprocess.run(docker_cmd, check=True)
        return {"status": "success", "message": f"Stopped the container {NAME}"}
    except subprocess.CalledProcessError as e:
        return {"status": "error", "message": f"Failed to stop container {NAME}: {e.output.decode()}"}

