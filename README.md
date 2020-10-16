# Experimental testbed for fine-grained memory allocation and precise time measurements in cloud functions

With this research codebase, we check how:
- cloud functions can be metered with millisecond precision, to avoid 100ms idleness penalties
- memory can be assigned dynamically to the container isolation to account for alteration while avoiding unused memory penalties

Both Docker and alternative containerisation technologies will be explored for this purpose.

## Docker measurements

Measurements of time and memory costs for Docker containers through tracing, based on FaaS provider pricing models (primarily implemented for AWS Lambda).

### Usage

To get the memory consumption trace profile and the FaaS hosting cost of an image that is assumed to contain a cloud function just once, run
```
./functracer <image-name>
```
The image should be non interactive. Check that the image actually exists (either locally or in [Docker Hub](https://hub.docker.com))

Further parameters can be added using quotes `""`
```
./functracer "[docker command parameters] <image-name> [image parameters]"
```
For an example, see Image resizer below.

After execution, the output will show 
* Max memory usage, in bytes
* Container runtime, in milliseconds
* Memory used in MB and memory allocated by the FaaS provider
* Total cost to run 1 million requests with the provider
* Net and overhead cost
* How much the price increases due to allocated but unused time and memory
* Wasted time, in milliseconds
* Wasted memory, in MB

During execution, the container is asigned the name `autostatsN`, with N being the PID. A .csv file named `autostatsN-rawresults.csv` gets created, containing all the pairs (timestamp, memory usage) observed, which can later be used for plotting.

The created container (not the image) will be removed after execution, and it's name will be displayed.


To run the test on the same image multiple times, run
```
./functracer-multi <image-name> <number of tests>
```
or
```
./functracer-multi "[docker command parameters] <image-name> [image parameters]" <number of tests>
```
A file called `autostats-N.dat` will be created containing the results of each test in these columns:
* Time(ms)
* Memory(MB)
* AWS Time(ms)
* AWS Memory(ms)
* AWS Cost($)
* Net cost($)
* Overhead cost($)


Finally, to get several trace profiles at the same time and calculate the maximum hull as well as the
upscaling hull with safety buffer, all using one out of a selection of fixed sample container images with sample data, run
```
./functracer-hull
```

### Some examples
If unsure which to take, take the Sleep example.

#### Hello world
Very short-lived example ([link](https://hub.docker.com/_/hello-world))
```
./functracer hello-world
```
Note, this executes so quickly that the measurement may fail due to lack of precision timing.

#### Sleep
A simple image with a 30 second sleep function ([link](https://hub.docker.com/r/yyekhlef/sleep))
```
./functracer yyekhlef/sleep
```
With that one, you can emulate a higher (but not lower) FaaS memory allocation than 128 MB
```
./functracer "--memory=256MB yyekhlef/sleep"
```
To get the .dat file for accurate memory tracking, use
```
./functracer "--memory=256MB yyekhlef/sleep" 2
```

#### Image resizer
Short example with memory variations ([link](https://hub.docker.com/r/futils/resize))
```
./functracer "-v $PWD:/d/ futils/resize <image-name.jpg> 50%"
```
A copy of the image to resize must be in the current directory.
Percentage can also be changed (works like a minimum).

Some sample images (1, 2 or 5mb) can be downloaded with the `download-sample-image.sh` script in `/ref-data`.
To automate multiple executions with multiple image sizes, use
```
./functracer-hull
```
To further try memory autotuning, train and test as follows
```
./functracer-hull False
cp ref-data/Dresden_Garnisonkirche_gp.jpg ref-data/sample.jpg
./functracer "-v $PWD:/d/ futils/resize ref-data/sample.jpg 50%" uhull.json
```

#### Linux benchmarks
Executes a bunch of benchmark tests (it takes a couple of minutes and requires a lot of diskspace - 64+GB!) ([link](https://hub.docker.com/r/unimarijo/linux-benchmarks))
```
./functracer unimarijo/linux-benchmarks
```

#### Image background remover
Short example with mostly flat memory usage ([link](https://hub.docker.com/r/futils/alpha))
```
./functracer "-v $PWD:/d/ futils/alpha <image-name.png> White 10"
```
A copy of the image to work with must be in the current directory.
Color and fuzziness can be changed

#### Image to monochrome
Short example with slight memory variation ([link](https://hub.docker.com/r/futils/monochrome))
```
./functracer "-v $PWD:/d/ futils/monochrome <image-name.png> Gray"
```
A copy of the image to convert must be in the current directory

### Video transcoding
Memory and time variations depend on size and type of video ([link](https://hub.docker.com/r/ntodd/video-transcoding))
```
./functracer "-v $PWD:/data ntodd/video-transcoding transcode-video --mp4 <video.mkv>"
```
A copy of the video to transcode must be in the current directory

### File compresser - decompresser
Memory and time variations depend on size of directory ([link](https://hub.docker.com/r/wucke13/compress))
```
./functracer "-v $PWD:/d/ -w /d/ wucke13/compress gzip --best -r <directory>"
```

Another compresser example ([link](https://hub.docker.com/r/lion86/compression-toolkit))

## Publications

* ESSCA 2020: Memory Autotuning for Cloud Functions (demo)
* WoSC6 2020: Resource Management for Cloud Functions with Memory Tracing, Profiling and Autotuning
