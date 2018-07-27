# Qgis3 WPS service

Setup a processing based WPS service.

## Running the service

The following document assumes that your are somehow familiar with the basics of [Docker](https://docs.docker.com/).

Unless you already have a Redis service running you have to create one:
```
# Create a bridge network
docker network create mynet
# Run redis on background on that network
docker run -d --rm --name redis --net mynet redis:4 
```

And launch the service interactively  on the port 8080 on the same network

```
docker run -it --rm -p 127.0.0.1:8080:8080 --net mynet \
       -v /path/to/processing/:/processing \
       -v /path/to/qgis/projects:/projects \
       -v /path/to/processing/output/dir:/srv/data \
       -e QYWPS_SERVER_WORKDIR=/srv/data \
       -e QYWPS_SERVER_PARALLELPROCESSES=2 \
       -e QYWPS_SERVER_LOGSTORAGE=REDIS \
       -e QYWPS_PROCESSSING_PROVIDERS=provider1,provider2  \
       -e QYWPS_PROCESSSING_PROVIDERS_MODULE_PATH=/processing \
       -e QYWPS_CACHE_ROOTDIR=/projects \
       -e QYWPS_USER={uid}:{gid} \
       3liz/qgis-wps
```

Replace {uid}:{gid} by the approriate uid and gid of your mounted volume directories. Alternatively you may use the
`-u <uid>` Docker options to set the appropriates rights.

*Note*: This will run the service interactively on your terminal, on a production environment you will have 
to adapt the deployment according to your infrastructure.


## Setting master projects

Master Qgis projects must be located at the location given by  `QYWPS_CACHE_ROOTDIR` - see configuration variables.

Processing algorithms are located at the lacation given by `QYWPS_PROCESSSING_PROVIDERS_MODULE_PATH`. 
See the Qywps documentation on how to configure properly you provider directory: https://projects.3liz.org/infra-v3/py-qgis-wps/tree/master#configuring-providers

## Configuration 

Configuration is done with environment variables 

### Global server configuration (from the qywps documentation):

- QYWPS\_SERVER\_WORKDIR: set the current dir processes, all processes will be running in that directory.
- QYWPS\_SERVER\_HOST\_PROXY: When the service is behind a reverse proxy, set this to the proxy entrypoint.
- QYWPS\_SERVER\_PARALLELPROCESSES: Number of parrallel process workers 
- QYWPS\_SERVER\_RESPONSE\_TIMEOUT: The max response time before killing a process.
- QYWPS\_SERVER\_RESPONSE\_EXPIRATION: The maxe time (in seconds) the response from a WPS process will be available.
- QYWPS\_SERVER\_WMS\_SERVICE\_URL: The base url for WMS service. Default to <hosturl>/wms. Responses from processing will
be retourned as WMS urls. This configuration variable set the base url for accessing results.
- QYWPS\_SERVER\_RESULTS\_MAP\_URI

#### Logging

- QYWPS\_LOGLEVEL: the log level, should be `INFO` in production mode, `DEBUG` for debug output. 

#### REDIS logstorage configuration

- QYWPS\_REDIS\_HOST: The redis host
- QYWPS\_REDIS\_PORT: The redis port. Default to 6379
- QYWPS\_REDIS\_DBNUM: The redis database number used. Default to 0


#### Qgis project Cache configuration

- QYWPS\_CACHE\_ROOTDIR: Absolute path to the qgis projects root directory, projects referenges with the MAP parameter will be searched at this location

#### Processing configuration

- QYWPS\_PROCESSSING\_PROVIDERS: List of providers for publishing algorithms (comma separated)
- QYWPS\_PROCESSSING\_PROVIDERS\_MODULE\_PATH: Path to look for processing algoritms provider to publish, algorithms from providers specified heres will be runnable as WPS processes.


## Using with Lizmap

For using with Lizmap,  you need to adjust the lizmap configuration with the following:

### Configuring the wps support in Lizmap

You must add the WPS support by adding the following in your *localconfig.ini* file:

```
[modules]
wps.access=2

[wps]
wps_url=http://locahost:8080/ows/
# Base URL to your WMS service (WPS/Processing results are returned as WMS urls.
ows_url=<url to WMS>
# Set the base for the qgis master projects, lizmap will use relative MAP path from this value
wps_rootDirectories="/srv/projects"
redis_host=redis 
redis_port=6379
redis_db=1
redis_key_prefix=wpslizmap

```

You must  set the master project directory `QYWPS_CACHE_ROOTDIR` to the same location as the qgis lizmap
projects directory (Lizmap projects directory). Which corresponds to `/srv/projects` in our project.



