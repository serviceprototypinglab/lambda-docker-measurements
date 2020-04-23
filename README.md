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
* Memory used in MB and memory allocated by AWS
* Total cost to run 1 million requests with AWS Lambda
* Net and overhead cost
* How much the price increases due to allocated but unused time and memory
* Wasted time, in milliseconds
* Wasted memory, in MB

During execution, the container is asigned the name `autostatsN`, with N being the PID. A .csv file named `autostatsN-rawresults.csv` gets created, containing all the pairs (timestamp, memory usage) observed, which can later be used for plotting.

The created container (not the image) will be removed after execution, and it's name will be displayed.


To run the test on the same image multiple times, run
```
./measure-image-multiple.sh <image-name> <number of tests>
```
or
```
./measure-image-multiple.sh "[docker command parameters] <image-name> [image parameters]" <number of tests>
```
A file called `autostats-N.dat` will be created containing the results of each test in these columns:
* Time(ms)
* Memory(MB)
* AWS Time(ms)
* AWS Memory(ms)
* AWS Cost($)
* Net cost($)
* Overhead cost($)

### Some examples

#### Hello world
Very short-lived example ([link](https://hub.docker.com/_/hello-world))
```
./measure-image.sh hello-world
```

#### Sleep
A simple image with a 30 second sleep function ([link](https://hub.docker.com/r/yyekhlef/sleep))
```
./measure-image.sh yyekhlef/sleep
```

#### Image resizer
Short example with memory variations ([link](https://hub.docker.com/r/futils/resize))
```
./measure-image.sh "-v $PWD:/d/ futils/resize <image-name.jpg> 50%"
```
A copy of the image to resize must be in the current directory.
Percentage can also be changed (works like a minimum).

Some sample images (1, 2 or 5mb) can be downloaded with the `download-sample-image.sh` script in `/ref-data`.

#### Linux benchmarks
Executes a bunch of benchmark tests (it takes a couple of minutes and requires a lot of diskspace) ([link](https://hub.docker.com/r/unimarijo/linux-benchmarks))
```
./measure-image.sh unimarijo/linux-benchmarks
```
