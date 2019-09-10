# Experimental testbed for fine-grained memory allocation and precise time measurements in cloud functions

With this research codebase, we check how:
- cloud functions can be metered with millisecond precision, to avoid 100ms idleness penalties
- memory can be assigned dynamically to the container isolation to account for alteration while avoiding unused memory penalties

Both Docker and alternative containerisation technologies will be explored for this purpose.

## Docker measurements

Measurements of time and memory costs for docker containers, based on AWS Lambda pricing.

### Usage

To get the AWS cost of an image just once, run
```
./measure-image.sh <image-name>
```
The image should be non interactive. Check that the image actually exists (either locally or in [Docker Hub](https://hub.docker.com))

Further parameters can be added using quotes `""`
```
./measure-image.sh "[docker command parameters] <image-name> [image parameters]"
```
For an example, see Image resizer below.

After execution, the output will show 
* Max memory usage, in bytes
* Container runtime, in milliseconds
* Total cost to run 1 million requests with AWS Lambda
* Net and overhead cost
* How much the price increases due to allocated but unused time and memory
* Wasted time, in milliseconds
* Wasted memory, in MB

During execution, the container is asigned the name `autostats-N`, with N being the PID. A .csv file named `autostats-N-rawresults.csv` gets created, containing all the pairs (timestamp, memory usage) observed, which can later be used for plotting.

The created container (not the image) will be removed after execution. 

### Examples

#### Hello world
Very short-lived example
```
./measure-image.sh hello-world
```

#### Sleep
A simple image with a 30 second sleep function
```
./measure-image.sh yyekhlef/sleep
```

#### Image resizer
Short example with memory variations
```
./measure-image.sh "-v $PWD:/d/ futils/resize <image-name.jpg> 50%"
```
A copy of the image to resize must be in the current directory. Sample images can be found in `/ref-data`\
Percentage can also be changed (works like a minimum)

#### Linux benchmarks
Executes a bunch of benchmark tests (it takes a couple of minutes and requires a lot of diskspace)
```
./measure-image.sh unimarijo/linux-benchmarks
```
