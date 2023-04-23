# Container API service

This is an API endpoint built using openapi for managing Docker containers.

## Pre-requisites

1.	Python 3.7 or later
2.	Docker
3.	Pip3

## Usage

To use this API, you can send HTTP requests to the following endpoints:

1.	POST /start-container: Start a Docker container. Pass the id/name of the container to start as a string parameter.
2.	PUT /stop-container: Stop a running Docker container. Pass the id/name of the container to stop as a string parameter.

## Running the API
To run the API, follow these steps:

1.	Clone this repository to your local machine. `git clone https://github.com/prasannaram19591/source-code.git` and move to the api directory `cd api`.
2.	Install openapi and uvicorn server pip packages. `pip3 install fastapi uvicorn`.
3.	In order to constantly reflect the code changes write a service file in your linux under `/etc/systemd/system/`.
4.	Name the service any name like `openapi.service` and write the following contents.
	```
	[Unit]
	Description=API Service
	After=network.target
	
	[Service]
	User=root
	WorkingDirectory=/root/source-code/api
	ExecStart=/usr/bin/python3 -m uvicorn portainer:app --reload --host 0.0.0.0 --port 4000
	Restart=always
	
	[Install]
	WantedBy=multi-user.target
 ```
5.	Note that the name of the python file should be passed in the uvicorn command in ExecStart line of service file.
6.	Start and enable the service `systemctl enable --now openapi.service`.
7.	Check if the service is running `systemctl status openapi.service`.
8.	Once the service is running open your browser and paste the url `http:<server_ip>:4000/docs` to view the builtin swagger UI for testing purposes.
9.	Expand any one api end point and click on `Try it out`.
10.	Input a container id in the text box and click on execute.

## Curl to reach endpoints directly from machine

The swagger UI also returns a curl command to interact with the api from command line itself.

1.	To start a container `curl -X 'POST' 'http://<server_ip>:4000/start-container?NAME=<container_id>' -H 'accept: application/json'`.
2.	To stop a container `curl -X 'PUT' 'http://<server_ip>:4000/stop-container?NAME=<container_id>' -H 'accept: application/json'`.
